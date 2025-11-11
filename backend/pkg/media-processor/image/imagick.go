package imageprocessor

import (
	"context"
	"fmt"
	"math"
	"sync"

	"gopkg.in/gographics/imagick.v3/imagick"

	core "github.com/album/backend/pkg/media-processor/core"
	pool "github.com/album/backend/pkg/media-processor/internal/pool"
	"github.com/album/backend/pkg/media-processor/internal/utils"
)

// ImagickProcessor 使用 ImageMagick 实现图片处理。
type ImagickProcessor struct {
	manager *ImagickManager
	pool    *pool.ImagickPool
	cfg     *core.Config
	mu      sync.RWMutex
	closed  bool
}

// NewImagickProcessor 创建 ImageMagick 图片处理器。
func NewImagickProcessor(cfg *core.Config) (ImageProcessor, error) {
	if cfg == nil {
		return nil, core.ErrNilConfig
	}

	manager := GetManager()
	if err := manager.Initialize(); err != nil {
		return nil, err
	}

	poolSize := cfg.Imagick.PoolSize
	if poolSize <= 0 {
		poolSize = 4
	}

	pool := pool.NewImagickPool(poolSize)

	return &ImagickProcessor{
		manager: manager,
		pool:    pool,
		cfg:     cfg,
	}, nil
}

func (p *ImagickProcessor) Process(ctx context.Context, originalPath string, specs []core.ImageSpec) (*core.ProcessResult, error) {
	if err := ValidateImageSpecs(specs); err != nil {
		return nil, err
	}

	if p.IsRAW(originalPath) {
		return p.ProcessRAW(ctx, originalPath, specs)
	}

	result := &core.ProcessResult{}
	var mu sync.Mutex

	concurrency := p.cfg.Concurrency
	if concurrency <= 0 {
		concurrency = 1
	}
	semaphore := make(chan struct{}, concurrency)
	var wg sync.WaitGroup

	for _, spec := range specs {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		wg.Add(1)
		semaphore <- struct{}{}

		spec := spec
		go func() {
			defer wg.Done()
			defer func() { <-semaphore }()

			output, err := p.generate(ctx, originalPath, spec)

			mu.Lock()
			defer mu.Unlock()

			if err != nil {
				result.Errors = append(result.Errors, core.ProcessError{
					Spec:    spec.Name,
					Message: err.Error(),
					Err:     err,
				})
				return
			}

			result.GeneratedFiles = append(result.GeneratedFiles, output)
		}()
	}

	wg.Wait()

	if metadata, err := p.ExtractMetadata(ctx, originalPath); err == nil {
		result.Metadata = metadata
	}

	return result, nil
}

func (p *ImagickProcessor) GenerateThumbnail(ctx context.Context, originalPath string, spec core.ImageSpec) (string, error) {
	if !spec.Crop {
		spec.Crop = true
	}
	return p.generate(ctx, originalPath, spec)
}

func (p *ImagickProcessor) GeneratePreview(ctx context.Context, originalPath string, spec core.ImageSpec) (string, error) {
	spec.Crop = false
	return p.generate(ctx, originalPath, spec)
}

func (p *ImagickProcessor) generate(ctx context.Context, originalPath string, spec core.ImageSpec) (string, error) {
	if err := ValidateImageSpec(spec); err != nil {
		return "", err
	}

	if err := p.manager.Acquire(); err != nil {
		return "", err
	}
	defer p.manager.Release()

	// 获取 MagickWand
	wand, err := p.pool.Get(ctx)
	if err != nil {
		return "", err
	}
	defer p.pool.Put(wand)

	wand.Clear()

	if err := wand.ReadImage(originalPath); err != nil {
		return "", fmt.Errorf("read image: %w", err)
	}

	if err := p.applySpec(wand, spec); err != nil {
		return "", err
	}

	outputPath, err := utils.BuildDerivedPath(originalPath, spec.Name, spec.Format)
	if err != nil {
		return "", err
	}
	if err := utils.EnsureDir(outputPath); err != nil {
		return "", err
	}

	if err := wand.WriteImage(outputPath); err != nil {
		return "", fmt.Errorf("write image: %w", err)
	}

	return outputPath, nil
}

