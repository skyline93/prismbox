package mediaprocessor

import core "github.com/album/backend/pkg/media-processor/core"

var (
	ErrNilConfig              = core.ErrNilConfig
	ErrInvalidImageSpec       = core.ErrInvalidImageSpec
	ErrInvalidVideoSpec       = core.ErrInvalidVideoSpec
	ErrNoImageSpecsConfigured = core.ErrNoImageSpecsConfigured
	ErrNoVideoSpecsConfigured = core.ErrNoVideoSpecsConfigured
	ErrImagickNotInitialized  = core.ErrImagickNotInitialized
	ErrImagickClosed          = core.ErrImagickClosed
	ErrImagickInUse           = core.ErrImagickInUse
	ErrNotRAWFile             = core.ErrNotRAWFile
	ErrFFmpegNotConfigured    = core.ErrFFmpegNotConfigured
	ErrFFprobeNotConfigured   = core.ErrFFprobeNotConfigured
	ErrUnsupportedFormat      = core.ErrUnsupportedFormat
)
