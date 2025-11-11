package mediaprocessor

import core "github.com/album/backend/pkg/media-processor/core"

type (
	Config        = core.Config
	ImagickConfig = core.ImagickConfig
	RAWConfig     = core.RAWConfig
	FFmpegConfig  = core.FFmpegConfig
)

func DefaultConfig() *Config {
	return core.DefaultConfig()
}
