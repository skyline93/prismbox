package videoprocessor

import (
	"context"

	core "github.com/album/backend/pkg/media-processor/core"
)

// VideoProcessor 定义视频处理器行为。
type VideoProcessor interface {
	Process(ctx context.Context, originalPath string, specs []core.VideoSpec) (*core.ProcessResult, error)
	GenerateThumbnail(ctx context.Context, videoPath string, timeOffset float64, spec core.ImageSpec) (string, error)
	GeneratePreview(ctx context.Context, originalPath string, spec core.VideoSpec) (string, error)
	ExtractMetadata(ctx context.Context, filePath string) (*core.MediaMetadata, error)
	Close() error
}
