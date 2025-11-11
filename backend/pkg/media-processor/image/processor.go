package imageprocessor

import (
	"context"

	core "github.com/album/backend/pkg/media-processor/core"
)

// ImageProcessor 定义图片处理器行为。
type ImageProcessor interface {
	Process(ctx context.Context, originalPath string, specs []core.ImageSpec) (*core.ProcessResult, error)
	GenerateThumbnail(ctx context.Context, originalPath string, spec core.ImageSpec) (string, error)
	GeneratePreview(ctx context.Context, originalPath string, spec core.ImageSpec) (string, error)
	ExtractMetadata(ctx context.Context, filePath string) (*core.MediaMetadata, error)
	IsRAW(filePath string) bool
	ProcessRAW(ctx context.Context, rawPath string, specs []core.ImageSpec) (*core.ProcessResult, error)
	Close() error
}
