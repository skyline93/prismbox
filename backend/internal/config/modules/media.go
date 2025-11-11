package modules

import (
	"fmt"
	"time"
)

// MediaConfig 媒体配置
type MediaConfig struct {
	MaxFileSize Size                  `yaml:"max_file_size"` // 支持 "100MB", "1GB" 等格式
	Processor   *MediaProcessorConfig `yaml:"processor"`
}

// Validate 验证媒体配置
func (c *MediaConfig) Validate() error {
	if c == nil {
		return nil
	}
	if c.Processor != nil {
		return c.Processor.Validate()
	}
	return nil
}

// MediaProcessorConfig 媒体处理器配置。
type MediaProcessorConfig struct {
	Concurrency       int                    `yaml:"concurrency"`
	DefaultImageSpecs []MediaImageSpecConfig `yaml:"default_image_specs"`
	DefaultVideoSpecs []MediaVideoSpecConfig `yaml:"default_video_specs"`
	Imagick           *MediaImagickConfig    `yaml:"imagick"`
	FFmpeg            *MediaFFmpegConfig     `yaml:"ffmpeg"`
}

// Validate 校验处理器配置。
func (c *MediaProcessorConfig) Validate() error {
	if c == nil {
		return nil
	}
	if c.Imagick != nil {
		if err := c.Imagick.Validate(); err != nil {
			return err
		}
	}
	if c.FFmpeg != nil {
		if err := c.FFmpeg.Validate(); err != nil {
			return err
		}
	}
	return nil
}

// MediaImageSpecConfig 图片规格配置。
type MediaImageSpecConfig struct {
	Name      string `yaml:"name"`
	MaxWidth  int    `yaml:"max_width"`
	MaxHeight int    `yaml:"max_height"`
	Quality   int    `yaml:"quality"`
	Format    string `yaml:"format"`
	Crop      bool   `yaml:"crop"`
}

// MediaVideoSpecConfig 视频规格配置。
type MediaVideoSpecConfig struct {
	Name     string `yaml:"name"`
	MaxWidth int    `yaml:"max_width"`
	Quality  int    `yaml:"quality"`
	Format   string `yaml:"format"`
}

// MediaImagickConfig ImageMagick 配置。
type MediaImagickConfig struct {
	PoolSize    int             `yaml:"pool_size"`
	MemoryLimit string          `yaml:"memory_limit"`
	DiskLimit   string          `yaml:"disk_limit"`
	RAW         *MediaRAWConfig `yaml:"raw"`
}

// Validate 校验 Imagick 配置。
func (c *MediaImagickConfig) Validate() error {
	if c == nil {
		return nil
	}
	if c.PoolSize < 0 {
		return fmt.Errorf("imagick.pool_size must be >= 0")
	}
	if c.RAW != nil {
		return c.RAW.Validate()
	}
	return nil
}

// MediaRAWConfig RAW 图片处理配置。
type MediaRAWConfig struct {
	Quality          int           `yaml:"quality"`
	Format           string        `yaml:"format"`
	MaxRetries       int           `yaml:"max_retries"`
	RetryDelay       time.Duration `yaml:"retry_delay"`
	SupportedFormats []string      `yaml:"supported_formats"`
}

// Validate 校验 RAW 配置。
func (c *MediaRAWConfig) Validate() error {
	if c == nil {
		return nil
	}
	if c.MaxRetries < 0 {
		return fmt.Errorf("imagick.raw.max_retries must be >= 0")
	}
	if c.Quality < 0 || c.Quality > 100 {
		return fmt.Errorf("imagick.raw.quality must be between 0 and 100")
	}
	return nil
}

// MediaFFmpegConfig FFmpeg 配置。
type MediaFFmpegConfig struct {
	BinaryPath      string        `yaml:"binary_path"`
	ProbePath       string        `yaml:"probe_path"`
	MaxConcurrency  int           `yaml:"max_concurrency"`
	ProcessTimeout  time.Duration `yaml:"process_timeout"`
	ThumbnailOffset float64       `yaml:"thumbnail_offset"`
}

// Validate 校验 FFmpeg 配置。
func (c *MediaFFmpegConfig) Validate() error {
	if c == nil {
		return nil
	}
	if c.MaxConcurrency < 0 {
		return fmt.Errorf("ffmpeg.max_concurrency must be >= 0")
	}
	if c.ProcessTimeout < 0 {
		return fmt.Errorf("ffmpeg.process_timeout must be >= 0")
	}
	return nil
}
