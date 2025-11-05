package config

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Duration 自定义时长类型（支持 "1h", "30m", "5s" 等格式）
type Duration time.Duration

// UnmarshalYAML 从YAML解析Duration
func (d *Duration) UnmarshalYAML(unmarshal func(interface{}) error) error {
	var s string
	if err := unmarshal(&s); err != nil {
		return err
	}
	duration, err := time.ParseDuration(s)
	if err != nil {
		return fmt.Errorf("invalid duration format: %s", s)
	}
	*d = Duration(duration)
	return nil
}

// MarshalYAML 序列化为YAML
func (d Duration) MarshalYAML() (interface{}, error) {
	return time.Duration(d).String(), nil
}

// Duration 转换为time.Duration
func (d Duration) Duration() time.Duration {
	return time.Duration(d)
}

// Size 自定义大小类型（支持 "1GB", "500MB", "100KB" 等格式）
type Size int64

// UnmarshalYAML 从YAML解析Size
func (s *Size) UnmarshalYAML(unmarshal func(interface{}) error) error {
	var str string
	if err := unmarshal(&str); err != nil {
		return err
	}
	size, err := parseSize(str)
	if err != nil {
		return err
	}
	*s = Size(size)
	return nil
}

// MarshalYAML 序列化为YAML
func (s Size) MarshalYAML() (interface{}, error) {
	return formatSize(int64(s)), nil
}

// Int64 转换为int64
func (s Size) Int64() int64 {
	return int64(s)
}

// parseSize 解析大小字符串（如 "1GB", "500MB"）
func parseSize(s string) (int64, error) {
	s = strings.TrimSpace(s)
	s = strings.ToUpper(s)

	// 移除可能的空格
	s = strings.ReplaceAll(s, " ", "")

	// 查找单位
	var unit string
	var valueStr string

	units := []string{"TB", "GB", "MB", "KB", "B"}
	for _, u := range units {
		if strings.HasSuffix(s, u) {
			unit = u
			valueStr = strings.TrimSuffix(s, u)
			break
		}
	}

	if unit == "" {
		// 没有单位，尝试直接解析为字节
		value, err := strconv.ParseInt(s, 10, 64)
		if err != nil {
			return 0, fmt.Errorf("invalid size format: %s", s)
		}
		return value, nil
	}

	value, err := strconv.ParseFloat(valueStr, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid size value: %s", valueStr)
	}

	var multiplier int64
	switch unit {
	case "TB":
		multiplier = 1024 * 1024 * 1024 * 1024
	case "GB":
		multiplier = 1024 * 1024 * 1024
	case "MB":
		multiplier = 1024 * 1024
	case "KB":
		multiplier = 1024
	case "B":
		multiplier = 1
	default:
		return 0, fmt.Errorf("unknown size unit: %s", unit)
	}

	return int64(value * float64(multiplier)), nil
}

// formatSize 格式化大小为字符串
func formatSize(size int64) string {
	const (
		KB = 1024
		MB = KB * 1024
		GB = MB * 1024
		TB = GB * 1024
	)

	switch {
	case size >= TB:
		return fmt.Sprintf("%.2fTB", float64(size)/float64(TB))
	case size >= GB:
		return fmt.Sprintf("%.2fGB", float64(size)/float64(GB))
	case size >= MB:
		return fmt.Sprintf("%.2fMB", float64(size)/float64(MB))
	case size >= KB:
		return fmt.Sprintf("%.2fKB", float64(size)/float64(KB))
	default:
		return fmt.Sprintf("%dB", size)
	}
}