func (p *ImagickProcessor) applySpec(wand *imagick.MagickWand, spec core.ImageSpec) error {
	width := wand.GetImageWidth()
	height := wand.GetImageHeight()

	targetWidth := uint(spec.MaxWidth)
	targetHeight := uint(spec.MaxHeight)

	if targetWidth == 0 && targetHeight == 0 {
		targetWidth = width
		targetHeight = height
	}

	if spec.Crop {
		if targetWidth == 0 {
			targetWidth = width
		}
		if targetHeight == 0 {
			targetHeight = height
		}
		if err := resizeToCover(wand, targetWidth, targetHeight); err != nil {
			return err
		}

		offsetX := int((wand.GetImageWidth() - targetWidth) / 2)
		offsetY := int((wand.GetImageHeight() - targetHeight) / 2)
		if err := wand.CropImage(targetWidth, targetHeight, offsetX, offsetY); err != nil {
			return fmt.Errorf("crop image: %w", err)
		}
	} else {
		if err := resizeToFit(wand, targetWidth, targetHeight); err != nil {
			return err
		}
	}

	if spec.Format != "" {
		if err := wand.SetImageFormat(spec.Format); err != nil {
			return fmt.Errorf("set format: %w", err)
		}
	}

	if err := wand.SetCompressionQuality(uint(spec.Quality)); err != nil {
		return fmt.Errorf("set compression quality: %w", err)
	}

	return nil
}

func resizeToCover(wand *imagick.MagickWand, targetWidth, targetHeight uint) error {
	sourceWidth := wand.GetImageWidth()
	sourceHeight := wand.GetImageHeight()

	scale := math.Max(
		float64(targetWidth)/float64(sourceWidth),
		float64(targetHeight)/float64(sourceHeight),
	)

	newWidth := uint(float64(sourceWidth) * scale)
	newHeight := uint(float64(sourceHeight) * scale)

	if err := wand.ResizeImage(newWidth, newHeight, imagick.FILTER_LANCZOS); err != nil {
		return fmt.Errorf("resize image: %w", err)
	}
	return nil
}

func resizeToFit(wand *imagick.MagickWand, maxWidth, maxHeight uint) error {
	currentWidth := float64(wand.GetImageWidth())
	currentHeight := float64(wand.GetImageHeight())

	scale := 1.0

	if maxWidth > 0 && currentWidth > float64(maxWidth) {
		scale = math.Min(scale, float64(maxWidth)/currentWidth)
	}
	if maxHeight > 0 && currentHeight > float64(maxHeight) {
		scale = math.Min(scale, float64(maxHeight)/currentHeight)
	}

	if scale >= 1.0 {
		return nil
	}

	newWidth := uint(math.Max(1, math.Round(currentWidth*scale)))
	newHeight := uint(math.Max(1, math.Round(currentHeight*scale)))

	if err := wand.ResizeImage(newWidth, newHeight, imagick.FILTER_LANCZOS); err != nil {
		return fmt.Errorf("resize image: %w", err)
	}
	return nil
}

func (p *ImagickProcessor) ExtractMetadata(ctx context.Context, filePath string) (*core.MediaMetadata, error) {
	if err := p.manager.Acquire(); err != nil {
		return nil, err
	}
	defer p.manager.Release()

	wand, err := p.pool.Get(ctx)
	if err != nil {
		return nil, err
	}
	defer p.pool.Put(wand)

	wand.Clear()
	if err := wand.ReadImage(filePath); err != nil {
		return nil, fmt.Errorf("read image for metadata: %w", err)
	}

	meta := extractMetadataFromWand(wand)

	if size, err := utils.FileSize(filePath); err == nil {
		meta.FileSize = &size
	}

	if mime, _, err := utils.DetectFileFormat(filePath); err == nil {
		meta.MimeType = &mime
	}

	return meta, nil
}

func (p *ImagickProcessor) Close() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.closed {
		return nil
	}

	p.pool.Close()

	if err := p.manager.Close(); err != nil && err != core.ErrImagickInUse {
		return err
	}

	p.closed = true
	return nil
}

func intMax(a, b int) int {
	if a > b {
		return a
	}
	return b
}
