package media

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
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
			log.Warn("image processing completed with errors",
				logger.String("media_uuid", payload.MediaUUID),
				logger.Int("error_count", len(result.Errors)),
			)
		}

		if err := repo.Update(ctx, payload.MediaUUID, updates); err != nil {
			return fmt.Errorf("update media metadata: %w", err)
		}

		log.Info("image processed successfully",
			logger.String("media_uuid", payload.MediaUUID),
			logger.Int("generated_files", len(result.GeneratedFiles)),
		)

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
			log.Warn("video processing completed with errors",
				logger.String("media_uuid", payload.MediaUUID),
				logger.Int("error_count", len(result.Errors)),
			)
		}

		if err := repo.Update(ctx, payload.MediaUUID, updates); err != nil {
			return fmt.Errorf("update media metadata: %w", err)
		}

		log.Info("video processed successfully",
			logger.String("media_uuid", payload.MediaUUID),
			logger.Int("generated_files", len(result.GeneratedFiles)),
		)

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
