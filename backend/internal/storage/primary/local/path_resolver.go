package local

import (
	"fmt"
	"path"
	"path/filepath"
	"strings"
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

// ResolveFilePath 解析文件路径（基于 Hash + 扩展名 + 变体）
func (pr *PathResolver) ResolveFilePath(hash string, extension string, variant string) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}

	if extension == "" {
		return "", fmt.Errorf("extension is required")
	}

	// 使用Hash前缀分区（2级目录）
	hashPrefix := hash[:2] // 前2位（00-ff）
	hashNext := hash[2:4]  // 3-4位（00-ff）

	basePath := filepath.Join(pr.basePath, "files", hashPrefix, hashNext)

	filename := buildFilename(hash, extension, variant)

	return filepath.Join(basePath, filename), nil
}

// ResolveTempPath 解析临时文件路径（基于上传ID）
func (pr *PathResolver) ResolveTempPath(uploadID string, category string) string {
	return filepath.Join(pr.basePath, "temp", category, uploadID+".tmp")
}

// ResolveStagingPath 解析待上传文件路径（基于Hash + 扩展名）
func (pr *PathResolver) ResolveStagingPath(hash string, extension string) (string, error) {
	if len(hash) < 2 {
		return "", fmt.Errorf("hash must be at least 2 characters")
	}

	if extension == "" {
		return "", fmt.Errorf("extension is required")
	}

	hashPrefix := hash[:2]
	filename := fmt.Sprintf("%s.%s", hash, extension)
	return filepath.Join(pr.basePath, "staging", hashPrefix, filename), nil
}

// ResolveKey 从key解析出hash、扩展名和变体
// key格式：{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}
// 例如：ab/cd/abcd1234.jpg, ab/cd/abcd1234_thumb.jpg, ab/cd/abcd1234_prev.jpg
func (pr *PathResolver) ResolveKey(key string) (hash string, extension string, variant string, err error) {
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
	// 变体标识通常出现在hash之后，如：hash_thumb, hash_prev
	if idx := strings.LastIndex(base, "_"); idx > 0 {
		hash = base[:idx]
		variant = base[idx+1:]
	} else {
		hash = base
		variant = "" // 默认变体（通常是 original）
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

// BuildKey 根据 hash、扩展名和变体构建 key（相对于 basePath）
func (pr *PathResolver) BuildKey(hash string, extension string, variant string) (string, error) {
	if len(hash) < 4 {
		return "", fmt.Errorf("hash must be at least 4 characters")
	}

	if extension == "" {
		return "", fmt.Errorf("extension is required")
	}

	filename := buildFilename(hash, extension, variant)
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

// buildFilename 构建文件名
// 格式：{hash}[_variant].{extension}
// 例如：abcd1234.jpg, abcd1234_thumb.jpg, abcd1234_prev.jpg
func buildFilename(hash string, extension string, variant string) string {
	if variant == "" {
		return fmt.Sprintf("%s.%s", hash, extension)
	}
	return fmt.Sprintf("%s_%s.%s", hash, variant, extension)
}
