# 7.6 媒体处理模块架构设计

## 7.6.1 模块定位

媒体处理模块是一个**独立的核心模块**，具有双重定位：

- **独立包**：位于 `pkg/media-processor`，作为独立的可复用包，可以被其他项目集成
- **核心模块**：被 `internal/service/media` 和 `internal/worker/media` 依赖，是应用的核心组件

## 7.6.2 设计原则

### 核心设计原则

1. **并发安全**：ImageMagick 只能初始化一次，使用单例管理模式，确保线程安全
2. **RAW 文件处理**：专门处理 RAW 格式图片，提高转换成功率，支持重试机制
3. **多规格支持**：支持多种缩略图和预览图规格，适应不同场景需求
4. **保持宽高比**：预览图严格保持原始宽高比，不进行裁剪
5. **可重复生成**：缩略图和预览图可以重复生成，当丢失或损毁后可通过原始文件重新生成
6. **容错处理**：元数据提取失败不影响整体流程，部分失败时记录错误并继续处理
7. **独立包设计**：作为独立包设计，便于集成到不同项目中

## 7.6.3 目录结构

```
pkg/media-processor/              # 独立的媒体处理包
├── processor.go                  # 主处理器接口和工厂
├── config.go                      # 配置结构
├── types.go                       # 类型定义（规格、元数据等）
├── errors.go                      # 错误定义
│
├── image/                         # 图片处理模块
│   ├── processor.go               # 图片处理器接口
│   ├── imagick.go                 # ImageMagick 实现
│   ├── manager.go                 # ImageMagick 生命周期管理（单例）
│   ├── raw.go                     # RAW 文件处理（专门处理）
│   ├── metadata.go                # 元数据提取（容错）
│   └── spec.go                    # 规格定义和验证
│
├── video/                         # 视频处理模块
│   ├── processor.go               # 视频处理器接口
│   ├── ffmpeg.go                  # FFmpeg 实现
│   ├── metadata.go                # 元数据提取（容错）
│   └── spec.go                    # 规格定义和验证
│
└── internal/                      # 内部工具（不对外暴露）
    ├── pool/                      # 资源池管理
    │   ├── imagick_pool.go        # ImageMagick 资源池
    │   └── pool.go                 # 通用资源池接口
    └── utils/                      # 工具函数
        ├── file.go                 # 文件工具
        └── format.go               # 格式检测

internal/service/media/            # 媒体服务（业务逻辑层）
├── service.go                     # 服务接口和实现
└── processor.go                   # 调用 media-processor

internal/worker/media/              # 媒体处理任务（后台任务层）
├── handler.go                     # 任务处理器（注册到 GQ）
└── processor.go                    # 调用 media-processor
```

## 7.6.4 核心接口设计

### 主处理器接口

```go
// pkg/media-processor/processor.go
package mediaprocessor

import (
    "context"
)

// MediaProcessor 媒体处理器工厂接口
type MediaProcessor interface {
    // ProcessImage 处理图片，生成所有配置的规格
    ProcessImage(ctx context.Context, originalPath string, specs []ImageSpec) (*ProcessResult, error)
    
    // ProcessVideo 处理视频，生成所有配置的规格
    ProcessVideo(ctx context.Context, originalPath string, specs []VideoSpec) (*ProcessResult, error)
    
    // GenerateThumbnail 生成指定规格的缩略图（可重复调用）
    GenerateThumbnail(ctx context.Context, originalPath string, spec ImageSpec) (string, error)
    
    // GeneratePreview 生成指定规格的预览图（可重复调用，保持宽高比）
    GeneratePreview(ctx context.Context, originalPath string, spec ImageSpec) (string, error)
    
    // ExtractImageMetadata 提取图片元数据（容错处理）
    ExtractImageMetadata(ctx context.Context, filePath string) (*MediaMetadata, error)
    
    // ExtractVideoMetadata 提取视频元数据（容错处理）
    ExtractVideoMetadata(ctx context.Context, filePath string) (*MediaMetadata, error)
    
    // Close 关闭处理器，清理资源
    Close() error
}

// ProcessResult 处理结果
type ProcessResult struct {
    GeneratedFiles []string           // 生成的文件路径列表
    Metadata        *MediaMetadata     // 提取的元数据
    Errors          []ProcessError     // 处理过程中的错误（部分失败的情况）
}

// ProcessError 处理错误
type ProcessError struct {
    Spec    string  // 规格名称
    Message string  // 错误信息
    Error   error   // 原始错误
}
```

