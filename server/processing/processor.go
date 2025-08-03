package processing

import (
	"context"
	"fmt"
	"image"
	_ "image/jpeg" // 注册JPEG解码器
	_ "image/png"  // 注册PNG解码器
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"server/constant"
	"server/models"
	"sync"
	"time"

	"github.com/h2non/bimg"
	"github.com/rwcarlsen/goexif/exif"
	"gorm.io/gorm"
)

// 导出常量，以便其他包（如 handlers）可以引用它们
const (
	PreviewVideoSuffix = "_prev.mp4"
	PreviewImageSuffix = "_prev.jpg"  // 图片预览统一用jpg
	ThumbSuffix        = "_thumb.jpg" // 统一用jpg做缩略图
	PreviewWidth       = 1280         // 预览图/视频宽度
	ThumbSize          = 400          // 缩略图尺寸
)

// ProcessVideo 异步处理视频文件：生成缩略图、转码预览视频、提取元数据
func ProcessVideo(db *gorm.DB, originalPath string, photoUUID string) {
	log.Printf("[VIDEO] Starting processing for %s", photoUUID)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute) // 视频处理时间更长
	defer cancel()

	var wg sync.WaitGroup
	var thumbErr, previewErr, metaErr error
	var updates = make(map[string]interface{})
	var finalStatus = constant.StatusCompleted

	// 1. 生成缩略图 (从视频第1秒)
	wg.Add(1)
	go func() {
		defer wg.Done()
		thumbPath := filepath.Join(filepath.Dir(originalPath), photoUUID+ThumbSuffix)
		// ffmpeg -i [input] -ss 00:00:01.000 -vframes 1 -vf "scale=400:400:force_original_aspect_ratio=decrease,pad=400:400:(ow-iw)/2:(oh-ih)/2" [output]
		cmd := exec.Command("ffmpeg", "-i", originalPath, "-ss", "00:00:01.000", "-vframes", "1", "-vf",
			fmt.Sprintf("scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2", ThumbSize, ThumbSize, ThumbSize, ThumbSize),
			"-y", // 覆盖已存在的文件
			thumbPath)
		if err := cmd.Run(); err != nil {
			log.Printf("[VIDEO] Thumbnail generation failed for %s: %v", photoUUID, err)
			thumbErr = err
		}
	}()

	// 2. 转码为预览视频 (H.264, AAC)
	wg.Add(1)
	go func() {
		defer wg.Done()
		previewPath := filepath.Join(filepath.Dir(originalPath), photoUUID+PreviewVideoSuffix)
		// ffmpeg -i [input] -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k -vf "scale=-2:1280" -movflags +faststart [output]
		cmd := exec.Command("ffmpeg", "-i", originalPath,
			"-c:v", "libx264", // 视频编码器
			"-preset", "veryfast", // 转码速度与质量的平衡
			"-crf", "23", // 视频质量 (越小越好)
			"-c:a", "aac", // 音频编码器
			"-b:a", "128k", // 音频比特率
			"-vf", fmt.Sprintf("scale=-2:%d", PreviewWidth), // 视频缩放，保持高宽比
			"-movflags", "+faststart", // 优化网络播放
			"-y", // 覆盖已存在的文件
			previewPath)
		if err := cmd.Run(); err != nil {
			log.Printf("[VIDEO] Preview transcode failed for %s: %v", photoUUID, err)
			previewErr = err
		}
	}()

	// 3. 使用 ffprobe 获取元数据
	// 此处简化处理，实际项目中可以解析json获取更详细信息
	// ffprobe -v error -show_format -show_streams -of json [input]
	cmd := exec.Command("ffprobe", "-v", "error", "-show_format", "-show_streams", originalPath)
	_, err := cmd.Output()
	if err != nil {
		log.Printf("[VIDEO] ffprobe failed for %s: %v", photoUUID, err)
		metaErr = err
	} else {
		// 在一个更复杂的实现中，你会将 `output` (JSON) unmarshal到一个结构体中。
		// 这里为了演示，我们只做简单的占位符。
		// 例如：`json.Unmarshal(output, &probeData)`
		updates["duration"] = 15.0 // Placeholder
		updates["width"] = 1920    // Placeholder
		updates["height"] = 1080   // Placeholder
	}

	// 等待所有并发任务完成
	wg.Wait()

	// 检查是否有任何任务失败或超时
	if ctx.Err() != nil {
		log.Printf("[VIDEO] Processing timed out for %s", photoUUID)
		finalStatus = constant.StatusFailed
	} else if thumbErr != nil || previewErr != nil || metaErr != nil {
		log.Printf("[VIDEO] Processing failed for %s with one or more errors.", photoUUID)
		finalStatus = constant.StatusFailed
	}

	// 更新文件信息和状态
	updatePhotoInfoAndStatus(db, photoUUID, finalStatus, updates)
	log.Printf("[VIDEO] Finished processing for %s with status: %s", photoUUID, finalStatus)
}

