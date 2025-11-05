package local

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/album/backend/internal/storage/interfaces"
)

// PathResolver 路径解析器（Hash-based，与用户解耦）
type PathResolver struct {
	basePath string
}

// NewPathResolver 创建路径解析器
func NewPathResolver(basePath string) *PathResolver {
	return &PathResolver{
		basePath: basePath,
	}
}

// ResolveFilePath 解析文件路径（基于Hash，不基于用户）
func (pr *PathResolver) ResolveFilePath(uuid string, hash string, fileType interfaces.FileType) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}

	// 使用Hash前缀分区（2级目录）
	hashPrefix := hash[:2] // 前2位（00-ff）
	hashNext := hash[2:4]  // 3-4位（00-ff）

	basePath := filepath.Join(pr.basePath, "files", hashPrefix, hashNext)

	var filename string
	switch fileType {
	case interfaces.FileTypeOriginal:
		filename = uuid + ".jpg"
	case interfaces.FileTypeThumbnail:
		filename = uuid + "_thumb.jpg"
	case interfaces.FileTypePreview:
		filename = uuid + "_prev.jpg"
	case interfaces.FileTypeEncrypted:
		filename = uuid + "_encrypted.jpg"
	case interfaces.FileTypeCompressed:
		filename = uuid + "_compressed.jpg"
	default:
		return "", fmt.Errorf("unsupported file type: %s", fileType)
	}

	return filepath.Join(basePath, filename), nil
}

// ResolveTempPath 解析临时文件路径（基于上传ID）
func (pr *PathResolver) ResolveTempPath(uploadID string, category string) string {
	return filepath.Join(pr.basePath, "temp", category, uploadID+".tmp")
}

// ResolveStagingPath 解析待上传文件路径（基于Hash）
func (pr *PathResolver) ResolveStagingPath(uuid string, hash string) (string, error) {
	if len(hash) < 2 {
		return "", fmt.Errorf("hash must be at least 2 characters")
	}

	hashPrefix := hash[:2]
	return filepath.Join(pr.basePath, "staging", hashPrefix, uuid+".jpg"), nil
}

// ResolveKey 从key解析出uuid和hash（key格式：{hash[0:2]}/{hash[2:4]}/{uuid}.jpg）
func (pr *PathResolver) ResolveKey(key string) (uuid string, hash string, fileType interfaces.FileType, err error) {
	// key格式：ab/cd/abc-123.jpg 或 ab/cd/abc-123_thumb.jpg
	parts := strings.Split(key, "/")
	if len(parts) < 3 {
		return "", "", "", fmt.Errorf("invalid key format: %s", key)
	}

	hashPrefix := parts[0]
	hashNext := parts[1]
	filename := parts[len(parts)-1]

	hash = hashPrefix + hashNext

	// 解析文件名
	if strings.HasSuffix(filename, "_thumb.jpg") {
		uuid = strings.TrimSuffix(filename, "_thumb.jpg")
		fileType = interfaces.FileTypeThumbnail
	} else if strings.HasSuffix(filename, "_prev.jpg") {
		uuid = strings.TrimSuffix(filename, "_prev.jpg")
		fileType = interfaces.FileTypePreview
	} else if strings.HasSuffix(filename, "_encrypted.jpg") {
		uuid = strings.TrimSuffix(filename, "_encrypted.jpg")
		fileType = interfaces.FileTypeEncrypted
	} else if strings.HasSuffix(filename, "_compressed.jpg") {
		uuid = strings.TrimSuffix(filename, "_compressed.jpg")
		fileType = interfaces.FileTypeCompressed
	} else if strings.HasSuffix(filename, ".jpg") {
		uuid = strings.TrimSuffix(filename, ".jpg")
		fileType = interfaces.FileTypeOriginal
	} else {
		return "", "", "", fmt.Errorf("unsupported file extension: %s", filename)
	}

	return uuid, hash, fileType, nil
}

// GetKeyFromPath 从文件路径获取key（相对于basePath）
func (pr *PathResolver) GetKeyFromPath(filePath string) (string, error) {
	relPath, err := filepath.Rel(pr.basePath, filePath)
	if err != nil {
		return "", fmt.Errorf("get relative path: %w", err)
	}
	return relPath, nil
}
