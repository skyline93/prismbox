package media

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
	"github.com/schollz/progressbar/v3"

	"github.com/album/backend/internal/cli/remote"
	"github.com/album/backend/pkg/hashutil"
)

// RunFileUpload 执行单文件上传
func RunFileUpload(ctx context.Context, opts FileUploadOptions) error {
	if err := opts.ResolvePaths(); err != nil {
		return err
	}

	prepared, err := prepareUploadTask(opts.FilePath, nil)
	if err != nil {
		return err
	}

	if opts.DryRun {
		printPreparedTask(prepared, opts.JSONOutput)
		return nil
	}

	client, err := remote.NewClient(remote.Config{
		BaseURL:    opts.BaseURL,
		SocketPath: opts.SocketPath,
		Timeout:    opts.Timeout,
	})
	if err != nil {
		return err
	}

	if err := authenticateClient(ctx, client, opts.CommonOptions); err != nil {
		return err
	}

	return uploadSingle(ctx, client, prepared, opts.Quiet, opts.JSONOutput)
}

// RunBatchUpload 执行批量上传
func RunBatchUpload(ctx context.Context, opts BatchUploadOptions) error {
	tasks, err := opts.ResolveBatchTasks(ctx)
	if err != nil {
		return err
	}

	prepared := make([]PreparedTask, 0, len(tasks))
	for i := range tasks {
		task := tasks[i]
		pt, err := prepareUploadTask(task.FilePath, &task)
		if err != nil {
			return err
		}
		prepared = append(prepared, pt)
	}

	if opts.DryRun {
		printPreparedTasks(prepared, opts.JSONOutput)
		return nil
	}

	client, err := remote.NewClient(remote.Config{
		BaseURL:    opts.BaseURL,
		SocketPath: opts.SocketPath,
		Timeout:    opts.Timeout,
	})
	if err != nil {
		return err
	}

	if err := authenticateClient(ctx, client, opts.CommonOptions); err != nil {
		return err
	}

	return uploadBatch(ctx, client, prepared, opts.Concurrency, opts.OnError, opts.Quiet, opts.JSONOutput)
}

// PreparedTask 上传任务准备结果
type PreparedTask struct {
	FilePath         string     `json:"file_path"`
	ItemType         string     `json:"item_type"`
	CaptureAt        *time.Time `json:"capture_at,omitempty"`
	CloudUUID        string     `json:"cloud_uuid"`
	Hash             string     `json:"hash"`
	FileSize         int64      `json:"file_size"`
	OriginalFilename string     `json:"original_filename"`
}

func prepareUploadTask(filePath string, overrides *UploadTask) (PreparedTask, error) {
	if filePath == "" {
		return PreparedTask{}, fmt.Errorf("文件路径不能为空")
	}
	info, err := os.Stat(filePath)
	if err != nil {
		return PreparedTask{}, fmt.Errorf("读取文件信息失败: %w", err)
	}
	if info.IsDir() {
		return PreparedTask{}, fmt.Errorf("文件路径指向目录: %s", filePath)
	}

	var (
		itemType  string
		cloudUUID string
		captureAt *time.Time
	)

	if overrides != nil {
		itemType = overrides.ItemType
		cloudUUID = overrides.CloudUUID
		captureAt = overrides.CaptureAt
	}

	if itemType == "" {
		itemType = detectItemType(filePath)
	}
	if itemType != "image" && itemType != "video" {
		return PreparedTask{}, fmt.Errorf("无法识别文件类型: %s", filePath)
	}

	if cloudUUID == "" {
		cloudUUID = uuid.NewString()
	}

	if captureAt == nil {
		modTime := info.ModTime().UTC()
		captureAt = &modTime
	}

	hashValue, err := computeFileHash(filePath)
	if err != nil {
		return PreparedTask{}, err
	}

	return PreparedTask{
		FilePath:         filePath,
		ItemType:         itemType,
		CaptureAt:        captureAt,
		CloudUUID:        cloudUUID,
		Hash:             hashValue,
		FileSize:         info.Size(),
		OriginalFilename: filepath.Base(filePath),
	}, nil
}

