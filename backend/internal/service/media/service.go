package media

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	"gorm.io/gorm"
)

// UploadMediaRequest 上传媒体请求
type UploadMediaRequest struct {
	UserID           uint
	Hash             string
	ItemType         string
	OriginalFilename string
	CloudUUID        string
	MediaTakenAt     *time.Time
	Filename         string
	FileSize         int64
	Data             io.Reader
}

// Service 媒体服务接口
type Service interface {
	// CheckInstantUpload 检查是否可以秒传（使用客户端传入的Hash）
	CheckInstantUpload(ctx context.Context, userID uint, hash string) (*models.Media, error)
	// UploadMedia 上传媒体文件（流式处理，使用客户端传入的Hash）
	UploadMedia(ctx context.Context, req *UploadMediaRequest) (*models.Media, error)
}

// service 媒体服务实现
type service struct {
	log            logger.Logger
	repo           repository.MediaRepository
	storageManager *storage.StorageManager
	taskQueue      *gq.Client
}

// NewService 创建媒体服务
func NewService(
	repo repository.MediaRepository,
	storageManager *storage.StorageManager,
	taskQueue *gq.Client,
) Service {
	return &service{
		log:            logger.New("service.media"),
		repo:           repo,
		storageManager: storageManager,
		taskQueue:      taskQueue,
	}
}

// CheckInstantUpload 检查是否可以秒传（使用客户端传入的Hash）
func (s *service) CheckInstantUpload(ctx context.Context, userID uint, hash string) (*models.Media, error) {
	existingMedia, err := s.repo.FindByHash(ctx, userID, hash)
	if err == nil && existingMedia != nil {
		// 文件已存在，可以秒传
		return existingMedia, nil
	}
	// 如果查询出错且不是记录不存在，返回错误
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("check instant upload: %w", err)
	}
	// 文件不存在，不能秒传
	return nil, nil
}

// UploadMedia 上传媒体文件（流式处理，使用客户端传入的Hash）
// 注意：秒传检查已在Handler层完成，这里直接进行上传
func (s *service) UploadMedia(ctx context.Context, req *UploadMediaRequest) (*models.Media, error) {
	// 1. 验证Hash长度（确保可以安全地切片）
	if len(req.Hash) < 4 {
		return nil, fmt.Errorf("invalid hash length: must be at least 4 characters")
	}

	// 2. 构建存储key（使用客户端传入的Hash）
	// key格式：{hash[0:2]}/{hash[2:4]}/{uuid}.{ext}
	hashPrefix := req.Hash[:2]
	hashNext := req.Hash[2:4]

	// 根据文件扩展名确定文件类型
	ext := filepath.Ext(req.Filename)
	if ext == "" {
		// 根据item_type设置默认扩展名
		if req.ItemType == "video" {
			ext = ".mp4"
		} else {
			ext = ".jpg"
		}
	}

	storageKey := fmt.Sprintf("%s/%s/%s%s", hashPrefix, hashNext, req.CloudUUID, ext)

	// 3. 流式上传到本地存储（直接使用io.Reader，不读入内存）
	putOpts := &interfaces.PutOptions{
		UserID:   req.UserID,
		FileType: interfaces.FileTypeOriginal,
	}

	// 直接流式写入，不需要读入内存
	if err := s.storageManager.Put(ctx, storageKey, req.Data, req.FileSize, putOpts); err != nil {
		return nil, fmt.Errorf("upload to storage: %w", err)
	}

	// 4. 创建数据库记录
	media := &models.Media{
		UUID:             req.CloudUUID,
		UserID:           req.UserID,
		Hash:             req.Hash,
		ItemType:         strings.ToLower(req.ItemType),
		OriginalFilename: req.OriginalFilename,
		Filename:         req.Filename,
		FileSize:         req.FileSize,
		MimeType:         "", // TODO: 根据文件类型自动检测
		MediaTakenAt:     req.MediaTakenAt,
		ProcessingStatus: "PENDING",
		Deleted:          false,
		LocalPath:        storageKey,
		BackupStatus:     "pending",
	}

	if err := s.repo.Create(ctx, media); err != nil {
		// 如果数据库创建失败，尝试删除已上传的文件
		s.storageManager.Delete(ctx, storageKey)
		return nil, fmt.Errorf("create media record: %w", err)
	}

	// 5. 入队处理任务（生成缩略图和预览图）
	taskPayload := map[string]interface{}{
		"media_uuid": req.CloudUUID,
		"file_path":  storageKey,
		"user_id":    req.UserID,
	}

	payloadBytes, err := json.Marshal(taskPayload)
	if err != nil {
		s.log.Error("failed to marshal task payload",
			logger.Error(err),
			logger.String("media_uuid", req.CloudUUID),
		)
		// 继续执行，不因为任务入队失败而失败
	} else {
		// 根据媒体类型选择不同的任务类型
		taskType := "media:process:image"
		if req.ItemType == "video" {
			taskType = "media:process:video"
		}

		if err := s.taskQueue.Enqueue(ctx,
			gq.NewTask(taskType, payloadBytes),
			gq.Queue("default"),
			gq.Priority(5),
		); err != nil {
			s.log.Error("failed to enqueue media process task",
				logger.Error(err),
				logger.String("media_uuid", req.CloudUUID),
			)
			// 继续执行，不因为任务入队失败而失败
		} else {
			s.log.Info("media process task enqueued",
				logger.String("media_uuid", req.CloudUUID),
				logger.String("task_type", taskType),
			)
		}
	}

	s.log.Info("media uploaded successfully",
		logger.String("uuid", req.CloudUUID),
		logger.String("hash", req.Hash),
		logger.Uint("user_id", req.UserID),
		logger.Int64("file_size", req.FileSize),
	)

	return media, nil
}
