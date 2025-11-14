package media

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/album/backend/internal/storage/interfaces"
)

// MediaFileType 业务层的文件类型
type MediaFileType string

const (
	MediaFileTypeOriginal  MediaFileType = "original"  // 原始文件
	MediaFileTypeThumbnail MediaFileType = "thumbnail" // 缩略图
	MediaFileTypePreview   MediaFileType = "preview"   // 预览图
)

// MediaCategory 媒体类别
type MediaCategory string

const (
	MediaCategoryImage MediaCategory = "image" // 图片
	MediaCategoryVideo MediaCategory = "video" // 视频
)

// StorageAdapter 存储适配器，将业务层的文件类型映射到存储层的扩展名和变体
type StorageAdapter struct{}

// NewStorageAdapter 创建存储适配器
func NewStorageAdapter() *StorageAdapter {
	return &StorageAdapter{}
}

// ToStorageOptions 将业务层选项转换为存储层选项
// itemType: "image" 或 "video"
// mediaType: "original", "thumbnail", "preview"
// originalExtension: 原始文件的扩展名（如 "jpg", "mp4", "arw"）
func (a *StorageAdapter) ToStorageOptions(itemType string, mediaType MediaFileType, originalExtension string) (*interfaces.PutOptions, error) {
	category := MediaCategory(strings.ToLower(itemType))
	if category != MediaCategoryImage && category != MediaCategoryVideo {
		return nil, fmt.Errorf("unsupported item type: %s", itemType)
	}

	opts := &interfaces.PutOptions{}

	switch mediaType {
	case MediaFileTypeOriginal:
		// 原始文件：使用原始扩展名，无变体标识
		opts.Extension = normalizeExtension(originalExtension)
		opts.Variant = ""

	case MediaFileTypeThumbnail:
		// 缩略图：根据媒体类别决定扩展名
		if category == MediaCategoryImage {
			// 图片缩略图：统一使用 jpg 格式
			opts.Extension = "jpg"
			opts.Variant = "thumbnail"
		} else if category == MediaCategoryVideo {
			// 视频缩略图：使用 jpg 格式（视频封面图）
			opts.Extension = "jpg"
			opts.Variant = "thumbnail"
		}

	case MediaFileTypePreview:
		// 预览图：根据媒体类别决定扩展名
		if category == MediaCategoryImage {
			// 图片预览图：统一使用 jpg 格式
			opts.Extension = "jpg"
			opts.Variant = "preview"
		} else if category == MediaCategoryVideo {
			// 视频预览图：使用 mp4 格式（与旧架构保持一致）
			opts.Extension = "mp4"
			opts.Variant = "preview"
		}

	default:
		return nil, fmt.Errorf("unsupported media type: %s", mediaType)
	}

	return opts, nil
}

// BuildStorageKey 构建存储key
// hash: 文件hash
// itemType: "image" 或 "video"
// mediaType: "original", "thumbnail", "preview"
// originalExtension: 原始文件的扩展名
func (a *StorageAdapter) BuildStorageKey(hash string, itemType string, mediaType MediaFileType, originalExtension string) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}

	opts, err := a.ToStorageOptions(itemType, mediaType, originalExtension)
	if err != nil {
		return "", err
	}

	// 构建key格式：{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}
	hashPrefix := hash[:2]
	hashNext := hash[2:4]

	var filename string
	if opts.Variant == "" {
		filename = fmt.Sprintf("%s.%s", hash, opts.Extension)
	} else {
		filename = fmt.Sprintf("%s_%s.%s", hash, opts.Variant, opts.Extension)
	}

	return fmt.Sprintf("%s/%s/%s", hashPrefix, hashNext, filename), nil
}

// ParseStorageKey 解析存储key，返回hash、扩展名和变体
func (a *StorageAdapter) ParseStorageKey(key string) (hash string, extension string, variant string, err error) {
	parts := strings.Split(key, "/")
	if len(parts) < 3 {
		return "", "", "", fmt.Errorf("invalid key format: %s", key)
	}

	hashPrefix := parts[0]
	hashNext := parts[1]
	filename := parts[len(parts)-1]

	// 解析文件扩展名
	ext := filepath.Ext(filename)
	if ext == "" {
		return "", "", "", fmt.Errorf("file extension required: %s", filename)
	}
	extension = strings.TrimPrefix(ext, ".")

	// 解析hash和变体标识
	base := strings.TrimSuffix(filename, ext)

	// 检查是否有变体标识（以下划线分隔）
	if idx := strings.LastIndex(base, "_"); idx > 0 {
		hash = base[:idx]
		variant = base[idx+1:]
	} else {
		hash = base
		variant = ""
	}

	if len(hash) < 4 {
		return "", "", "", fmt.Errorf("hash must be at least 4 characters")
	}

	// 基本校验：确保 hash 前缀与路径一致
	if !strings.HasPrefix(hash, hashPrefix+hashNext) {
		return "", "", "", fmt.Errorf("hash prefix mismatch with key: %s", key)
	}

	return hash, extension, variant, nil
}

// GetThumbnailKey 获取缩略图的存储key
func (a *StorageAdapter) GetThumbnailKey(hash string, itemType string, originalExtension string) (string, error) {
	return a.BuildStorageKey(hash, itemType, MediaFileTypeThumbnail, originalExtension)
}

// GetPreviewKey 获取预览图的存储key
func (a *StorageAdapter) GetPreviewKey(hash string, itemType string, originalExtension string) (string, error) {
	return a.BuildStorageKey(hash, itemType, MediaFileTypePreview, originalExtension)
}

// normalizeExtension 规范化扩展名（移除点号，转为小写）
func normalizeExtension(ext string) string {
	ext = strings.TrimPrefix(ext, ".")
	ext = strings.ToLower(ext)
	return ext
}

// IsImageExtension 判断是否为图片扩展名
func IsImageExtension(ext string) bool {
	ext = normalizeExtension(ext)
	imageExts := []string{"jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "arw", "cr2", "cr3", "nef", "raf", "dng", "orf", "rw2"}
	for _, imgExt := range imageExts {
		if ext == imgExt {
			return true
		}
	}
	return false
}

// IsVideoExtension 判断是否为视频扩展名
func IsVideoExtension(ext string) bool {
	ext = normalizeExtension(ext)
	videoExts := []string{"mp4", "mov", "avi", "mkv", "webm", "flv", "wmv", "m4v", "3gp"}
	for _, vidExt := range videoExts {
		if ext == vidExt {
			return true
		}
	}
	return false
}

// InferMediaCategory 根据扩展名推断媒体类别
func InferMediaCategory(ext string) MediaCategory {
	if IsImageExtension(ext) {
		return MediaCategoryImage
	}
	if IsVideoExtension(ext) {
		return MediaCategoryVideo
	}
	return "" // 未知类型
}