func computeFileHash(filePath string) (string, error) {
	// 使用统一的哈希工具类（默认 MD5）
	return hashutil.CalculateFileHashMD5(filePath)
}

func printPreparedTask(task PreparedTask, jsonOutput bool) {
	if jsonOutput {
		data, _ := json.MarshalIndent(task, "", "  ")
		fmt.Println(string(data))
		return
	}
	fmt.Printf("文件: %s\n", task.FilePath)
	fmt.Printf("类型: %s\n", task.ItemType)
	fmt.Printf("大小: %d bytes\n", task.FileSize)
	fmt.Printf("Hash: %s\n", task.Hash)
	fmt.Printf("CloudUUID: %s\n", task.CloudUUID)
	if task.CaptureAt != nil {
		fmt.Printf("拍摄时间: %s\n", task.CaptureAt.Format(time.RFC3339))
	}
}

func printPreparedTasks(tasks []PreparedTask, jsonOutput bool) {
	if jsonOutput {
		data, _ := json.MarshalIndent(tasks, "", "  ")
		fmt.Println(string(data))
		return
	}
	fmt.Printf("共 %d 个文件待上传：\n", len(tasks))
	for _, task := range tasks {
		fmt.Printf("- %s (%s, %d bytes, hash=%s)\n",
			task.FilePath, task.ItemType, task.FileSize, task.Hash)
	}
}

func uploadSingle(ctx context.Context, client *remote.Client, task PreparedTask, quiet, jsonOutput bool) error {
	f, err := os.Open(task.FilePath)
	if err != nil {
		return fmt.Errorf("打开文件失败: %w", err)
	}
	defer f.Close()

	var bar *progressbar.ProgressBar
	reader := io.Reader(f)
	if !quiet {
		bar = progressbar.NewOptions64(task.FileSize,
			progressbar.OptionSetDescription("上传中"),
			progressbar.OptionSetWriter(os.Stderr),
			progressbar.OptionShowBytes(true),
			progressbar.OptionSetWidth(30),
			progressbar.OptionThrottle(100*time.Millisecond),
		)
		reader = io.TeeReader(f, bar)
	}

	resp, err := client.UploadMedia(ctx, &remote.UploadMediaInput{
		Hash:             task.Hash,
		ItemType:         task.ItemType,
		OriginalFilename: task.OriginalFilename,
		CloudUUID:        task.CloudUUID,
		MediaTakenAt:     task.CaptureAt,
		FileSize:         task.FileSize,
		FileName:         task.OriginalFilename,
		File:             reader,
	})
	if bar != nil {
		_ = bar.Finish()
	}
	if err != nil {
		return err
	}

	output := FileUploadResult{
		Success: true,
		Message: resp.Message,
		Media:   resp.Media,
	}

	return output.Print(jsonOutput)
}

// FileUploadResult 单文件上传结果
type FileUploadResult struct {
	Success bool          `json:"success"`
	Message string        `json:"message"`
	Media   *remote.Media `json:"media,omitempty"`
	Error   string        `json:"error,omitempty"`
	File    *PreparedTask `json:"file,omitempty"`
}

func (r FileUploadResult) Print(jsonOutput bool) error {
	if jsonOutput {
		data, err := json.MarshalIndent(r, "", "  ")
		if err != nil {
			return err
		}
		fmt.Println(string(data))
		return nil
	}
	if r.Success {
		fmt.Printf("上传成功: %s\n", r.Message)
		if r.Media != nil {
			fmt.Printf("媒体 UUID: %s\n", r.Media.UUID)
			fmt.Printf("文件名: %s\n", r.Media.Filename)
			fmt.Printf("文件大小: %d\n", r.Media.FileSize)
		}
	} else {
		fmt.Printf("上传失败: %s\n", r.Error)
	}
	return nil
}

type batchUploadResult struct {
	Successes []FileUploadResult `json:"successes"`
	Failures  []FileUploadResult `json:"failures"`
}

