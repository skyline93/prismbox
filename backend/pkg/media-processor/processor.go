package mediaprocessor

import (
	"context"
	"sync"

	imageprocessor "github.com/album/backend/pkg/media-processor/image"
	videoprocessor "github.com/album/backend/pkg/media-processor/video"
)

// MediaProcessor 媒体处理器工厂接口。
type MediaProcessor interface {
	ProcessImage(ctx context.Context, originalPath string, specs []ImageSpec) (*ProcessResult, error)
	ProcessVideo(ctx context.Context, originalPath string, specs []VideoSpec) (*ProcessResult, error)
	GenerateThumbnail(ctx context.Context, originalPath string, spec ImageSpec) (string, error)
	GeneratePreview(ctx context.Context, originalPath string, spec ImageSpec) (string, error)
	ExtractImageMetadata(ctx context.Context, filePath string) (*MediaMetadata, error)
	ExtractVideoMetadata(ctx context.Context, filePath string) (*MediaMetadata, error)
	Close() error
}

// processor 为默认的 MediaProcessor 实现。
type processor struct {
	cfg            *Config
	imageProcessor imageprocessor.ImageProcessor
	videoProcessor videoprocessor.VideoProcessor
	mu             sync.Mutex
	closed         bool
}

// NewProcessor 根据配置创建媒体处理器。
func NewProcessor(cfg *Config) (MediaProcessor, error) {
	if cfg == nil {
		return nil, ErrNilConfig
	}

	imgProc, err := imageprocessor.NewImagickProcessor(cfg)
	if err != nil {
		return nil, err
	}

	videoProc, err := videoprocessor.NewFFmpegProcessor(cfg)
	if err != nil {
		return nil, err
	}

	return &processor{
		cfg:            cfg,
		imageProcessor: imgProc,
		videoProcessor: videoProc,
	}, nil
}

func (p *processor) defaultImageSpecs() ([]ImageSpec, error) {
	if len(p.cfg.DefaultImageSpecs) == 0 {
		return nil, ErrNoImageSpecsConfigured
	}
	return p.cfg.DefaultImageSpecs, nil
}

func (p *processor) defaultVideoSpecs() ([]VideoSpec, error) {
	if len(p.cfg.DefaultVideoSpecs) == 0 {
		return nil, ErrNoVideoSpecsConfigured
	}
	return p.cfg.DefaultVideoSpecs, nil
}

func (p *processor) ProcessImage(ctx context.Context, originalPath string, specs []ImageSpec) (*ProcessResult, error) {
	if specs == nil {
		var err error
		specs, err = p.defaultImageSpecs()
		if err != nil {
			return nil, err
		}
	}
	return p.imageProcessor.Process(ctx, originalPath, specs)
}

func (p *processor) ProcessVideo(ctx context.Context, originalPath string, specs []VideoSpec) (*ProcessResult, error) {
	if specs == nil {
		var err error
		specs, err = p.defaultVideoSpecs()
		if err != nil {
			return nil, err
		}
	}
	return p.videoProcessor.Process(ctx, originalPath, specs)
}

func (p *processor) GenerateThumbnail(ctx context.Context, originalPath string, spec ImageSpec) (string, error) {
	return p.imageProcessor.GenerateThumbnail(ctx, originalPath, spec)
}

func (p *processor) GeneratePreview(ctx context.Context, originalPath string, spec ImageSpec) (string, error) {
	return p.imageProcessor.GeneratePreview(ctx, originalPath, spec)
}

func (p *processor) ExtractImageMetadata(ctx context.Context, filePath string) (*MediaMetadata, error) {
	return p.imageProcessor.ExtractMetadata(ctx, filePath)
}

func (p *processor) ExtractVideoMetadata(ctx context.Context, filePath string) (*MediaMetadata, error) {
	return p.videoProcessor.ExtractMetadata(ctx, filePath)
}

func (p *processor) Close() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.closed {
		return nil
	}

	if err := p.imageProcessor.Close(); err != nil {
		return err
	}
	if err := p.videoProcessor.Close(); err != nil {
		return err
	}

	p.closed = true
	return nil
}
