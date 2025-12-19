package sync

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/pkg/logger"
)

// Service 同步服务接口
type Service interface {
	// StreamAssets 流式同步资产
	StreamAssets(ctx context.Context, writer io.Writer, req *StreamAssetsRequest) error
}

// StreamAssetsRequest 流式同步资产请求
type StreamAssetsRequest struct {
	UserID       uint
	Types        []string
	Reset        bool
	UpdatedAfter *time.Time
	DeviceID     string // 设备ID（用于多设备支持）
}

// service 同步服务实现
type service struct {
	log            logger.Logger
	syncRepo       repository.SyncRepository
	checkpointRepo repository.CheckpointRepository
}

// NewService 创建同步服务
func NewService(
	syncRepo repository.SyncRepository,
	checkpointRepo repository.CheckpointRepository,
) Service {
	return &service{
		log:            logger.New("service.sync"),
		syncRepo:       syncRepo,
		checkpointRepo: checkpointRepo,
	}
}

// StreamAssets 流式同步资产
func (s *service) StreamAssets(ctx context.Context, writer io.Writer, req *StreamAssetsRequest) error {
	var checkpoint *models.SyncCheckpoint
	var err error

	// 1. 检查是否需要重置
	if req.Reset {
		// 重置时，清除 checkpoint 并直接进行全量同步
		if err := s.checkpointRepo.ResetSyncProgress(ctx, req.UserID, req.DeviceID); err != nil {
			s.log.Error("failed to reset sync progress",
				logger.Error(err),
				logger.Uint("user_id", req.UserID),
			)
			// 继续执行，不中断
		}
		// 重置后，checkpoint 为 nil，表示全量同步
		checkpoint = nil
	} else {
		// 2. 非重置模式：获取 checkpoint
		checkpoint, err = s.checkpointRepo.GetCheckpoint(ctx, req.UserID, req.DeviceID, "assets_v1")
		if err != nil {
			return fmt.Errorf("get checkpoint: %w", err)
		}

		// 3. 检查是否需要全量同步（仅在非重置模式下检查）
		if s.needsFullSync(checkpoint) {
			// 需要全量同步，发送重置事件通知客户端
			s.sendResetEvent(writer)
			return nil
		}
	}

	// 4. 获取当前时间 ID（用于 checkpoint）
	nowID := s.checkpointRepo.GetNowID()

	// 5. 流式发送资产数据
	if err := s.streamAssets(ctx, writer, req, checkpoint, nowID); err != nil {
		return fmt.Errorf("stream assets: %w", err)
	}

	// 6. 发送同步完成事件
	s.sendCompleteEvent(writer, nowID)

	return nil
}

// needsFullSync 检查是否需要全量同步
func (s *service) needsFullSync(checkpoint *models.SyncCheckpoint) bool {
	if checkpoint == nil {
		return true // 没有 checkpoint，需要全量同步
	}

	// 检查 checkpoint 是否过期（超过 30 天）
	if checkpoint.UpdatedAt.Before(time.Now().AddDate(0, 0, -30)) {
		return true
	}

	return false
}

// sendResetEvent 发送同步重置事件
func (s *service) sendResetEvent(writer io.Writer) {
	event := map[string]interface{}{
		"type": "sync_reset_v1",
		"ids":  []string{"reset"},
		"data": map[string]interface{}{},
	}
	s.writeJSONLine(writer, event)
}

// sendCompleteEvent 发送同步完成事件
func (s *service) sendCompleteEvent(writer io.Writer, nowID string) {
	event := map[string]interface{}{
		"type": "sync_complete_v1",
		"ids":  []string{nowID},
		"data": map[string]interface{}{},
	}
	s.writeJSONLine(writer, event)
}