### 图片处理器接口

```go
// pkg/media-processor/image/processor.go
package imageprocessor

import (
    "context"
    "github.com/album/backend/pkg/media-processor"
)

// ImageProcessor 图片处理器接口
type ImageProcessor interface {
    // Process 处理图片，生成所有规格
    Process(ctx context.Context, originalPath string, specs []mediaprocessor.ImageSpec) (*mediaprocessor.ProcessResult, error)
    
    // GenerateThumbnail 生成缩略图（可裁剪）
    GenerateThumbnail(ctx context.Context, originalPath string, spec mediaprocessor.ImageSpec) (string, error)
    
    // GeneratePreview 生成预览图（不裁剪，保持宽高比）
    GeneratePreview(ctx context.Context, originalPath string, spec mediaprocessor.ImageSpec) (string, error)
    
    // ExtractMetadata 提取元数据
    ExtractMetadata(ctx context.Context, filePath string) (*mediaprocessor.MediaMetadata, error)
    
    // IsRAW 判断是否为 RAW 文件
    IsRAW(filePath string) bool
    
    // ProcessRAW 处理 RAW 文件（专门的处理逻辑）
    ProcessRAW(ctx context.Context, rawPath string, outputSpecs []mediaprocessor.ImageSpec) (*mediaprocessor.ProcessResult, error)
}
```

### 视频处理器接口

```go
// pkg/media-processor/video/processor.go
package videoprocessor

import (
    "context"
    "github.com/album/backend/pkg/media-processor"
)

// VideoProcessor 视频处理器接口
type VideoProcessor interface {
    // Process 处理视频，生成所有规格
    Process(ctx context.Context, originalPath string, specs []mediaprocessor.VideoSpec) (*mediaprocessor.ProcessResult, error)
    
    // GenerateThumbnail 生成缩略图（从指定时间点提取帧）
    GenerateThumbnail(ctx context.Context, videoPath string, timeOffset float64, spec mediaprocessor.ImageSpec) (string, error)
    
    // GeneratePreview 生成预览视频
    GeneratePreview(ctx context.Context, originalPath string, spec mediaprocessor.VideoSpec) (string, error)
    
    // ExtractMetadata 提取元数据
    ExtractMetadata(ctx context.Context, filePath string) (*mediaprocessor.MediaMetadata, error)
}
```

## 7.6.5 ImageMagick 生命周期管理（并发安全）

### ImageMagick 管理器（单例模式）

```go
// pkg/media-processor/image/manager.go
package imageprocessor

import (
    "sync"
    "gopkg.in/gographics/imagick.v3/imagick"
)

// ImagickManager ImageMagick 生命周期管理器（单例模式，线程安全）
type ImagickManager struct {
    mu          sync.RWMutex
    initialized bool
    closed      bool
    refCount    int64  // 引用计数
}

var (
    globalManager *ImagickManager
    once          sync.Once
)

// GetManager 获取全局管理器（单例）
func GetManager() *ImagickManager {
    once.Do(func() {
        globalManager = &ImagickManager{}
    })
    return globalManager
}

// Initialize 初始化 ImageMagick（只能调用一次，线程安全）
func (m *ImagickManager) Initialize() error {
    m.mu.Lock()
    defer m.mu.Unlock()
    
    if m.initialized {
        return nil // 已经初始化，直接返回
    }
    
    if m.closed {
        return ErrImagickClosed // 已经关闭，不能重新初始化
    }
    
    imagick.Initialize()
    m.initialized = true
    return nil
}

// Acquire 获取资源（增加引用计数）
func (m *ImagickManager) Acquire() error {
    m.mu.RLock()
    defer m.mu.RUnlock()
    
    if !m.initialized {
        return ErrImagickNotInitialized
    }
    
    if m.closed {
        return ErrImagickClosed
    }
    
    m.refCount++
    return nil
}

// Release 释放资源（减少引用计数）
func (m *ImagickManager) Release() {
    m.mu.Lock()
    defer m.mu.Unlock()
    
    if m.refCount > 0 {
        m.refCount--
    }
}

// Close 关闭 ImageMagick（应用关闭时调用）
func (m *ImagickManager) Close() error {
    m.mu.Lock()
    defer m.mu.Unlock()
    
    if !m.initialized || m.closed {
        return nil
    }
    
    if m.refCount > 0 {
        return ErrImagickInUse // 还有资源在使用，不能关闭
    }
    
    imagick.Terminate()
    m.closed = true
    return nil
}

// IsInitialized 检查是否已初始化
func (m *ImagickManager) IsInitialized() bool {
    m.mu.RLock()
    defer m.mu.RUnlock()
    return m.initialized && !m.closed
}
```

