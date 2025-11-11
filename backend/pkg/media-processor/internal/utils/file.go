package utils

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// EnsureDir 确保目标目录存在。
func EnsureDir(path string) error {
	dir := filepath.Dir(path)
	if dir == "" || dir == "." {
		return nil
	}
	return os.MkdirAll(dir, 0o755)
}

// BuildDerivedPath 根据原始文件生成派生文件路径。
func BuildDerivedPath(originalPath, specName, format string) (string, error) {
	if originalPath == "" {
		return "", fmt.Errorf("media-processor: original path empty")
	}
	if specName == "" {
		specName = "derived"
	}

	ext := strings.ToLower(strings.TrimPrefix(format, "."))
	if ext == "" {
		ext = strings.TrimPrefix(filepath.Ext(originalPath), ".")
	}

	dir := filepath.Dir(originalPath)
	base := strings.TrimSuffix(filepath.Base(originalPath), filepath.Ext(originalPath))
	filename := fmt.Sprintf("%s_%s.%s", base, specName, ext)
	return filepath.Join(dir, filename), nil
}

// FileExists 判断文件是否存在。
func FileExists(path string) bool {
	if path == "" {
		return false
	}
	_, err := os.Stat(path)
	return err == nil
}

// FileSize 返回文件大小。
func FileSize(path string) (int64, error) {
	info, err := os.Stat(path)
	if err != nil {
		return 0, err
	}
	return info.Size(), nil
}