// streamAssets 流式发送资产数据
func (s *service) streamAssets(ctx context.Context, writer io.Writer, req *StreamAssetsRequest, checkpoint *models.SyncCheckpoint, nowID string) error {
	batchSize := 100
	var lastID string
	var since *time.Time

	// 如果有 checkpoint，使用 checkpoint 的 ack 作为 lastID
	if checkpoint != nil && checkpoint.Ack != "" {
		lastID = checkpoint.Ack
	}

	// 如果指定了 updatedAfter，使用它作为增量同步的时间点
	if req.UpdatedAfter != nil {
		since = req.UpdatedAfter
		lastID = "" // 增量同步不使用游标
	}

	for {
		var medias []*models.Media
		var err error

		if since != nil {
			// 增量同步：基于时间戳
			medias, err = s.syncRepo.GetAssetsSince(ctx, req.UserID, since, batchSize)
			if err != nil {
				return fmt.Errorf("get assets since: %w", err)
			}
		} else {
			// 全量同步：基于游标
			var nextLastID string
			medias, nextLastID, err = s.syncRepo.GetAssetsWithCursor(ctx, req.UserID, batchSize, lastID)
			if err != nil {
				return fmt.Errorf("get assets with cursor: %w", err)
			}
			lastID = nextLastID
		}

		// 如果没有更多数据，退出循环
		if len(medias) == 0 {
			break
		}

		// 批量发送资产数据
		if err := s.sendAssetBatch(writer, medias, nowID); err != nil {
			return fmt.Errorf("send asset batch: %w", err)
		}

		// 如果是增量同步，检查是否还有更多数据
		if since != nil {
			if len(medias) < batchSize {
				break // 没有更多数据
			}
			// 更新 since 为最后一条记录的更新时间
			if len(medias) > 0 {
				lastMedia := medias[len(medias)-1]
				since = &lastMedia.UpdatedAt
			}
		} else {
			// 游标分页：如果 lastID 为空，说明没有更多数据
			if lastID == "" {
				break
			}
		}
	}

	return nil
}

// sendAssetBatch 批量发送资产数据
func (s *service) sendAssetBatch(writer io.Writer, medias []*models.Media, ack string) error {
	// 将资产转换为响应格式
	assetData := make([]map[string]interface{}, 0, len(medias))
	ids := make([]string, 0, len(medias))

	for _, media := range medias {
		ids = append(ids, media.UUID)

		asset := map[string]interface{}{
			"uuid":              media.UUID,
			"user_id":           media.UserID,
			"hash":              media.Hash,
			"item_type":         media.ItemType,
			"original_filename": media.OriginalFilename,
			"filename":          media.Filename,
			"file_size":         media.FileSize,
			"mime_type":         media.MimeType,
			"processing_status": media.ProcessingStatus,
			"local_path":        media.LocalPath,
			"backup_status":     media.BackupStatus,
			"created_at":        media.CreatedAt.Format(time.RFC3339),
			"updated_at":        media.UpdatedAt.Format(time.RFC3339),
		}

		// 添加可选字段
		if media.Width > 0 {
			asset["width"] = media.Width
		}
		if media.Height > 0 {
			asset["height"] = media.Height
		}
		if media.MediaTakenAt != nil {
			asset["media_taken_at"] = media.MediaTakenAt.Format(time.RFC3339)
		}
		if media.ThumbHash != "" {
			asset["thumb_hash"] = media.ThumbHash
		}

		assetData = append(assetData, asset)
	}

	// 发送事件（每批一个事件）
	event := map[string]interface{}{
		"type": "asset_v1",
		"ids":  ids,
		"data": assetData,
		"ack":  ack,
	}

	return s.writeJSONLine(writer, event)
}

// writeJSONLine 写入一行 JSON（JSON Lines 格式）
func (s *service) writeJSONLine(writer io.Writer, data interface{}) error {
	jsonBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("marshal json: %w", err)
	}

	jsonBytes = append(jsonBytes, '\n')
	if _, err := writer.Write(jsonBytes); err != nil {
		return fmt.Errorf("write json line: %w", err)
	}

	// 刷新缓冲区（如果支持）
	if flusher, ok := writer.(interface{ Flush() error }); ok {
		if err := flusher.Flush(); err != nil {
			return fmt.Errorf("flush writer: %w", err)
		}
	}

	return nil
}
