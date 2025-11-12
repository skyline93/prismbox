package media

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/goccy/go-yaml"
)

// CommonOptions CLI 通用选项
type CommonOptions struct {
	BaseURL    string
	SocketPath string
	Email      string
	Password   string
	Timeout    time.Duration
	JSONOutput bool
	Quiet      bool
	DryRun     bool
}

// FileUploadOptions 单文件上传选项
type FileUploadOptions struct {
	CommonOptions
	FilePath string
}

// BatchUploadOptions 批量上传选项
type BatchUploadOptions struct {
	CommonOptions
	Dir          string
	ManifestPath string
	Concurrency  int
	OnError      string
}

// UploadTask 批量上传任务描述
type UploadTask struct {
	FilePath  string     `json:"file_path"`
	ItemType  string     `json:"item_type"`
	CaptureAt *time.Time `json:"capture_at,omitempty"`
	CloudUUID string     `json:"cloud_uuid,omitempty"`
}

// ResolvePaths 校验并解析路径
func (o *FileUploadOptions) ResolvePaths() error {
	if o.FilePath == "" {
		return errors.New("未提供文件路径")
	}
	if !filepath.IsAbs(o.FilePath) {
		abs, err := filepath.Abs(o.FilePath)
		if err != nil {
			return fmt.Errorf("解析文件路径失败: %w", err)
		}
		o.FilePath = abs
	}
	return nil
}

// ResolveBatchTasks 基于目录或清单文件生成上传任务
func (o *BatchUploadOptions) ResolveBatchTasks(ctx context.Context) ([]UploadTask, error) {
	if o.Dir != "" {
		return discoverTasksFromDir(o.Dir)
	}
	return loadTasksFromManifest(ctx, o.ManifestPath)
}

func discoverTasksFromDir(dir string) ([]UploadTask, error) {
	if !filepath.IsAbs(dir) {
		abs, err := filepath.Abs(dir)
		if err != nil {
			return nil, fmt.Errorf("解析目录路径失败: %w", err)
		}
		dir = abs
	}
	info, err := os.Stat(dir)
	if err != nil {
		return nil, fmt.Errorf("读取目录信息失败: %w", err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("指定路径不是目录: %s", dir)
	}

	var tasks []UploadTask
	err = filepath.Walk(dir, func(path string, info os.FileInfo, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if info.IsDir() {
			return nil
		}
		if strings.HasPrefix(info.Name(), ".") {
			return nil
		}
		itemType := detectItemType(info.Name())
		if itemType == "" {
			return nil
		}
		tasks = append(tasks, UploadTask{
			FilePath: path,
			ItemType: itemType,
		})
		return nil
	})
	if err != nil {
		return nil, err
	}
	if len(tasks) == 0 {
		return nil, fmt.Errorf("目录 %s 未发现可上传的媒体文件", dir)
	}
	return tasks, nil
}

func loadTasksFromManifest(ctx context.Context, manifestPath string) ([]UploadTask, error) {
	if manifestPath == "" {
		return nil, errors.New("未提供 manifest 路径")
	}
	data, err := os.ReadFile(manifestPath)
	if err != nil {
		return nil, fmt.Errorf("读取 manifest 失败: %w", err)
	}

	switch strings.ToLower(filepath.Ext(manifestPath)) {
	case ".yaml", ".yml":
		return parseManifestYAML(ctx, data)
	default:
		return parseManifestJSON(ctx, data)
	}
}

func detectItemType(filename string) string {
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(filename), "."))
	if ext == "" {
		return ""
	}
	if _, ok := imageExt[ext]; ok {
		return "image"
	}
	if _, ok := videoExt[ext]; ok {
		return "video"
	}
	return ""
}

var (
	imageExt = map[string]struct{}{
		"jpg": {}, "jpeg": {}, "png": {}, "gif": {}, "webp": {}, "bmp": {}, "heic": {}, "tif": {}, "tiff": {},
	}
	videoExt = map[string]struct{}{
		"mp4": {}, "mov": {}, "avi": {}, "mkv": {}, "webm": {}, "flv": {}, "wmv": {},
	}
)

func parseManifestJSON(_ context.Context, data []byte) ([]UploadTask, error) {
	var tasks []UploadTask
	if err := json.Unmarshal(data, &tasks); err != nil {
		return nil, fmt.Errorf("解析 JSON manifest 失败: %w", err)
	}
	return normalizeTasks(tasks)
}

func parseManifestYAML(_ context.Context, data []byte) ([]UploadTask, error) {
	var tasks []UploadTask
	if err := yaml.Unmarshal(data, &tasks); err != nil {
		return nil, fmt.Errorf("解析 YAML manifest 失败: %w", err)
	}
	return normalizeTasks(tasks)
}

func normalizeTasks(tasks []UploadTask) ([]UploadTask, error) {
	if len(tasks) == 0 {
		return nil, errors.New("manifest 未包含任何任务")
	}
	seen := make(map[string]struct{})
	for i := range tasks {
		task := &tasks[i]
		if task.FilePath == "" {
			return nil, fmt.Errorf("manifest 中存在缺少 file_path 的任务（索引 %d）", i)
		}
		if !filepath.IsAbs(task.FilePath) {
			abs, err := filepath.Abs(task.FilePath)
			if err != nil {
				return nil, fmt.Errorf("解析文件路径失败 (%s): %w", task.FilePath, err)
			}
			task.FilePath = abs
		}
		if task.ItemType == "" {
			task.ItemType = detectItemType(task.FilePath)
		}
		if task.ItemType == "" {
			return nil, fmt.Errorf("无法识别文件类型: %s", task.FilePath)
		}
		key := path.Clean(task.FilePath)
		if _, ok := seen[key]; ok {
			return nil, fmt.Errorf("manifest 中存在重复文件路径: %s", task.FilePath)
		}
		seen[key] = struct{}{}
	}
	return tasks, nil
}
