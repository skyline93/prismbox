package imageprocessor

import (
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"gopkg.in/gographics/imagick.v3/imagick"

	core "github.com/album/backend/pkg/media-processor/core"
)

func extractMetadataFromWand(wand *imagick.MagickWand) *core.MediaMetadata {
	meta := &core.MediaMetadata{}

	width := int(wand.GetImageWidth())
	height := int(wand.GetImageHeight())
	meta.Width = &width
	meta.Height = &height

	if err := populateEXIF(wand, meta); err != nil {
		// 容错：忽略错误，仅记录日志的职责留给上层调用方
	}

	return meta
}

func populateEXIF(wand *imagick.MagickWand, meta *core.MediaMetadata) error {
	if wand == nil || meta == nil {
		return fmt.Errorf("invalid parameters")
	}

	if makeVal := wand.GetImageProperty("exif:Make"); makeVal != "" {
		meta.CameraMake = ptr(makeVal)
	}

	if model := wand.GetImageProperty("exif:Model"); model != "" {
		meta.CameraModel = ptr(model)
	}

	if taken := wand.GetImageProperty("exif:DateTimeOriginal"); taken != "" {
		if t, err := parseEXIFDate(taken); err == nil {
			meta.MediaTakenAt = &t
		}
	}

	if latStr := wand.GetImageProperty("exif:GPSLatitude"); latStr != "" {
		if lat, err := parseGPS(latStr, wand.GetImageProperty("exif:GPSLatitudeRef")); err == nil {
			meta.Latitude = &lat
		}
	}

	if lonStr := wand.GetImageProperty("exif:GPSLongitude"); lonStr != "" {
		if lon, err := parseGPS(lonStr, wand.GetImageProperty("exif:GPSLongitudeRef")); err == nil {
			meta.Longitude = &lon
		}
	}

	return nil
}

func parseEXIFDate(value string) (time.Time, error) {
	layouts := []string{
		"2006:01:02 15:04:05",
		time.RFC3339,
	}
	for _, layout := range layouts {
		if t, err := time.Parse(layout, value); err == nil {
			return t, nil
		}
	}
	return time.Time{}, fmt.Errorf("unsupported exif date: %s", value)
}

func parseGPS(value string, ref string) (float64, error) {
	parts := strings.Split(value, ",")
	if len(parts) == 0 {
		return 0, fmt.Errorf("invalid gps value %s", value)
	}

	var degrees float64
	for i, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		ratParts := strings.Split(part, "/")
		if len(ratParts) == 2 {
			num, err := strconv.ParseFloat(strings.TrimSpace(ratParts[0]), 64)
			if err != nil {
				return 0, err
			}
			den, err := strconv.ParseFloat(strings.TrimSpace(ratParts[1]), 64)
			if err != nil {
				return 0, err
			}
			if den == 0 {
				continue
			}
			degrees += num / den / math.Pow(60, float64(i))
		} else {
			// fallback for decimal form
			val, err := strconv.ParseFloat(part, 64)
			if err != nil {
				return 0, err
			}
			degrees += val / math.Pow(60, float64(i))
		}
	}

	ref = strings.ToUpper(strings.TrimSpace(ref))
	if ref == "S" || ref == "W" {
		degrees *= -1
	}

	return degrees, nil
}

func ptr[T any](v T) *T {
	return &v
}
