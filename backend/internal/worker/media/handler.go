package media

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/thumbhash"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
)

// RegisterMediaProcessors 注册媒体处理任务。
func RegisterMediaProcessors(
	mux *gq.ServeMux,
	repo repository.MediaRepository,
	storageManager *storage.StorageManager,
	processor mediaprocessor.MediaProcessor,
) {
	mux.HandleFunc("media:process:image", processImageHandler(repo, storageManager, processor))
	mux.HandleFunc("media:process:video", processVideoHandler(repo, storageManager, processor))
}

type processPayload struct {
	MediaUUID string `json:"media_uuid"`
	FilePath  string `json:"file_path"`
	UserID    uint   `json:"user_id"`
}

func processImageHandler(
	repo repository.MediaRepository,
	storageManager *storage.StorageManager,
	processor mediaprocessor.MediaProcessor,
) gq.HandlerFunc {
	log := logger.New("worker.media.image")

	return func(ctx context.Context, task *gq.Task) error {
		var payload processPayload
		if err := json.Unmarshal(task.Payload, &payload); err != nil {
			return fmt.Errorf("invalid payload: %w", err)
		}

		if payload.MediaUUID == "" || payload.FilePath == "" {
			return fmt.Errorf("media_uuid and file_path are required")
		}

		media, err := repo.FindByUUID(ctx, payload.MediaUUID)
		if err != nil {
			return fmt.Errorf("find media %s: %w", payload.MediaUUID, err)
		}

		if !strings.EqualFold(media.ItemType, "image") {
			return fmt.Errorf("media %s is not image type", payload.MediaUUID)
		}

		originalPath, err := storageManager.GetSignedURL(ctx, payload.FilePath, 10*time.Minute)
		if err != nil {
			return fmt.Errorf("resolve image path: %w", err)
		}

		log.Debug("starting image processing",
			logger.String("media_uuid", payload.MediaUUID),
			logger.String("file_path", payload.FilePath),
			logger.String("original_path", originalPath),
		)

		result, procErr := processor.ProcessImage(ctx, originalPath, nil)
		status := "COMPLETED"
		updates := map[string]interface{}{
			"processing_status": status,
		}

		if procErr != nil {
			status = "FAILED"
			updates["processing_status"] = status
			updateErr := repo.Update(ctx, payload.MediaUUID, updates)
			if updateErr != nil {
				log.Error("failed to update media after processing error",
					logger.Error(updateErr),
					logger.String("media_uuid", payload.MediaUUID),
				)
			}
			return fmt.Errorf("process image: %w", procErr)
		}

		if result.Metadata != nil {
			applyMetadataToUpdates(result.Metadata, updates)
		}

		if len(result.GeneratedFiles) > 0 {
			updates["local_path"] = payload.FilePath
		}

		if len(result.Errors) > 0 {
			status = "FAILED"
			updates["processing_status"] = status
			// 构建详细的错误信息
			errorDetails := make([]string, len(result.Errors))
			for i, err := range result.Errors {
				errorDetails[i] = fmt.Sprintf("%s: %s", err.Spec, err.Message)
			}
			log.Warn("image processing completed with errors",
				logger.String("media_uuid", payload.MediaUUID),
				logger.String("original_path", originalPath),
				logger.Int("error_count", len(result.Errors)),
				logger.String("errors", strings.Join(errorDetails, "; ")),
			)
			// 为每个错误单独记录日志，便于调试
			for _, err := range result.Errors {
				log.Error("image processing error for spec",
					logger.String("media_uuid", payload.MediaUUID),
					logger.String("spec", err.Spec),
					logger.String("error_message", err.Message),
					logger.Error(err.Err),
				)
			}
		}

		// 生成 ThumbHash（仅图片类型，失败不阻塞主流程）
		if status == "COMPLETED" && strings.EqualFold(media.ItemType, "image") {
			thumbHashStartTime := time.Now()
			thumbHash, err := generateThumbHash(ctx, originalPath)
			thumbHashLatency := time.Since(thumbHashStartTime)
			if err == nil && thumbHash != "" {
				updates["thumb_hash"] = thumbHash
				log.Info("thumbhash generated successfully",
					logger.String("media_uuid", payload.MediaUUID),
					logger.String("original_path", originalPath),
					logger.Duration("generation_latency_ms", thumbHashLatency),
					logger.Int("thumbhash_length", len(thumbHash)),
					logger.String("thumbhash_value", thumbHash),
				)
				log.Debug("updates map after adding thumbhash",
					logger.String("media_uuid", payload.MediaUUID),
					logger.String("updates", fmt.Sprintf("%+v", updates)),
				)
			} else {
				log.Warn("failed to generate thumbhash (non-fatal, continuing)",
					logger.String("media_uuid", payload.MediaUUID),
					logger.String("original_path", originalPath),
					logger.Duration("generation_latency_ms", thumbHashLatency),
					logger.Error(err),
				)
			}
		}

		if err := repo.Update(ctx, payload.MediaUUID, updates); err != nil {
			return fmt.Errorf("update media metadata: %w", err)
		}

		log.Info("image processed successfully",
			logger.String("media_uuid", payload.MediaUUID),
			logger.String("original_path", originalPath),
			logger.Int("generated_files", len(result.GeneratedFiles)),
		)
		if len(result.GeneratedFiles) > 0 {
			log.Debug("generated files list",
				logger.String("media_uuid", payload.MediaUUID),
				logger.String("files", strings.Join(result.GeneratedFiles, ", ")),
			)
		}

		return nil
	}
}