### ImageMagick 资源池（并发安全）

```go
// pkg/media-processor/image/imagick.go
package imageprocessor

import (
    "context"
    "sync"
    "gopkg.in/gographics/imagick.v3/imagick"
)

// ImagickProcessor ImageMagick 处理器实现
type ImagickProcessor struct {
    manager *ImagickManager
    pool    *ImagickPool      // 资源池
    config  *Config
    mu      sync.RWMutex      // 保护配置和状态
}

// ImagickPool ImageMagick 资源池（线程安全）
type ImagickPool struct {
    pool    chan *imagick.MagickWand
    maxSize int
    mu      sync.Mutex
}

// NewImagickPool 创建资源池
func NewImagickPool(maxSize int) *ImagickPool {
    return &ImagickPool{
        pool:    make(chan *imagick.MagickWand, maxSize),
        maxSize: maxSize,
    }
}

// Get 从池中获取资源
func (p *ImagickPool) Get(ctx context.Context) (*imagick.MagickWand, error) {
    select {
    case wand := <-p.pool:
        return wand, nil
    default:
        // 池中没有可用资源，创建新的
        return imagick.NewMagickWand(), nil
    }
}

// Put 归还资源到池中
func (p *ImagickPool) Put(wand *imagick.MagickWand) {
    if wand == nil {
        return
    }
    
    // 清理资源
    wand.Clear()
    
    select {
    case p.pool <- wand:
        // 成功归还
    default:
        // 池已满，销毁资源
        wand.Destroy()
    }
}

// NewImagickProcessor 创建 ImageMagick 处理器
func NewImagickProcessor(config *Config) (*ImagickProcessor, error) {
    manager := GetManager()
    
    // 确保 ImageMagick 已初始化
    if err := manager.Initialize(); err != nil {
        return nil, err
    }
    
    return &ImagickProcessor{
        manager: manager,
        pool:    NewImagickPool(config.PoolSize),
        config:  config,
    }, nil
}
```

## 7.6.6 RAW 文件处理（专门处理）

### RAW 处理器设计

