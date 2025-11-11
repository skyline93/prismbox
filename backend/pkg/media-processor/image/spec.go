package imageprocessor

import (
	"fmt"
	"strings"

	core "github.com/album/backend/pkg/media-processor/core"
)

// ValidateImageSpec 校验单个图片规格。
func ValidateImageSpec(spec core.ImageSpec) error {
	if spec.Name == "" {
		return fmt.Errorf("%w: name empty", core.ErrInvalidImageSpec)
	}
	if spec.MaxWidth < 0 || spec.MaxHeight < 0 {
		return fmt.Errorf("%w: invalid dimension", core.ErrInvalidImageSpec)
	}
	if spec.Quality < 1 || spec.Quality > 100 {
		return fmt.Errorf("%w: invalid quality", core.ErrInvalidImageSpec)
	}
	if spec.Format == "" {
		return fmt.Errorf("%w: format empty", core.ErrInvalidImageSpec)
	}
	return nil
}

// ValidateImageSpecs 校验图片规格列表。
func ValidateImageSpecs(specs []core.ImageSpec) error {
	if len(specs) == 0 {
		return core.ErrNoImageSpecsConfigured
	}
	seen := make(map[string]struct{}, len(specs))
	for _, spec := range specs {
		if err := ValidateImageSpec(spec); err != nil {
			return err
		}
		key := strings.ToLower(spec.Name)
		if _, ok := seen[key]; ok {
			return fmt.Errorf("%w: duplicated spec %s", core.ErrInvalidImageSpec, spec.Name)
		}
		seen[key] = struct{}{}
	}
	return nil
}