func uploadBatch(ctx context.Context, client *remote.Client, tasks []PreparedTask, concurrency int, onError string, quiet, jsonOutput bool) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	var totalBytes int64
	for _, task := range tasks {
		totalBytes += task.FileSize
	}

	jobs := make(chan PreparedTask)
	results := make(chan FileUploadResult)

	var progress *progressbar.ProgressBar
	if !quiet && totalBytes > 0 {
		progress = progressbar.NewOptions64(totalBytes,
			progressbar.OptionSetDescription("批量上传"),
			progressbar.OptionSetWriter(os.Stderr),
			progressbar.OptionSetWidth(30),
			progressbar.OptionSetRenderBlankState(true),
			progressbar.OptionShowBytes(true),
		)
	}

	var wg sync.WaitGroup
	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for task := range jobs {
				select {
				case <-ctx.Done():
					return
				default:
				}

				file, err := os.Open(task.FilePath)
				if err != nil {
					results <- FileUploadResult{
						Success: false,
						Error:   fmt.Sprintf("打开文件失败: %v", err),
						File:    &task,
					}
					continue
				}
				func() {
					defer file.Close()

					reader := io.Reader(file)
					if progress != nil {
						reader = io.TeeReader(file, progress)
					}

					resp, err := client.UploadMedia(ctx, &remote.UploadMediaInput{
						Hash:             task.Hash,
						ItemType:         task.ItemType,
						OriginalFilename: task.OriginalFilename,
						CloudUUID:        task.CloudUUID,
						MediaTakenAt:     task.CaptureAt,
						FileSize:         task.FileSize,
						FileName:         task.OriginalFilename,
						File:             reader,
					})
					if err != nil {
						results <- FileUploadResult{
							Success: false,
							Error:   err.Error(),
							File:    &task,
						}
						return
					}

					results <- FileUploadResult{
						Success: true,
						Message: resp.Message,
						Media:   resp.Media,
						File:    &task,
					}
				}()
			}
		}()
	}

	go func() {
		for _, task := range tasks {
			select {
			case <-ctx.Done():
				close(jobs)
				return
			case jobs <- task:
			}
		}
		close(jobs)
	}()

	go func() {
		wg.Wait()
		close(results)
	}()

	var (
		summary       batchUploadResult
		progressCount int64
	)

	for res := range results {
		if res.Success {
			summary.Successes = append(summary.Successes, res)
		} else {
			summary.Failures = append(summary.Failures, res)
			if onError == "stop" {
				cancel()
			}
		}
		current := atomic.AddInt64(&progressCount, 1)
		if progress != nil {
			progress.Describe(fmt.Sprintf("批量上传 %d/%d", current, len(tasks)))
		}
	}

	if progress != nil {
		_ = progress.Finish()
	}

	if jsonOutput {
		data, err := json.MarshalIndent(summary, "", "  ")
		if err != nil {
			return err
		}
		fmt.Println(string(data))
	} else {
		fmt.Printf("上传完成：成功 %d 个，失败 %d 个\n", len(summary.Successes), len(summary.Failures))
		for _, failure := range summary.Failures {
			if failure.File != nil {
				fmt.Printf("- 失败文件: %s => %s\n", failure.File.FilePath, failure.Error)
			}
		}
	}

	if len(summary.Failures) > 0 {
		return fmt.Errorf("共有 %d 个文件上传失败", len(summary.Failures))
	}
	return nil
}

func authenticateClient(ctx context.Context, client *remote.Client, opts CommonOptions) error {
	if opts.Email == "" || opts.Password == "" {
		return fmt.Errorf("请提供登录邮箱和密码，可通过 --email/--password 或环境变量 ALBUM_CLI_EMAIL / ALBUM_CLI_PASSWORD 设置")
	}
	if err := client.LoginWithPassword(ctx, opts.Email, opts.Password); err != nil {
		return fmt.Errorf("登录失败: %w", err)
	}
	return nil
}
