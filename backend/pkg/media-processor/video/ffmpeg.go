package videoprocessor

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	core "github.com/album/backend/pkg/media-processor/core"
	"github.com/album/backend/pkg/media-processor/internal/utils"
)

// FFmpegProcessor 使用 FFmpeg/FFprobe 实现视频处理。
type FFmpegProcessor struct {
	cfg     *core.Config
	mu      sync.RWMutex
	closed  bool
	workers int
}

// NewFFmpegProcessor 创建视频处理器。
func NewFFmpegProcessor(cfg *core.Config) (VideoProcessor, error) {
	if cfg == nil {
		return nil, core.ErrNilConfig
	}

	if strings.TrimSpace(cfg.FFmpeg.BinaryPath) == "" {
		return nil, core.ErrFFmpegNotConfigured
	}
	if strings.TrimSpace(cfg.FFmpeg.ProbePath) == "" {
		return nil, core.ErrFFprobeNotConfigured
	}

	workers := cfg.FFmpeg.MaxConcurrency
	if workers <= 0 {
		workers = cfg.Concurrency
	}
	if workers <= 0 {
		workers = 1
	}

	return &FFmpegProcessor{
		cfg:     cfg,
		workers: workers,
	}, nil
}

func (p *FFmpegProcessor) Process(ctx context.Context, originalPath string, specs []core.VideoSpec) (*core.ProcessResult, error) {
	if len(specs) == 0 {
		return nil, core.ErrNoVideoSpecsConfigured
	}

	result := &core.ProcessResult{}
	var mu sync.Mutex

	semaphore := make(chan struct{}, p.workers)
	var wg sync.WaitGroup

	for _, spec := range specs {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		wg.Add(1)
		semaphore <- struct{}{}

		spec := spec
		go func() {
			defer wg.Done()
			defer func() { <-semaphore }()

			output, err := p.transcode(ctx, originalPath, spec)

			mu.Lock()
			defer mu.Unlock()

			if err != nil {
				result.Errors = append(result.Errors, core.ProcessError{
					Spec:    spec.Name,
					Message: err.Error(),
					Err:     err,
				})
				return
			}

			result.GeneratedFiles = append(result.GeneratedFiles, output)
		}()
	}

	wg.Wait()

	if metadata, err := p.ExtractMetadata(ctx, originalPath); err == nil {
		result.Metadata = metadata
	}

	return result, nil
}

func (p *FFmpegProcessor) GenerateThumbnail(ctx context.Context, videoPath string, timeOffset float64, spec core.ImageSpec) (string, error) {
	if timeOffset < 0 {
		timeOffset = p.cfg.FFmpeg.ThumbnailOffset
	}
	if timeOffset < 0 {
		timeOffset = 1.0
	}

	var outputPath string
	if strings.Contains(videoPath, "://") {
		// 输入为 URL 时写入临时目录，避免 BuildDerivedPath 产生非法路径
		ext := strings.TrimPrefix(strings.ToLower(spec.Format), ".")
		if ext == "" {
			ext = "jpg"
		}
		outputPath = filepath.Join(os.TempDir(), fmt.Sprintf("video_thumb_%d_%s.%s", time.Now().UnixNano(), spec.Name, ext))
		if err := utils.EnsureDir(outputPath); err != nil {
			return "", err
		}
	} else {
		var err error
		outputPath, err = utils.BuildDerivedPath(videoPath, spec.Name, spec.Format)
		if err != nil {
			return "", err
		}
		if err := utils.EnsureDir(outputPath); err != nil {
			return "", err
		}
	}

	args := []string{
		"-y",
		"-ss", fmt.Sprintf("%.2f", timeOffset),
		"-i", videoPath,
		"-frames:v", "1",
	}

	scaleFilter := buildScaleFilter(spec.MaxWidth, spec.MaxHeight)
	if scaleFilter != "" {
		args = append(args, "-vf", scaleFilter)
	}

	if spec.Quality > 0 {
		args = append(args, "-q:v", strconv.Itoa(clamp(spec.Quality, 1, 31)))
	}

	args = append(args, outputPath)

	if err := p.runFFmpeg(ctx, args...); err != nil {
		return "", err
	}

	return outputPath, nil
}

func (p *FFmpegProcessor) GeneratePreview(ctx context.Context, originalPath string, spec core.VideoSpec) (string, error) {
	return p.transcode(ctx, originalPath, spec)
}

func (p *FFmpegProcessor) ExtractMetadata(ctx context.Context, filePath string) (*core.MediaMetadata, error) {
	data, err := p.runFFprobe(ctx, filePath)
	if err != nil {
		return nil, err
	}

	meta := &core.MediaMetadata{}

	for _, stream := range data.Streams {
		switch stream.CodecType {
		case "video":
			if stream.Width > 0 {
				meta.Width = ptr(stream.Width)
			}
			if stream.Height > 0 {
				meta.Height = ptr(stream.Height)
			}
			if stream.CodecName != "" {
				meta.VideoCodec = ptr(stream.CodecName)
			}
			if stream.AvgFrameRate != "" {
				if frameRate, err := parseFraction(stream.AvgFrameRate); err == nil {
					meta.FrameRate = ptr(frameRate)
				}
			}
			if stream.BitRate != "" {
				if bitrate, err := strconv.ParseInt(stream.BitRate, 10, 64); err == nil {
					meta.BitRate = &bitrate
				}
			}
		case "audio":
			if stream.CodecName != "" {
				meta.AudioCodec = ptr(stream.CodecName)
			}
			if stream.Channels > 0 {
				meta.AudioChannels = ptr(stream.Channels)
			}
			if stream.SampleRate != "" {
				if sampleRate, err := strconv.Atoi(stream.SampleRate); err == nil {
					meta.AudioSampleRate = &sampleRate
				}
			}
		}
	}

	if durStr := data.Format.Duration; durStr != "" {
		if duration, err := strconv.ParseFloat(durStr, 64); err == nil {
			meta.Duration = &duration
		}
	}

	if sizeStr := data.Format.Size; sizeStr != "" {
		if size, err := strconv.ParseInt(sizeStr, 10, 64); err == nil {
			meta.FileSize = &size
		}
	}

	if mime, ext, err := utils.DetectFileFormat(filePath); err == nil {
		meta.MimeType = &mime
		if ext != "" && meta.VideoCodec == nil {
			meta.VideoCodec = ptr(ext)
		}
	}

	return meta, nil
}