func processVideoHandler(
	repo repository.MediaRepository,
	storageManager *storage.StorageManager,
	processor mediaprocessor.MediaProcessor,
) gq.HandlerFunc {
	log := logger.New("worker.media.video")

	return func(ctx context.Context, task *gq.Task) error {
		var payload processPayload
		if err := json.Unmarshal(task.Payload, &payload); err != nil {
			return fmt.Errorf("invalid payload: %w", err)
		}

		if payload.MediaUUID == "" || payload.FilePath == "" {
			return fmt.Errorf("media_uuid and file_path are required")
		}

		media, err := repo.FindByUUID(ctx, payload.MediaUUID)
		if err != nil {
			return fmt.Errorf("find media %s: %w", payload.MediaUUID, err)
		}

		if !strings.EqualFold(media.ItemType, "video") {
			return fmt.Errorf("media %s is not video type", payload.MediaUUID)
		}

		originalPath, err := storageManager.GetSignedURL(ctx, payload.FilePath, 10*time.Minute)
		if err != nil {
			return fmt.Errorf("resolve video path: %w", err)
		}

		log.Debug("starting video processing",
			logger.String("media_uuid", payload.MediaUUID),
			logger.String("file_path", payload.FilePath),
			logger.String("original_path", originalPath),
		)

		result, procErr := processor.ProcessVideo(ctx, originalPath, nil)
		status := "COMPLETED"
		updates := map[string]interface{}{
			"processing_status": status,
		}

		if procErr != nil {
			status = "FAILED"
			updates["processing_status"] = status
			updateErr := repo.Update(ctx, payload.MediaUUID, updates)
			if updateErr != nil {
				log.Error("failed to update media after processing error",
					logger.Error(updateErr),
					logger.String("media_uuid", payload.MediaUUID),
				)
			}
			return fmt.Errorf("process video: %w", procErr)
		}

		if result.Metadata != nil {
			applyMetadataToUpdates(result.Metadata, updates)
		}

		if len(result.GeneratedFiles) > 0 {
			updates["local_path"] = payload.FilePath
		}

		if len(result.Errors) > 0 {
			status = "FAILED"
			updates["processing_status"] = status
			// 构建详细的错误信息
			errorDetails := make([]string, len(result.Errors))
			for i, err := range result.Errors {
				errorDetails[i] = fmt.Sprintf("%s: %s", err.Spec, err.Message)
			}
			log.Warn("video processing completed with errors",
				logger.String("media_uuid", payload.MediaUUID),
				logger.String("original_path", originalPath),
				logger.Int("error_count", len(result.Errors)),
				logger.String("errors", strings.Join(errorDetails, "; ")),
			)
			// 为每个错误单独记录日志，便于调试
			for _, err := range result.Errors {
				log.Error("video processing error for spec",
					logger.String("media_uuid", payload.MediaUUID),
					logger.String("spec", err.Spec),
					logger.String("error_message", err.Message),
					logger.Error(err.Err),
				)
			}
		}

		if err := repo.Update(ctx, payload.MediaUUID, updates); err != nil {
			return fmt.Errorf("update media metadata: %w", err)
		}

		log.Info("video processed successfully",
			logger.String("media_uuid", payload.MediaUUID),
			logger.String("original_path", originalPath),
			logger.Int("generated_files", len(result.GeneratedFiles)),
		)
		if len(result.GeneratedFiles) > 0 {
			log.Debug("generated files list",
				logger.String("media_uuid", payload.MediaUUID),
				logger.String("files", strings.Join(result.GeneratedFiles, ", ")),
			)
		}

		return nil
	}
}

func applyMetadataToUpdates(metadata *mediaprocessor.MediaMetadata, updates map[string]interface{}) {
	if metadata == nil {
		return
	}

	if metadata.Width != nil {
		updates["width"] = *metadata.Width
	}
	if metadata.Height != nil {
		updates["height"] = *metadata.Height
	}
	if metadata.FileSize != nil {
		updates["file_size"] = *metadata.FileSize
	}
	if metadata.MimeType != nil {
		updates["mime_type"] = *metadata.MimeType
	}
	if metadata.MediaTakenAt != nil {
		updates["media_taken_at"] = *metadata.MediaTakenAt
	}
	if metadata.CameraMake != nil {
		updates["camera_make"] = *metadata.CameraMake
	}
	if metadata.CameraModel != nil {
		updates["camera_model"] = *metadata.CameraModel
	}
	if metadata.Latitude != nil {
		updates["latitude"] = *metadata.Latitude
	}
	if metadata.Longitude != nil {
		updates["longitude"] = *metadata.Longitude
	}
	if metadata.Duration != nil {
		updates["duration"] = *metadata.Duration
	}
}

// generateThumbHash 生成 ThumbHash 占位符
func generateThumbHash(ctx context.Context, imagePath string) (string, error) {
	generator, err := thumbhash.NewGenerator()
	if err != nil {
		return "", fmt.Errorf("create generator: %w", err)
	}

	thumbHash, err := generator.GenerateFromFile(ctx, imagePath)
	if err != nil {
		return "", fmt.Errorf("generate thumbhash: %w", err)
	}

	return thumbHash, nil
}
