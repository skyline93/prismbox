package local

import (
	"fmt"
	"path"
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

// ResolveFilePath 解析文件路径（基于 Hash 的内容寻址）
func (pr *PathResolver) ResolveFilePath(hash string, fileType interfaces.FileType) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}

	// 使用Hash前缀分区（2级目录）
	hashPrefix := hash[:2] // 前2位（00-ff）
	hashNext := hash[2:4]  // 3-4位（00-ff）

	basePath := filepath.Join(pr.basePath, "files", hashPrefix, hashNext)

	filename, err := buildFilename(hash, fileType)
	if err != nil {
		return "", err
	}

	return filepath.Join(basePath, filename), nil
}

// ResolveTempPath 解析临时文件路径（基于上传ID）
func (pr *PathResolver) ResolveTempPath(uploadID string, category string) string {
	return filepath.Join(pr.basePath, "temp", category, uploadID+".tmp")
}

// ResolveStagingPath 解析待上传文件路径（基于Hash）
func (pr *PathResolver) ResolveStagingPath(hash string) (string, error) {
	if len(hash) < 2 {
		return "", fmt.Errorf("hash must be at least 2 characters")
	}

	hashPrefix := hash[:2]
	return filepath.Join(pr.basePath, "staging", hashPrefix, hash+".jpg"), nil
}

// ResolveKey 从key解析出hash和文件类型（key格式：{hash[0:2]}/{hash[2:4]}/{hash}[suffix].jpg）
func (pr *PathResolver) ResolveKey(key string) (hash string, fileType interfaces.FileType, err error) {
	// key格式：ab/cd/abcd1234....jpg 或 ab/cd/abcd1234...._thumb.jpg
	parts := strings.Split(key, "/")
	if len(parts) < 3 {
		return "", "", fmt.Errorf("invalid key format: %s", key)
	}

	hashPrefix := parts[0]
	hashNext := parts[1]
	filename := parts[len(parts)-1]

	// 解析文件名
	var base string
	if strings.HasSuffix(filename, "_thumb.jpg") {
		base = strings.TrimSuffix(filename, "_thumb.jpg")
		fileType = interfaces.FileTypeThumbnail
	} else if strings.HasSuffix(filename, "_prev.jpg") {
		base = strings.TrimSuffix(filename, "_prev.jpg")
		fileType = interfaces.FileTypePreview
	} else if strings.HasSuffix(filename, "_encrypted.jpg") {
		base = strings.TrimSuffix(filename, "_encrypted.jpg")
		fileType = interfaces.FileTypeEncrypted
	} else if strings.HasSuffix(filename, "_compressed.jpg") {
		base = strings.TrimSuffix(filename, "_compressed.jpg")
		fileType = interfaces.FileTypeCompressed
	} else if strings.HasSuffix(filename, ".jpg") {
		base = strings.TrimSuffix(filename, ".jpg")
		fileType = interfaces.FileTypeOriginal
	} else {
		return "", "", fmt.Errorf("unsupported file extension: %s", filename)
	}

	hash = base
	if len(hash) < 4 {
		return "", "", fmt.Errorf("hash must be at least 4 characters")
	}

	// 基本校验：确保 hash 前缀与路径一致
	if !strings.HasPrefix(hash, hashPrefix+hashNext) {
		return "", "", fmt.Errorf("hash prefix mismatch with key: %s", key)
	}

	return hash, fileType, nil
}

// BuildKey 根据 hash 与文件类型构建 key（相对于 basePath）
func (pr *PathResolver) BuildKey(hash string, fileType interfaces.FileType) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}

	filename, err := buildFilename(hash, fileType)
	if err != nil {
		return "", err
	}

	return path.Join(hash[:2], hash[2:4], filename), nil
}

// GetKeyFromPath 从文件路径获取key（相对于basePath）
func (pr *PathResolver) GetKeyFromPath(filePath string) (string, error) {
	relPath, err := filepath.Rel(pr.basePath, filePath)
	if err != nil {
		return "", fmt.Errorf("get relative path: %w", err)
	}
	return relPath, nil
}

func buildFilename(hash string, fileType interfaces.FileType) (string, error) {
	var suffix string
	switch fileType {
	case interfaces.FileTypeOriginal:
		suffix = ""
	case interfaces.FileTypeThumbnail:
		suffix = "_thumb"
	case interfaces.FileTypePreview:
		suffix = "_prev"
	case interfaces.FileTypeEncrypted:
		suffix = "_encrypted"
	case interfaces.FileTypeCompressed:
		suffix = "_compressed"
	default:
		return "", fmt.Errorf("unsupported file type: %s", fileType)
	}

	return fmt.Sprintf("%s%s.jpg", hash, suffix), nil
}
