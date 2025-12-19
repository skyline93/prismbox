package thumbhash

import (
	"bytes"
	"context"
	"encoding/base64"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"os"

	_ "image/gif"

	"go.n16f.net/thumbhash"
)

// Generator ThumbHash 生成器
// 使用标准的 go-thumbhash 库实现
type Generator struct {
	// 不再需要 imagickManager，使用标准库
}

// NewGenerator 创建 ThumbHash 生成器
func NewGenerator() (*Generator, error) {
	// go-thumbhash 库不需要初始化
	return &Generator{}, nil
}

// GenerateFromFile 从文件路径生成 ThumbHash
// 返回 base64 编码的 ThumbHash 字符串
func (g *Generator) GenerateFromFile(ctx context.Context, imagePath string) (string, error) {
	// 打开并解码图片
	file, err := os.Open(imagePath)
	if err != nil {
		return "", fmt.Errorf("open image: %w", err)
	}
	defer file.Close()

	return g.GenerateFromReader(ctx, file)
}

// GenerateFromReader 从 io.Reader 生成 ThumbHash
func (g *Generator) GenerateFromReader(ctx context.Context, reader io.Reader) (string, error) {
	// 解码图片
	img, _, err := image.Decode(reader)
	if err != nil {
		return "", fmt.Errorf("decode image: %w", err)
	}

	// 使用 go-thumbhash 库生成哈希
	// EncodeImage 函数接受 image.Image 并返回 ThumbHash 字节数组
	hash := thumbhash.EncodeImage(img)

	// 编码为 base64
	return base64.StdEncoding.EncodeToString(hash), nil
}

// DecodeThumbHash 解码 ThumbHash（用于测试和验证）
// 返回解码后的字节数组
func DecodeThumbHash(encoded string) ([]byte, error) {
	return base64.StdEncoding.DecodeString(encoded)
}

// DecodeToImage 从 base64 编码的 ThumbHash 解码生成占位图
// 返回 JPEG 格式的图片数据（作为降级方案）
func DecodeToImage(encodedThumbHash string, width, height int) ([]byte, error) {
	// 1. 解码 base64
	hashBytes, err := base64.StdEncoding.DecodeString(encodedThumbHash)
	if err != nil {
		return nil, fmt.Errorf("decode base64: %w", err)
	}

	// 2. 使用 thumbhash 库解码为图片
	img, err := thumbhash.DecodeImage(hashBytes)
	if err != nil {
		return nil, fmt.Errorf("decode thumbhash: %w", err)
	}

	// 3. 如果指定了尺寸，缩放图片
	if width > 0 && height > 0 && (img.Bounds().Dx() != width || img.Bounds().Dy() != height) {
		// 使用简单的最近邻缩放（对于占位图足够）
		scaled := image.NewRGBA(image.Rect(0, 0, width, height))
		srcW := img.Bounds().Dx()
		srcH := img.Bounds().Dy()

		for y := 0; y < height; y++ {
			for x := 0; x < width; x++ {
				srcX := x * srcW / width
				srcY := y * srcH / height
				scaled.Set(x, y, img.At(srcX, srcY))
			}
		}
		img = scaled
	}

	// 4. 编码为 JPEG（质量85，适合占位图）
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, img, &jpeg.Options{Quality: 85}); err != nil {
		return nil, fmt.Errorf("encode jpeg: %w", err)
	}

	return buf.Bytes(), nil
}

// DecodeToPNG 从 base64 编码的 ThumbHash 解码生成 PNG 格式占位图
// 返回 PNG 格式的图片数据（如果需要透明通道）
func DecodeToPNG(encodedThumbHash string, width, height int) ([]byte, error) {
	// 1. 解码 base64
	hashBytes, err := base64.StdEncoding.DecodeString(encodedThumbHash)
	if err != nil {
		return nil, fmt.Errorf("decode base64: %w", err)
	}

	// 2. 使用 thumbhash 库解码为图片
	img, err := thumbhash.DecodeImage(hashBytes)
	if err != nil {
		return nil, fmt.Errorf("decode thumbhash: %w", err)
	}

	// 3. 如果指定了尺寸，缩放图片
	if width > 0 && height > 0 && (img.Bounds().Dx() != width || img.Bounds().Dy() != height) {
		scaled := image.NewRGBA(image.Rect(0, 0, width, height))
		srcW := img.Bounds().Dx()
		srcH := img.Bounds().Dy()

		for y := 0; y < height; y++ {
			for x := 0; x < width; x++ {
				srcX := x * srcW / width
				srcY := y * srcH / height
				scaled.Set(x, y, img.At(srcX, srcY))
			}
		}
		img = scaled
	}

	// 4. 编码为 PNG
	var buf bytes.Buffer
	encoder := &png.Encoder{CompressionLevel: png.BestSpeed}
	if err := encoder.Encode(&buf, img); err != nil {
		return nil, fmt.Errorf("encode png: %w", err)
	}

	return buf.Bytes(), nil
}
