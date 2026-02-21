// Package pooluri 解析与构建存储池位置 URI（restic 风格），如 local:///absolute/path。
package pooluri

import (
	"fmt"
	"net/url"
	"path/filepath"
	"strings"
)

const (
	SchemeLocal = "local"
)

// Parse 解析 location URI，返回 scheme 与 path 部分。本地池 path 为绝对路径。
// 格式：local:///absolute/path（三斜杠表示 authority 为空）。
func Parse(location string) (scheme, path string, err error) {
	location = strings.TrimSpace(location)
	if location == "" {
		return "", "", fmt.Errorf("location is required")
	}
	u, err := url.Parse(location)
	if err != nil {
		return "", "", fmt.Errorf("parse location: %w", err)
	}
	scheme = strings.ToLower(u.Scheme)
	if scheme == "" {
		return "", "", fmt.Errorf("location must have scheme (e.g. local:///path)")
	}
	path = u.Path
	if u.Host != "" {
		// local://host/path 形式时 path 可能以 / 开头，保留
		path = "/" + strings.TrimPrefix(path, "/")
	}
	if scheme == SchemeLocal {
		path = filepath.FromSlash(path)
		if path == "" || path == "/" {
			return "", "", fmt.Errorf("local location must have path (e.g. local:///absolute/path)")
		}
		// local 仅接受绝对路径，不接受相对路径（避免随 cwd 变化）
		if !filepath.IsAbs(path) {
			return "", "", fmt.Errorf("local location path must be absolute (e.g. local:///absolute/path), got: %s", path)
		}
	}
	return scheme, path, nil
}

// PathFromLocation 从 location 解析出池根路径（仅 local 类型）。若 scheme 非 local 返回错误。
func PathFromLocation(location string) (string, error) {
	scheme, path, err := Parse(location)
	if err != nil {
		return "", err
	}
	if scheme != SchemeLocal {
		return "", fmt.Errorf("unsupported scheme for path: %s", scheme)
	}
	return path, nil
}

// ValidateLocalPath 校验本地池路径：须为非空且绝对路径。不校验路径是否真实存在（目录可由池加载时创建）。
func ValidateLocalPath(path string) error {
	path = filepath.Clean(path)
	if path == "" {
		return fmt.Errorf("path is required")
	}
	if !filepath.IsAbs(path) {
		return fmt.Errorf("path must be absolute, got: %s", path)
	}
	return nil
}

// BuildLocal 构建本地池的 location URI，path 将被规范化为绝对路径。
// 格式为 local:///absolute/path（三斜杠：scheme 后 "://" + path 的 "/" = 共三个斜杠）。
// 注意 abs 本身以 "/" 开头，故用 "://" 而非 ":///" 拼接，否则会得到 local:////path。
func BuildLocal(path string) (string, error) {
	path = filepath.Clean(strings.TrimSpace(path))
	if path == "" {
		return "", fmt.Errorf("path is required")
	}
	abs, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("absolute path: %w", err)
	}
	slashPath := filepath.ToSlash(abs)
	return SchemeLocal + "://" + slashPath, nil
}
