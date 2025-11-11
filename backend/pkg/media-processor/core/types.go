package core

import "time"

// ImageSpec 图片规格配置
type ImageSpec struct {
	Name      string `json:"name"`
	MaxWidth  int    `json:"max_width"`
	MaxHeight int    `json:"max_height"`
	Quality   int    `json:"quality"`
	Format    string `json:"format"`
	Crop      bool   `json:"crop"`
}

// VideoSpec 视频规格配置
type VideoSpec struct {
	Name     string `json:"name"`
	MaxWidth int    `json:"max_width"`
	Quality  int    `json:"quality"`
	Format   string `json:"format"`
}

// MediaMetadata 媒体元数据信息
type MediaMetadata struct {
	Width    *int    `json:"width,omitempty"`
	Height   *int    `json:"height,omitempty"`
	FileSize *int64  `json:"file_size,omitempty"`
	MimeType *string `json:"mime_type,omitempty"`

	MediaTakenAt *time.Time `json:"media_taken_at,omitempty"`
	CameraMake   *string    `json:"camera_make,omitempty"`
	CameraModel  *string    `json:"camera_model,omitempty"`
	Latitude     *float64   `json:"latitude,omitempty"`
	Longitude    *float64   `json:"longitude,omitempty"`

	Duration        *float64 `json:"duration,omitempty"`
	VideoCodec      *string  `json:"video_codec,omitempty"`
	AudioCodec      *string  `json:"audio_codec,omitempty"`
	FrameRate       *float64 `json:"frame_rate,omitempty"`
	BitRate         *int64   `json:"bit_rate,omitempty"`
	AudioChannels   *int     `json:"audio_channels,omitempty"`
	AudioSampleRate *int     `json:"audio_sample_rate,omitempty"`
}

// ProcessResult 表示处理过程的结果。
type ProcessResult struct {
	GeneratedFiles []string       `json:"generated_files"`
	Metadata       *MediaMetadata `json:"metadata,omitempty"`
	Errors         []ProcessError `json:"errors,omitempty"`
}

// ProcessError 记录单个规格处理失败的错误信息。
type ProcessError struct {
	Spec    string `json:"spec"`
	Message string `json:"message"`
	Err     error  `json:"-"`
}