```go
// pkg/media-processor/image/raw.go
package imageprocessor

import (
    "context"
    "fmt"
    "github.com/album/backend/pkg/media-processor"
)

// RAWProcessor RAW 文件处理器
type RAWProcessor struct {
    processor *ImagickProcessor
    config    *RAWConfig
}

// RAWConfig RAW 处理配置
type RAWConfig struct {
    // RAW 转换选项
    Quality          int     // JPEG 质量（1-100）
    Format           string  // 输出格式（jpg, tiff等）
    
    // 错误处理
    MaxRetries       int     // 最大重试次数
    RetryDelay       int     // 重试延迟（秒）
    
    // RAW 格式支持
    SupportedFormats []string // 支持的 RAW 格式（CR2, NEF, ARW等）
}

// ProcessRAW 处理 RAW 文件（专门的处理逻辑）
func (p *ImagickProcessor) ProcessRAW(ctx context.Context, rawPath string, outputSpecs []mediaprocessor.ImageSpec) (*mediaprocessor.ProcessResult, error) {
    // 1. 验证 RAW 格式
    if !p.IsRAW(rawPath) {
        return nil, ErrNotRAWFile
    }
    
    // 2. 使用 ImageMagick 的 RAW 解码器（需要安装 ufraw 或 dcraw）
    wand, err := p.pool.Get(ctx)
    if err != nil {
        return nil, err
    }
    defer p.pool.Put(wand)
    
    // 3. 设置 RAW 处理选项
    wand.SetImageFormat("raw") // 或使用特定的 RAW 格式
    
    // 4. 读取 RAW 文件（可能需要重试）
    var readErr error
    for i := 0; i < p.config.RAWConfig.MaxRetries; i++ {
        if err := wand.ReadImage(rawPath); err == nil {
            readErr = nil
            break
        }
        readErr = err
        
        // 等待后重试
        select {
        case <-ctx.Done():
            return nil, ctx.Err()
        case <-time.After(time.Duration(p.config.RAWConfig.RetryDelay) * time.Second):
        }
    }
    
    if readErr != nil {
        return nil, fmt.Errorf("failed to read RAW file after %d retries: %w", 
            p.config.RAWConfig.MaxRetries, readErr)
    }
    
    // 5. 转换为 JPEG 并生成所有规格
    // ... 实现细节
    
    return result, nil
}

// IsRAW 判断是否为 RAW 文件
func (p *ImagickProcessor) IsRAW(filePath string) bool {
    ext := strings.ToLower(filepath.Ext(filePath))
    for _, format := range p.config.RAWConfig.SupportedFormats {
        if ext == "."+strings.ToLower(format) {
            return true
        }
    }
    return false
}
```

## 7.6.7 规格配置设计

### 图片规格配置

```go
// pkg/media-processor/types.go
package mediaprocessor

// ImageSpec 图片规格配置
type ImageSpec struct {
    Name     string  // 规格名称，如 "thumbnail", "preview", "small", "medium", "large"
    MaxWidth int     // 最大宽度（0表示不限制）
    MaxHeight int    // 最大高度（0表示不限制）
    Quality  int     // 质量（1-100，JPEG）
    Format   string  // 输出格式，如 "jpg", "png", "webp"
    Crop     bool    // 是否允许裁剪（缩略图可以裁剪，预览图不能裁剪）
}

// VideoSpec 视频规格配置
type VideoSpec struct {
    Name      string  // 规格名称，如 "preview", "small", "medium"
    MaxWidth  int     // 最大宽度
    Quality   int     // 质量（CRF值，越小质量越好）
    Format    string  // 输出格式，如 "mp4", "webm"
}
```

### 默认规格配置

```go
// pkg/media-processor/config.go
package mediaprocessor

// DefaultConfig 返回默认配置
func DefaultConfig() *Config {
    return &Config{
        DefaultImageSpecs: []ImageSpec{
            {
                Name:     "thumbnail",
                MaxWidth:  400,
                MaxHeight: 400,
                Quality:   75,
                Format:    "jpg",
                Crop:      true, // 缩略图可以裁剪
            },
            {
                Name:     "preview",
                MaxWidth:  1280,
                MaxHeight: 0, // 不限制高度
                Quality:   80,
                Format:    "jpg",
                Crop:      false, // 预览图不裁剪，保持宽高比
            },
            {
                Name:     "small",
                MaxWidth:  640,
                MaxHeight: 0,
                Quality:   85,
                Format:    "jpg",
                Crop:      false,
            },
            {
                Name:     "medium",
                MaxWidth:  1920,
                MaxHeight: 0,
                Quality:   90,
                Format:    "jpg",
                Crop:      false,
            },
        },
        DefaultVideoSpecs: []VideoSpec{
            {
                Name:     "preview",
                MaxWidth:  1280,
                Quality:   23,
                Format:    "mp4",
            },
        },
        Concurrency: 4,
    }
}
```

## 7.6.8 元数据提取（容错处理）

### 元数据结构

