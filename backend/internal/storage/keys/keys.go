// Package keys 提供存储层唯一的 key 格式与解析，格式：files/{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}
package keys

import (
	"fmt"
	"path"
	"path/filepath"
	"strings"
)

// KeyPathPrefix 相对路径前缀，key 与池根拼接时使用。
const KeyPathPrefix = "files"

// Variant 常量（与业务层 MediaFileType 对应）
const (
	VariantThumbnail = "thumbnail"
	VariantPreview   = "preview"
)

// DynamicThumbnailVariantPrefix 动态缩略图 variant 前缀，格式为 thumbnail_{width}x{height}
const DynamicThumbnailVariantPrefix = "thumbnail_"

// BuildKey 根据 hash、扩展名和变体构建 key（相对路径），格式：files/{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}
func BuildKey(hash string, extension string, variant string) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}
	if extension == "" {
		return "", fmt.Errorf("extension is required")
	}
	filename := buildFilename(hash, extension, variant)
	return path.Join(KeyPathPrefix, hash[:2], hash[2:4], filename), nil
}

// ResolveKey 从 key 解析出 hash、扩展名和变体。key 必须为 files/{hash[0:2]}/{hash[2:4]}/{filename} 格式。
func ResolveKey(key string) (hash string, extension string, variant string, err error) {
	parts := strings.Split(key, "/")
	if len(parts) != 4 || parts[0] != KeyPathPrefix {
		return "", "", "", fmt.Errorf("invalid key format (expected files/xx/xx/filename): %s", key)
	}
	hashPrefix := parts[1]
	hashNext := parts[2]
	filename := parts[3]

	ext := filepath.Ext(filename)
	if ext == "" {
		return "", "", "", fmt.Errorf("file extension required: %s", filename)
	}
	extension = strings.TrimPrefix(ext, ".")
	base := strings.TrimSuffix(filename, ext)

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
	if !strings.HasPrefix(hash, hashPrefix+hashNext) {
		return "", "", "", fmt.Errorf("hash prefix mismatch with key: %s", key)
	}
	return hash, extension, variant, nil
}

func buildFilename(hash string, extension string, variant string) string {
	if variant == "" {
		return fmt.Sprintf("%s.%s", hash, extension)
	}
	return fmt.Sprintf("%s_%s.%s", hash, variant, extension)
}
