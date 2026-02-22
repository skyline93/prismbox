package core

import "time"

// ImageTierConfig 单档位媒体尺寸配置（长边限制，不裁剪，保持比例）。
type ImageTierConfig struct {
	Size    int    `json:"size" yaml:"size" mapstructure:"size"`
	Format  string `json:"format" yaml:"format" mapstructure:"format"`
	Quality int    `json:"quality" yaml:"quality" mapstructure:"quality"`
}

// Config 为媒体处理模块的总体配置。
type Config struct {
	// Thumbnail / Preview 为缩略图、预览图单处配置，会合并进 DefaultImageSpecs 的对应档位。
	Thumbnail *ImageTierConfig `json:"thumbnail" yaml:"thumbnail" mapstructure:"thumbnail"`
	Preview   *ImageTierConfig `json:"preview" yaml:"preview" mapstructure:"preview"`

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
// 缩略图/预览图采用长边限制、不裁剪，与 Immich 行为对齐。
func DefaultConfig() *Config {
	thumbSize := 250
	previewSize := 1440
	return &Config{
		Thumbnail: &ImageTierConfig{Size: thumbSize, Format: "jpg", Quality: 80},
		Preview:   &ImageTierConfig{Size: previewSize, Format: "jpg", Quality: 80},
		DefaultImageSpecs: []ImageSpec{
			{
				Name:      "thumbnail",
				MaxWidth:  thumbSize,
				MaxHeight: 0,
				Quality:   80,
				Format:    "jpg",
				Crop:      false,
			},
			{
				Name:      "preview",
				MaxWidth:  previewSize,
				MaxHeight: 0,
				Quality:   80,
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

// EnsureTierSpecs 将 Thumbnail/Preview 配置合并进 DefaultImageSpecs（替换或追加 thumbnail/preview 档位）。
// 在 NewProcessor 前调用，保证 YAML 中的 media.thumbnail / media.preview 生效。
func (c *Config) EnsureTierSpecs() {
	if c == nil {
		return
	}
	replaceOrAppend := func(name string, tier *ImageTierConfig) {
		if tier == nil || tier.Size <= 0 {
			return
		}
		spec := ImageSpec{
			Name:      name,
			MaxWidth:  tier.Size,
			MaxHeight: 0,
			Quality:   tier.Quality,
			Format:    tier.Format,
			Crop:      false,
		}
		if tier.Quality <= 0 {
			spec.Quality = 80
		}
		if spec.Format == "" {
			spec.Format = "jpg"
		}
		for i := range c.DefaultImageSpecs {
			if c.DefaultImageSpecs[i].Name == name {
				c.DefaultImageSpecs[i] = spec
				return
			}
		}
		c.DefaultImageSpecs = append(c.DefaultImageSpecs, spec)
	}
	replaceOrAppend("thumbnail", c.Thumbnail)
	replaceOrAppend("preview", c.Preview)
}

// EnsureTierSpecs 为包外调用入口，将 Thumbnail/Preview 合并进 DefaultImageSpecs。
func EnsureTierSpecs(c *Config) {
	if c != nil {
		c.EnsureTierSpecs()
	}
}
