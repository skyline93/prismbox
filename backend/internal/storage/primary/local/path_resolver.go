package local

import (
	"fmt"
	"path/filepath"

	"github.com/album/backend/internal/storage/keys"
)

// KeyPathPrefix 重新导出，供本包内或同层使用；池内文件路径为 pool.Path + key。
const KeyPathPrefix = keys.KeyPathPrefix

// PathResolver 路径解析器（Hash-based，与用户解耦）。
// BasePath 仅用于 ResolveTempPath、ResolveStagingPath 及可配置的缓存根目录，不参与池内文件路径。
// 池内文件路径 = pool.Path + 相对路径 key（ResolveFilePath 返回相对路径）。
type PathResolver struct {
	basePath string
}

// NewPathResolver 创建路径解析器
func NewPathResolver(basePath string) *PathResolver {
	return &PathResolver{
		basePath: basePath,
	}
}

// ResolveFilePath 解析文件相对路径（基于 Hash + 扩展名 + 变体），不包含 BasePath；与 keys.BuildKey 一致。
func (pr *PathResolver) ResolveFilePath(hash string, extension string, variant string) (string, error) {
	return keys.BuildKey(hash, extension, variant)
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

// ResolveKey 从 key 解析出 hash、扩展名和变体，委托 keys.ResolveKey。
func (pr *PathResolver) ResolveKey(key string) (hash string, extension string, variant string, err error) {
	return keys.ResolveKey(key)
}

// BuildKey 根据 hash、扩展名和变体构建 key（相对于池根），委托 keys.BuildKey。
func (pr *PathResolver) BuildKey(hash string, extension string, variant string) (string, error) {
	return keys.BuildKey(hash, extension, variant)
}

// GetKeyFromPath 从池根下的完整路径获取 key（相对路径）。poolRoot 为池根目录，fullPath 为文件完整路径。
func (pr *PathResolver) GetKeyFromPath(poolRoot, fullPath string) (string, error) {
	relPath, err := filepath.Rel(poolRoot, fullPath)
	if err != nil {
		return "", fmt.Errorf("get relative path: %w", err)
	}
	return filepath.ToSlash(relPath), nil
}