func (p *FFmpegProcessor) Close() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.closed {
		return nil
	}

	p.closed = true
	return nil
}

func (p *FFmpegProcessor) transcode(ctx context.Context, input string, spec core.VideoSpec) (string, error) {
	if spec.Name == "" {
		return "", fmt.Errorf("%w: empty name", core.ErrInvalidVideoSpec)
	}

	if spec.Format == "" {
		spec.Format = "mp4"
	}

	outputPath, err := utils.BuildDerivedPath(input, spec.Name, spec.Format)
	if err != nil {
		return "", err
	}
	if err := utils.EnsureDir(outputPath); err != nil {
		return "", err
	}

	args := []string{"-y", "-i", input}
	scaleFilter := buildScaleFilter(spec.MaxWidth, 0)
	if scaleFilter != "" {
		args = append(args, "-vf", scaleFilter)
	}

	crf := clamp(spec.Quality, 0, 51)
	if crf <= 0 {
		crf = 23
	}

	args = append(args,
		"-c:v", "libx264",
		"-preset", "medium",
		"-crf", strconv.Itoa(crf),
		"-c:a", "aac",
		"-movflags", "+faststart",
		outputPath,
	)

	if err := p.runFFmpeg(ctx, args...); err != nil {
		return "", err
	}

	return outputPath, nil
}

func (p *FFmpegProcessor) runFFmpeg(ctx context.Context, args ...string) error {
	ctx, cancel := p.commandContext(ctx)
	defer cancel()

	cmd := exec.CommandContext(ctx, p.cfg.FFmpeg.BinaryPath, args...)

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("ffmpeg: %w (%s)", err, stderr.String())
	}

	return nil
}

func (p *FFmpegProcessor) runFFprobe(ctx context.Context, filePath string) (*ffprobeOutput, error) {
	ctx, cancel := p.commandContext(ctx)
	defer cancel()

	args := []string{
		"-v", "quiet",
		"-print_format", "json",
		"-show_format",
		"-show_streams",
		filePath,
	}

	cmd := exec.CommandContext(ctx, p.cfg.FFmpeg.ProbePath, args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("ffprobe: %w (%s)", err, stderr.String())
	}

	var out ffprobeOutput
	if err := json.Unmarshal(stdout.Bytes(), &out); err != nil {
		return nil, fmt.Errorf("ffprobe parse: %w", err)
	}

	return &out, nil
}

func (p *FFmpegProcessor) commandContext(ctx context.Context) (context.Context, context.CancelFunc) {
	timeout := p.cfg.FFmpeg.ProcessTimeout
	if timeout <= 0 {
		timeout = 10 * time.Minute
	}
	return context.WithTimeout(ctx, timeout)
}

func buildScaleFilter(maxWidth, maxHeight int) string {
	if maxWidth <= 0 && maxHeight <= 0 {
		return ""
	}

	if maxWidth > 0 && maxHeight > 0 {
		return fmt.Sprintf("scale=%d:%d:force_original_aspect_ratio=decrease", maxWidth, maxHeight)
	}

	if maxWidth > 0 {
		return fmt.Sprintf("scale=%d:-2:force_original_aspect_ratio=decrease", maxWidth)
	}

	return fmt.Sprintf("scale=-2:%d:force_original_aspect_ratio=decrease", maxHeight)
}

func clamp(value, min, max int) int {
	if value < min {
		return min
	}
	if value > max {
		return max
	}
	return value
}

func parseFraction(value string) (float64, error) {
	parts := strings.Split(value, "/")
	if len(parts) != 2 {
		return strconv.ParseFloat(value, 64)
	}
	num, err := strconv.ParseFloat(parts[0], 64)
	if err != nil {
		return 0, err
	}
	den, err := strconv.ParseFloat(parts[1], 64)
	if err != nil {
		return 0, err
	}
	if den == 0 {
		return 0, fmt.Errorf("division by zero")
	}
	return num / den, nil
}

type ffprobeOutput struct {
	Streams []ffprobeStream `json:"streams"`
	Format  ffprobeFormat   `json:"format"`
}

type ffprobeStream struct {
	CodecName    string `json:"codec_name"`
	CodecType    string `json:"codec_type"`
	Width        int    `json:"width"`
	Height       int    `json:"height"`
	Channels     int    `json:"channels"`
	SampleRate   string `json:"sample_rate"`
	BitRate      string `json:"bit_rate"`
	AvgFrameRate string `json:"avg_frame_rate"`
}

type ffprobeFormat struct {
	Filename string `json:"filename"`
	Duration string `json:"duration"`
	Size     string `json:"size"`
}

func ptr[T any](v T) *T {
	return &v
}