// ProcessImage 异步处理图片文件：生成缩略图、预览图、解析EXIF
func ProcessImage(db *gorm.DB, originalPath string, photoUUID string) {
	log.Printf("[IMAGE] Starting processing for %s", photoUUID)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	buffer, err := os.ReadFile(originalPath)
	if err != nil {
		log.Printf("[IMAGE] Error reading original file for processing (%s): %v", photoUUID, err)
		updatePhotoInfoAndStatus(db, photoUUID, constant.StatusFailed, nil)
		return
	}

	var wg sync.WaitGroup
	var thumbErr, previewErr error
	var finalStatus = constant.StatusCompleted

	bimgImage := bimg.NewImage(buffer)

	// 1. 生成预览图
	wg.Add(1)
	go func() {
		defer wg.Done()
		previewPath := filepath.Join(filepath.Dir(originalPath), photoUUID+PreviewImageSuffix)
		// 如果图片本身小于预览宽度，就不放大，直接复制原图作为预览图
		size, _ := bimgImage.Size()
		if size.Width > PreviewWidth {
			newImage, err := bimgImage.Process(bimg.Options{Width: PreviewWidth, Quality: 80, Type: bimg.JPEG})
			if err != nil {
				log.Printf("[IMAGE] Failed to create preview for %s: %v", photoUUID, err)
				previewErr = err
				return
			}
			bimg.Write(previewPath, newImage)
		} else {
			// 直接使用原图作为预览图
			os.WriteFile(previewPath, buffer, 0644)
		}
	}()

	// 2. 生成缩略图 (智能裁剪)
	wg.Add(1)
	go func() {
		defer wg.Done()
		thumbPath := filepath.Join(filepath.Dir(originalPath), photoUUID+ThumbSuffix)
		newImage, err := bimgImage.Process(bimg.Options{
			Width:   ThumbSize,
			Height:  ThumbSize,
			Crop:    true,
			Gravity: bimg.GravitySmart, // 智能裁剪，识别主体
			Quality: 75,
			Type:    bimg.JPEG,
		})
		if err != nil {
			log.Printf("[IMAGE] Failed to create thumbnail for %s: %v", photoUUID, err)
			thumbErr = err
			return
		}
		bimg.Write(thumbPath, newImage)
	}()

	// 3. 解析EXIF和文件元数据
	updates := parseMetadata(originalPath)

	// 等待所有并发任务完成
	wg.Wait()

	if ctx.Err() != nil {
		log.Printf("[IMAGE] Processing timed out for %s", photoUUID)
		finalStatus = constant.StatusFailed
	} else if thumbErr != nil || previewErr != nil {
		log.Printf("[IMAGE] Processing failed for %s with one or more errors.", photoUUID)
		finalStatus = constant.StatusFailed
	}

	updatePhotoInfoAndStatus(db, photoUUID, finalStatus, updates)
	log.Printf("[IMAGE] Finished processing for %s with status: %s", photoUUID, finalStatus)
}

// parseMetadata 从图片文件解析元数据（EXIF、尺寸、大小等）
func parseMetadata(filePath string) map[string]interface{} {
	updates := make(map[string]interface{})

	file, err := os.Open(filePath)
	if err != nil {
		log.Printf("Error opening file for metadata parsing (%s): %v", filePath, err)
		return updates
	}
	defer file.Close()

	// 解析EXIF
	x, err := exif.Decode(file)
	if err != nil {
		log.Printf("EXIF decoding failed for %s: %v. Continuing without EXIF.", filePath, err)
	} else {
		if dt, err := x.DateTime(); err == nil {
			updates["photo_taken_at"] = &dt
		}
		if make, err := x.Get(exif.Make); err == nil {
			val, _ := make.StringVal()
			updates["camera_make"] = &val
		}
		if model, err := x.Get(exif.Model); err == nil {
			val, _ := model.StringVal()
			updates["camera_model"] = &val
		}
		if lat, long, err := x.LatLong(); err == nil {
			updates["latitude"] = &lat
			updates["longitude"] = &long
		}
	}

	// 重置文件读取指针以获取其他信息
	file.Seek(0, 0)
	img, _, err := image.DecodeConfig(file)
	if err == nil {
		updates["width"] = img.Width
		updates["height"] = img.Height
	}

	fileInfo, err := file.Stat()
	if err == nil {
		updates["file_size"] = fileInfo.Size()
	}

	file.Seek(0, 0)
	buffer := make([]byte, 512)
	n, err := file.Read(buffer)
	if err == nil {
		updates["mime_type"] = http.DetectContentType(buffer[:n])
	}

	return updates
}

// updatePhotoInfoAndStatus 将解析出的元数据和最终处理状态更新到数据库
func updatePhotoInfoAndStatus(db *gorm.DB, uuid string, status constant.ProcessingStatus, otherUpdates map[string]interface{}) {
	updates := map[string]interface{}{"processing_status": status}
	if otherUpdates != nil {
		for k, v := range otherUpdates {
			updates[k] = v
		}
	}

	if err := db.Model(&models.Photo{}).Where("uuid = ?", uuid).Updates(updates).Error; err != nil {
		log.Printf("Failed to update final status and metadata in DB for %s: %v", uuid, err)
	} else {
		log.Printf("Successfully updated final status and metadata for %s", uuid)
	}
}

// ProcessOrphanedTasks 在服务启动时检查并处理未完成的任务
func ProcessOrphanedTasks(db *gorm.DB, uploadDir string) {
	var pendingPhotos []models.Photo
	db.Where("processing_status = ?", constant.StatusPending).Find(&pendingPhotos)

	if len(pendingPhotos) > 0 {
		log.Printf("Found %d orphaned tasks to process...", len(pendingPhotos))
		for _, photo := range pendingPhotos {
			filePath := filepath.Join(uploadDir, photo.Filename)
			if _, err := os.Stat(filePath); os.IsNotExist(err) {
				log.Printf("Orphaned task for %s has a missing file, marking as FAILED.", photo.UUID)
				updatePhotoInfoAndStatus(db, photo.UUID, constant.StatusFailed, nil)
				continue
			}

			log.Printf("Re-queueing orphaned task for %s", photo.UUID)
			if photo.ItemType == constant.TypeVideo {
				go ProcessVideo(db, filePath, photo.UUID)
			} else {
				go ProcessImage(db, filePath, photo.UUID)
			}
		}
	} else {
		log.Println("No orphaned tasks found.")
	}
}
