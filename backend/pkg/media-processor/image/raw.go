package imageprocessor

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	core "github.com/album/backend/pkg/media-processor/core"
	"github.com/album/backend/pkg/media-processor/internal/utils"
)

// ProcessRAW 针对 RAW 图片的专门处理逻辑。
func (p *ImagickProcessor) ProcessRAW(ctx context.Context, rawPath string, specs []core.ImageSpec) (*core.ProcessResult, error) {
	if !p.IsRAW(rawPath) {
		return nil, core.ErrNotRAWFile
	}

	if err := ValidateImageSpecs(specs); err != nil {
		return nil, err
	}

	result := &core.ProcessResult{}
	var mu sync.Mutex

	for _, spec := range specs {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		output, err := p.processRawSpec(ctx, rawPath, spec)
		mu.Lock()
		if err != nil {
			result.Errors = append(result.Errors, core.ProcessError{
				Spec:    spec.Name,
				Message: err.Error(),
				Err:     err,
			})
		} else {
			result.GeneratedFiles = append(result.GeneratedFiles, output)
		}
		mu.Unlock()
	}

	if metadata, err := p.ExtractMetadata(ctx, rawPath); err == nil {
		result.Metadata = metadata
	}

	return result, nil
}

func (p *ImagickProcessor) processRawSpec(ctx context.Context, rawPath string, spec core.ImageSpec) (string, error) {
	if err := p.manager.Acquire(); err != nil {
		return "", err
	}
	defer p.manager.Release()

	wand, err := p.pool.Get(ctx)
	if err != nil {
		return "", err
	}
	defer p.pool.Put(wand)

	wand.Clear()

	retries := intMax(1, p.cfg.Imagick.RAW.MaxRetries)
	delay := p.cfg.Imagick.RAW.RetryDelay
	if delay <= 0 {
		delay = time.Second
	}

	var readErr error
	for i := 0; i < retries; i++ {
		readErr = wand.ReadImage(rawPath)
		if readErr == nil {
			break
		}

		select {
		case <-ctx.Done():
			return "", ctx.Err()
		case <-time.After(delay):
		}
	}

	if readErr != nil {
		return "", fmt.Errorf("read RAW image: %w", readErr)
	}

	if spec.Format == "" {
		spec.Format = p.cfg.Imagick.RAW.Format
	}
	if spec.Quality == 0 {
		spec.Quality = p.cfg.Imagick.RAW.Quality
	}

	if err := p.applySpec(wand, spec); err != nil {
		return "", err
	}

	outputPath, err := utils.BuildDerivedPath(rawPath, spec.Name, spec.Format)
	if err != nil {
		return "", err
	}
	if err := utils.EnsureDir(outputPath); err != nil {
		return "", err
	}
	if err := wand.WriteImage(outputPath); err != nil {
		return "", fmt.Errorf("write RAW output: %w", err)
	}

	return outputPath, nil
}

// IsRAW 判断文件是否为 RAW 格式。
func (p *ImagickProcessor) IsRAW(filePath string) bool {
	ext := utils.NormalizeExt(filePath)
	for _, format := range p.cfg.Imagick.RAW.SupportedFormats {
		if ext == strings.ToLower(format) {
			return true
		}
	}
	return false
}