```go
// pkg/media-processor/types.go
package mediaprocessor

import "time"

// MediaMetadata 媒体元数据（所有字段都是可选的，容错处理）
type MediaMetadata struct {
    // 基础信息
    Width       *int     `json:"width,omitempty"`
    Height      *int     `json:"height,omitempty"`
    FileSize    *int64   `json:"file_size,omitempty"`
    MimeType    *string  `json:"mime_type,omitempty"`
    
    // 图片元数据
    MediaTakenAt *time.Time `json:"media_taken_at,omitempty"`
    CameraMake   *string    `json:"camera_make,omitempty"`
    CameraModel  *string    `json:"camera_model,omitempty"`
    Latitude     *float64   `json:"latitude,omitempty"`
    Longitude    *float64   `json:"longitude,omitempty"`
    
    // 视频元数据
    Duration        *float64 `json:"duration,omitempty"`
    VideoCodec      *string  `json:"video_codec,omitempty"`
    AudioCodec      *string  `json:"audio_codec,omitempty"`
    FrameRate       *float64 `json:"frame_rate,omitempty"`
    BitRate         *int64   `json:"bit_rate,omitempty"`
    AudioChannels   *int     `json:"audio_channels,omitempty"`
    AudioSampleRate *int     `json:"audio_sample_rate,omitempty"`
}
```

### 容错处理原则

1. **EXIF 解析失败**：网络图片、截屏等可能没有 EXIF，不返回错误，只记录日志
2. **部分字段缺失**：某些字段提取失败不影响其他字段的提取
3. **视频元数据提取失败**：如果 ffprobe 失败，返回部分元数据，不返回错误
4. **格式检测失败**：使用备用方法检测格式

## 7.6.9 应用集成

### Service 层集成

```go
// internal/service/media/service.go
package media

import (
    "context"
    "github.com/album/backend/pkg/media-processor"
)

type MediaService interface {
    // UploadMedia 上传媒体文件
    UploadMedia(ctx context.Context, req *UploadMediaRequest) (*MediaResponse, error)
    
    // RegenerateThumbnail 重新生成缩略图
    RegenerateThumbnail(ctx context.Context, mediaUUID string, specName string) error
    
    // RegeneratePreview 重新生成预览图
    RegeneratePreview(ctx context.Context, mediaUUID string, specName string) error
}

type service struct {
    repo          repository.MediaRepository
    storageManager *storage.StorageManager
    taskQueue     *gq.Client
    processor     mediaprocessor.MediaProcessor
}
```

### Worker 层集成

```go
// internal/worker/media/handler.go
package media

import (
    "context"
    "encoding/json"
    "github.com/album/backend/pkg/gq"
    "github.com/album/backend/pkg/media-processor"
)

// RegisterMediaProcessors 注册媒体处理任务
func RegisterMediaProcessors(mux *gq.ServeMux, processor mediaprocessor.MediaProcessor) {
    mux.HandleFunc("media:process:image", processImageHandler(processor))
    mux.HandleFunc("media:process:video", processVideoHandler(processor))
}

func processImageHandler(processor mediaprocessor.MediaProcessor) gq.HandlerFunc {
    return func(ctx context.Context, task *gq.Task) error {
        var payload struct {
            MediaUUID string `json:"media_uuid"`
            FilePath  string `json:"file_path"`
        }
        
        if err := json.Unmarshal(task.Payload, &payload); err != nil {
            return err
        }
        
        // 使用处理器处理图片
        result, err := processor.ProcessImage(ctx, payload.FilePath, nil) // nil 使用默认规格
        if err != nil {
            return err
        }
        
        // 更新数据库状态和元数据
        // ...
        
        return nil
    }
}
```

### 依赖注入

```go
// internal/app/app.go
type App struct {
    // ...
    MediaProcessor mediaprocessor.MediaProcessor
}

// internal/app/builder.go
func (b *Builder) BuildMediaProcessor() error {
    config := mediaprocessor.DefaultConfig()
    // 从应用配置加载
    processor, err := mediaprocessor.NewProcessor(config)
    if err != nil {
        return err
    }
    
    b.app.MediaProcessor = processor
    return nil
}

// 应用关闭时清理
func (a *App) Close() error {
    if a.MediaProcessor != nil {
        return a.MediaProcessor.Close()
    }
    return nil
}
```

