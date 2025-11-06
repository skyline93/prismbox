package media

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
)

// RegisterMediaProcessors 注册媒体处理任务
func RegisterMediaProcessors(mux *gq.ServeMux) {
	mux.HandleFunc("media:process:image", processImageHandler)
	mux.HandleFunc("media:process:video", processVideoHandler)
}

// processImageHandler 处理图片处理任务（空跑）
func processImageHandler(ctx context.Context, task *gq.Task) error {
	log := logger.New("worker.media.image")

	var payload map[string]interface{}
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	mediaUUID, ok := payload["media_uuid"].(string)
	if !ok {
		return fmt.Errorf("missing or invalid media_uuid in payload")
	}

	filePath, ok := payload["file_path"].(string)
	if !ok {
		return fmt.Errorf("missing or invalid file_path in payload")
	}

	// TODO: 实现实际的图片处理逻辑
	// 1. 从本地存储读取原始图片
	// 2. 提取 EXIF 元数据
	// 3. 生成缩略图（400x400）
	// 4. 生成预览图（1280px 宽度）
	// 5. 更新数据库记录

	log.Info("processing image (placeholder)",
		logger.String("media_uuid", mediaUUID),
		logger.String("file_path", filePath),
	)

	// 空跑，直接返回成功
	return nil
}

// processVideoHandler 处理视频处理任务（空跑）
func processVideoHandler(ctx context.Context, task *gq.Task) error {
	log := logger.New("worker.media.video")

	var payload map[string]interface{}
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	mediaUUID, ok := payload["media_uuid"].(string)
	if !ok {
		return fmt.Errorf("missing or invalid media_uuid in payload")
	}

	filePath, ok := payload["file_path"].(string)
	if !ok {
		return fmt.Errorf("missing or invalid file_path in payload")
	}

	// TODO: 实现实际的视频处理逻辑
	// 1. 从本地存储读取原始视频
	// 2. 提取元数据
	// 3. 生成缩略图（从第 1 秒提取帧）
	// 4. 生成预览视频（1280px 宽度）
	// 5. 更新数据库记录

	log.Info("processing video (placeholder)",
		logger.String("media_uuid", mediaUUID),
		logger.String("file_path", filePath),
	)

	// 空跑，直接返回成功
	return nil
}
