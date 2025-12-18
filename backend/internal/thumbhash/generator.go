package thumbhash

import (
	"context"
	"encoding/base64"
	"fmt"
	"io"
	"os"

	"gopkg.in/gographics/imagick.v3/imagick"
)

// Generator ThumbHash 生成器
type Generator struct {
	manager *imagickManager
}

// NewGenerator 创建 ThumbHash 生成器
func NewGenerator() (*Generator, error) {
	manager := getImagickManager()
	if err := manager.Initialize(); err != nil {
		return nil, fmt.Errorf("initialize imagick: %w", err)
	}

	return &Generator{
		manager: manager,
	}, nil
}

// GenerateFromFile 从文件路径生成 ThumbHash
// 返回 base64 编码的 ThumbHash 字符串
func (g *Generator) GenerateFromFile(ctx context.Context, imagePath string) (string, error) {
	// 使用 ImageMagick 读取图片
	mw := imagick.NewMagickWand()
	defer mw.Destroy()

	if err := mw.ReadImage(imagePath); err != nil {
		return "", fmt.Errorf("read image: %w", err)
	}

	// 获取原始尺寸
	origWidth := int(mw.GetImageWidth())
	origHeight := int(mw.GetImageHeight())

	// ThumbHash 算法：将图片缩放到小尺寸（通常 100x100 或更小），然后进行压缩编码
	// 为了生成更小的占位符，我们使用 100x100 作为目标尺寸
	targetSize := 100
	thumbWidth := targetSize
	thumbHeight := targetSize

	// 保持宽高比
	if origWidth > origHeight {
		thumbHeight = int(float64(targetSize) * float64(origHeight) / float64(origWidth))
	} else {
		thumbWidth = int(float64(targetSize) * float64(origWidth) / float64(origHeight))
	}

	// 确保最小尺寸
	if thumbWidth < 1 {
		thumbWidth = 1
	}
	if thumbHeight < 1 {
		thumbHeight = 1
	}

	// 缩放图片
	if err := mw.ResizeImage(uint(thumbWidth), uint(thumbHeight), imagick.FILTER_LANCZOS); err != nil {
		return "", fmt.Errorf("resize image: %w", err)
	}

	// 转换为 RGB 格式（ThumbHash 使用 RGB）
	if err := mw.SetImageColorspace(imagick.COLORSPACE_SRGB); err != nil {
		return "", fmt.Errorf("set colorspace: %w", err)
	}

	// 获取像素数据
	pixels, err := mw.ExportImagePixels(0, 0, uint(thumbWidth), uint(thumbHeight), "RGB", imagick.PIXEL_CHAR)
	if err != nil {
		return "", fmt.Errorf("export pixels: %w", err)
	}
	if pixels == nil {
		return "", fmt.Errorf("export pixels failed")
	}

	// 类型断言为 []byte
	pixelBytes, ok := pixels.([]byte)
	if !ok {
		return "", fmt.Errorf("unexpected pixel type")
	}

	// 生成 ThumbHash：使用简化的算法
	// 实际 ThumbHash 算法更复杂，这里使用一个简化版本
	// 将像素数据压缩并编码为 base64
	thumbHash := g.encodeThumbHash(pixelBytes, thumbWidth, thumbHeight, origWidth, origHeight)

	return base64.StdEncoding.EncodeToString(thumbHash), nil
}

// GenerateFromReader 从 io.Reader 生成 ThumbHash
func (g *Generator) GenerateFromReader(ctx context.Context, reader io.Reader) (string, error) {
	// 创建临时文件
	tmpFile, err := os.CreateTemp("", "thumbhash-*.jpg")
	if err != nil {
		return "", fmt.Errorf("create temp file: %w", err)
	}
	defer os.Remove(tmpFile.Name())
	defer tmpFile.Close()

	// 写入临时文件
	if _, err := io.Copy(tmpFile, reader); err != nil {
		return "", fmt.Errorf("copy to temp file: %w", err)
	}

	return g.GenerateFromFile(ctx, tmpFile.Name())
}

// encodeThumbHash 编码像素数据为 ThumbHash
// 这是一个简化版本，实际 ThumbHash 算法更复杂
// 返回的字节数组包含：原始尺寸信息 + 压缩的像素数据
func (g *Generator) encodeThumbHash(pixels []byte, thumbWidth, thumbHeight, origWidth, origHeight int) []byte {
	// 简化的 ThumbHash 编码：
	// 1. 将 RGB 像素数据进一步压缩（使用简单的平均采样）
	// 2. 生成一个紧凑的二进制表示

	// 采样到更小的尺寸（例如 20x20）以减少数据量
	sampleSize := 20
	if thumbWidth < sampleSize {
		sampleSize = thumbWidth
	}
	if thumbHeight < sampleSize {
		sampleSize = thumbHeight
	}

	// 计算采样步长
	stepX := thumbWidth / sampleSize
	stepY := thumbHeight / sampleSize
	if stepX < 1 {
		stepX = 1
	}
	if stepY < 1 {
		stepY = 1
	}

	// 采样像素
	sampled := make([]byte, 0, sampleSize*sampleSize*3)
	for y := 0; y < thumbHeight && len(sampled)/3 < sampleSize*sampleSize; y += stepY {
		for x := 0; x < thumbWidth && len(sampled)/3 < sampleSize*sampleSize; x += stepX {
			idx := (y*thumbWidth + x) * 3
			if idx+2 < len(pixels) {
				sampled = append(sampled, pixels[idx], pixels[idx+1], pixels[idx+2])
			}
		}
	}

	// 添加尺寸信息（前8字节：原始宽高 + 采样尺寸）
	result := make([]byte, 8+len(sampled))
	// 原始尺寸（4字节）
	result[0] = byte(origWidth >> 8)
	result[1] = byte(origWidth & 0xFF)
	result[2] = byte(origHeight >> 8)
	result[3] = byte(origHeight & 0xFF)
	// 采样尺寸（2字节）
	result[4] = byte(sampleSize)
	result[5] = byte(sampleSize)
	// 保留2字节用于未来扩展
	result[6] = 0
	result[7] = 0
	copy(result[8:], sampled)

	return result
}

// DecodeThumbHash 解码 ThumbHash（用于测试和验证）
func DecodeThumbHash(encoded string) (origWidth, origHeight, sampleSize int, pixels []byte, err error) {
	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return 0, 0, 0, nil, fmt.Errorf("decode base64: %w", err)
	}

	if len(data) < 8 {
		return 0, 0, 0, nil, fmt.Errorf("invalid thumbhash data")
	}

	// 解析原始尺寸
	origWidth = int(data[0])<<8 | int(data[1])
	origHeight = int(data[2])<<8 | int(data[3])
	// 解析采样尺寸
	sampleSize = int(data[4])
	if int(data[5]) != sampleSize {
		return 0, 0, 0, nil, fmt.Errorf("invalid sample size")
	}
	pixels = data[8:]

	return origWidth, origHeight, sampleSize, pixels, nil
}

// imagickManager ImageMagick 管理器（单例）
type imagickManager struct {
	initialized bool
}

var globalManager *imagickManager

func getImagickManager() *imagickManager {
	if globalManager == nil {
		globalManager = &imagickManager{}
	}
	return globalManager
}

func (m *imagickManager) Initialize() error {
	if m.initialized {
		return nil
	}
	imagick.Initialize()
	m.initialized = true
	return nil
}
