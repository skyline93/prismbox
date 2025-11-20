package core

import "time"

// Config 为媒体处理模块的总体配置。
type Config struct {
	DefaultImageSpecs []ImageSpec
	DefaultVideoSpecs []VideoSpec

	Concurrency int

	Imagick ImagickConfig
	FFmpeg  FFmpegConfig
}

// ImagickConfig 控制 ImageMagick 相关参数。
type ImagickConfig struct {
	PoolSize    int
	MemoryLimit string
	DiskLimit   string
	RAW         RAWConfig
}

// RAWConfig 控制 RAW 图片处理的行为。
type RAWConfig struct {
	Quality          int
	Format           string
	MaxRetries       int
	RetryDelay       time.Duration
	SupportedFormats []string
}

// FFmpegConfig 控制 FFmpeg 的调用。
type FFmpegConfig struct {
	BinaryPath      string
	ProbePath       string
	MaxConcurrency  int
	ProcessTimeout  time.Duration
	ThumbnailOffset float64
}

// DefaultConfig 构造一个默认配置。
func DefaultConfig() *Config {
	return &Config{
		DefaultImageSpecs: []ImageSpec{
			{
				Name:      "thumbnail",
				MaxWidth:  400,
				MaxHeight: 400,
				Quality:   75,
				Format:    "jpg",
				Crop:      true,
			},
			{
				Name:      "preview",
				MaxWidth:  1280,
				MaxHeight: 0,
				Quality:   80,
				Format:    "jpg",
				Crop:      false,
			},
			{
				Name:      "small",
				MaxWidth:  640,
				MaxHeight: 0,
				Quality:   85,
				Format:    "jpg",
				Crop:      false,
			},
			{
				Name:      "medium",
				MaxWidth:  1920,
				MaxHeight: 0,
				Quality:   90,
				Format:    "jpg",
				Crop:      false,
			},
		},
		DefaultVideoSpecs: []VideoSpec{
			{
				Name:     "preview",
				MaxWidth: 1280,
				Quality:  23,
				Format:   "mp4",
			},
		},
		Concurrency: 1,
		Imagick: ImagickConfig{
			PoolSize:    1,
			MemoryLimit: "512MB",
			DiskLimit:   "1GB",
			RAW: RAWConfig{
				Quality:          90,
				Format:           "jpg",
				MaxRetries:       3,
				RetryDelay:       5 * time.Second,
				SupportedFormats: []string{"CR2", "NEF", "ARW", "ORF", "RW2"},
			},
		},
		FFmpeg: FFmpegConfig{
			BinaryPath:      "/usr/bin/ffmpeg",
			ProbePath:       "/usr/bin/ffprobe",
			MaxConcurrency:  1,
			ProcessTimeout:  10 * time.Minute,
			ThumbnailOffset: 1.5,
		},
	}
}