## 7.6.10 并发安全设计要点

### 1. ImageMagick 初始化

- **单例模式**：使用 `sync.Once` 确保只初始化一次
- **线程安全**：使用 `sync.RWMutex` 保护状态
- **引用计数**：跟踪资源使用情况，防止过早关闭

### 2. 资源池管理

- **资源池**：MagickWand 资源池，避免频繁创建/销毁
- **并发安全**：使用 channel 实现线程安全的资源池
- **资源清理**：自动清理资源，防止内存泄漏

### 3. 并发处理

- **并发生成**：使用 goroutine 并发生成多个规格
- **同步机制**：使用 `sync.WaitGroup` 同步并发任务
- **错误收集**：收集部分失败的错误，不影响整体流程

## 7.6.11 RAW 文件处理设计要点

### 1. 格式检测

- **专门检测**：`IsRAW` 方法专门检测 RAW 格式
- **格式支持**：支持多种 RAW 格式（CR2, NEF, ARW等）
- **扩展性**：便于添加新的 RAW 格式支持

### 2. 专门处理

- **专门方法**：`ProcessRAW` 方法专门处理 RAW 文件
- **解码器支持**：使用 ImageMagick 的 RAW 解码器（需要安装 ufraw 或 dcraw）
- **转换选项**：专门的 RAW 转换选项配置

### 3. 错误重试

- **重试机制**：失败时自动重试，提高成功率
- **可配置**：重试次数和延迟可配置
- **超时控制**：支持上下文超时控制

## 7.6.12 模块边界

### 独立包设计

- **pkg/media-processor**：独立的可复用包，不依赖 `internal` 包
- **接口抽象**：通过接口定义，便于测试和替换
- **依赖注入**：通过依赖注入使用，便于测试

### 核心模块集成

- **internal/service/media**：业务逻辑层，调用 `pkg/media-processor`
- **internal/worker/media**：后台任务层，调用 `pkg/media-processor`
- **依赖注入**：通过 `internal/app` 进行依赖注入

## 7.6.13 配置示例

```yaml
# configs/config.yaml
media:
  processor:
    # ImageMagick 配置
    imagick:
      pool_size: 10          # 资源池大小
      memory_limit: "2GB"    # 内存限制
      disk_limit: "10GB"     # 磁盘限制
      
      # RAW 处理配置
      raw:
        max_retries: 3        # 最大重试次数
        retry_delay: 5       # 重试延迟（秒）
        supported_formats:   # 支持的 RAW 格式
          - CR2
          - NEF
          - ARW
          - ORF
          - RW2
    
    # FFmpeg 配置
    ffmpeg:
      binary_path: "/usr/bin/ffmpeg"
      probe_path: "/usr/bin/ffprobe"
      max_concurrency: 4
      process_timeout: 600   # 超时时间（秒）
    
    # 默认规格
    default_image_specs:
      - name: "thumbnail"
        max_width: 400
        max_height: 400
        quality: 75
        format: "jpg"
        crop: true
      - name: "preview"
        max_width: 1280
        max_height: 0
        quality: 80
        format: "jpg"
        crop: false
    
    # 并发配置
    concurrency: 4
```

## 7.6.14 总结

媒体处理模块架构设计的关键特点：

- ✅ **并发安全**：ImageMagick 单例管理，资源池，线程安全
- ✅ **RAW 处理**：专门处理逻辑，错误重试，提高成功率
- ✅ **多规格支持**：灵活的规格配置，适应不同场景
- ✅ **保持宽高比**：预览图严格保持原始宽高比
- ✅ **可重复生成**：支持重新生成缩略图和预览图
- ✅ **容错处理**：元数据提取失败不影响整体流程
- ✅ **独立包设计**：作为独立包，便于复用和集成
- ✅ **核心模块**：与应用逻辑解耦，便于维护和测试

