package core

import "errors"

var (
	ErrNilConfig              = errors.New("media-processor: config must not be nil")
	ErrInvalidImageSpec       = errors.New("media-processor: invalid image spec")
	ErrInvalidVideoSpec       = errors.New("media-processor: invalid video spec")
	ErrNoImageSpecsConfigured = errors.New("media-processor: no image specs configured")
	ErrNoVideoSpecsConfigured = errors.New("media-processor: no video specs configured")
	ErrImagickNotInitialized  = errors.New("media-processor: imagick not initialized")
	ErrImagickClosed          = errors.New("media-processor: imagick manager already closed")
	ErrImagickInUse           = errors.New("media-processor: imagick resources still in use")
	ErrNotRAWFile             = errors.New("media-processor: file is not a supported RAW format")
	ErrFFmpegNotConfigured    = errors.New("media-processor: ffmpeg binary not configured")
	ErrFFprobeNotConfigured   = errors.New("media-processor: ffprobe binary not configured")
	ErrUnsupportedFormat      = errors.New("media-processor: unsupported format")
)
