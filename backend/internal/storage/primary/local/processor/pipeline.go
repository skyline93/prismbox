package processor

import (
	"context"
	"fmt"
	"io"
	"os"
)

// Processor 处理器接口
type Processor interface {
	Process(ctx context.Context, input io.Reader, output io.Writer) error
	Name() string
}

// ProcessingPipeline 处理管道
type ProcessingPipeline struct {
	processors []Processor
}

// NewProcessingPipeline 创建处理管道
func NewProcessingPipeline(processors ...Processor) *ProcessingPipeline {
	return &ProcessingPipeline{
		processors: processors,
	}
}

// Process 处理数据流
func (pp *ProcessingPipeline) Process(ctx context.Context, input io.Reader) (io.ReadCloser, error) {
	if len(pp.processors) == 0 {
		// 没有处理器，直接返回输入
		return io.NopCloser(input), nil
	}

	var current io.Reader = input

	for i, processor := range pp.processors {
		// 1. 创建临时文件
		tempFile, err := os.CreateTemp("", fmt.Sprintf("processor_%d_*.tmp", i))
		if err != nil {
			return nil, fmt.Errorf("create temp file for processor %s: %w", processor.Name(), err)
		}

		// 2. 处理
		if err := processor.Process(ctx, current, tempFile); err != nil {
			tempFile.Close()
			os.Remove(tempFile.Name())
			return nil, fmt.Errorf("processor %s failed: %w", processor.Name(), err)
		}

		// 3. 关闭并重置为新的输入
		if err := tempFile.Close(); err != nil {
			os.Remove(tempFile.Name())
			return nil, fmt.Errorf("close temp file: %w", err)
		}

		// 打开临时文件作为下一个处理器的输入
		nextFile, err := os.Open(tempFile.Name())
		if err != nil {
			os.Remove(tempFile.Name())
			return nil, fmt.Errorf("open temp file: %w", err)
		}

		// 如果是最后一个处理器，返回文件（调用者负责清理）
		if i == len(pp.processors)-1 {
			return &tempFileReader{
				file:    nextFile,
				path:    tempFile.Name(),
				cleanup: true,
			}, nil
		}

		// 否则，继续下一个处理器
		current = nextFile
	}

	return nil, fmt.Errorf("unexpected end of pipeline")
}

// tempFileReader 临时文件读取器（自动清理）
type tempFileReader struct {
	file    *os.File
	path    string
	cleanup bool
}

// Read 读取数据
func (tfr *tempFileReader) Read(p []byte) (n int, err error) {
	return tfr.file.Read(p)
}

// Close 关闭并清理
func (tfr *tempFileReader) Close() error {
	if tfr.file != nil {
		tfr.file.Close()
	}
	if tfr.cleanup && tfr.path != "" {
		os.Remove(tfr.path)
	}
	return nil
}

// CompressionProcessor 压缩处理器（占位符，实际实现需要根据需求）
type CompressionProcessor struct {
	level int
}

// NewCompressionProcessor 创建压缩处理器
func NewCompressionProcessor(level int) *CompressionProcessor {
	return &CompressionProcessor{
		level: level,
	}
}

// Name 返回处理器名称
func (cp *CompressionProcessor) Name() string {
	return "compression"
}

// Process 处理数据（占位符实现）
func (cp *CompressionProcessor) Process(ctx context.Context, input io.Reader, output io.Writer) error {
	// TODO: 实现实际的压缩逻辑
	// 这里只是简单的复制
	_, err := io.Copy(output, input)
	return err
}

// EncryptionProcessor 加密处理器（占位符，实际实现需要根据需求）
type EncryptionProcessor struct {
	keyPath string
}

// NewEncryptionProcessor 创建加密处理器
func NewEncryptionProcessor(keyPath string) *EncryptionProcessor {
	return &EncryptionProcessor{
		keyPath: keyPath,
	}
}

// Name 返回处理器名称
func (ep *EncryptionProcessor) Name() string {
	return "encryption"
}

// Process 处理数据（占位符实现）
func (ep *EncryptionProcessor) Process(ctx context.Context, input io.Reader, output io.Writer) error {
	// TODO: 实现实际的加密逻辑
	// 这里只是简单的复制
	_, err := io.Copy(output, input)
	return err
}

// MetadataExtractor 元数据提取器（占位符，实际实现需要根据需求）
type MetadataExtractor struct{}

// NewMetadataExtractor 创建元数据提取器
func NewMetadataExtractor() *MetadataExtractor {
	return &MetadataExtractor{}
}

// Name 返回处理器名称
func (me *MetadataExtractor) Name() string {
	return "metadata"
}

// Process 处理数据（占位符实现）
func (me *MetadataExtractor) Process(ctx context.Context, input io.Reader, output io.Writer) error {
	// TODO: 实现实际的元数据提取逻辑
	// 这里只是简单的复制
	_, err := io.Copy(output, input)
	return err
}
