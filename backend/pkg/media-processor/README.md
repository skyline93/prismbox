# 媒体处理模块（`pkg/media-processor`）

媒体处理模块是后端的核心能力之一，负责图片与视频的缩放、转码、缩略图/预览图生成以及元数据提取。本模块完全遵循《7.6 媒体处理模块架构设计》文档，并以独立可复用的 Go 包形式实现，可在 Album 项目或其他服务中直接集成。

---

## 1. 目录结构总览

```
pkg/media-processor/
├── config.go                 # 总体配置及默认值
├── errors.go                 # 统一错误定义
├── processor.go              # 对外公开的 MediaProcessor 接口
├── types.go                  # 业务类型（规格、元数据等）
│
├── image/
│   ├── processor.go          # 图片处理接口定义
│   ├── imagick.go            # ImageMagick 图片处理实现（缩放/裁剪/生成规格）
│   ├── manager.go            # ImageMagick 生命周期单例管理
│   ├── metadata.go           # EXIF 元数据提取
│   ├── raw.go                # RAW 图片专用处理流程
│   └── spec.go               # 图片规格校验逻辑
│
├── video/
│   ├── processor.go          # 视频处理接口定义
│   └── ffmpeg.go             # 基于 FFmpeg/FFprobe 的视频实现
│
└── internal/
    ├── pool/                 # 通用资源池及 MagickWand 池实现
    └── utils/                # 文件工具、格式检测等内部辅助
```

---

## 2. 核心接口（`mediaprocessor.MediaProcessor`）

```go
type MediaProcessor interface {
    ProcessImage(ctx context.Context, originalPath string, specs []ImageSpec) (*ProcessResult, error)
    ProcessVideo(ctx context.Context, originalPath string, specs []VideoSpec) (*ProcessResult, error)
    GenerateThumbnail(ctx context.Context, originalPath string, spec ImageSpec) (string, error)
    GeneratePreview(ctx context.Context, originalPath string, spec ImageSpec) (string, error)
    ExtractImageMetadata(ctx context.Context, filePath string) (*MediaMetadata, error)
    ExtractVideoMetadata(ctx context.Context, filePath string) (*MediaMetadata, error)
    Close() error
}
```

- `ProcessImage` / `ProcessVideo`：读取原始文件，根据规格批量生成派生文件并提取元数据，具有容错能力（部分规格失败不影响整体）。
- `GenerateThumbnail` / `GeneratePreview`：按需重复生成单一规格的缩略图/预览图。
- `Extract*Metadata`：提取图片（EXIF）或视频（FFprobe）元信息，字段均为可选。
- `Close`：释放底层资源（ImageMagick、资源池等），应用退出时务必调用。

`ProcessResult` 结构提供生成文件列表、提取到的元数据以及可选的规格失败信息。

---

## 3. 配置体系（`config.go` 与 `modules.MediaConfig`）

### 3.1 默认配置

`mediaprocessor.DefaultConfig()` 提供一份安全的默认值：

- 图片规格：`thumbnail`（400x400，允许裁剪）、`preview`（1280px 宽度保持比例）、`small`、`medium`。
- 视频规格：默认生成 `preview`（1280px）。
- 并发度 `Concurrency = 4`，ImageMagick 资源池大小 10。
- RAW 处理默认重试 3 次，输出 JPG，支持常见 RAW 格式（CR2、NEF、ARW...）。
- FFmpeg/FFprobe 默认二进制路径 `/usr/bin/ffmpeg` 与 `/usr/bin/ffprobe`。

### 3.2 应用配置映射

`internal/config/modules/media.go` 增加了 `MediaProcessorConfig`，可直接在 `configs/config.yaml` 中覆盖默认值：

```yaml
media:
  max_file_size: "100MB"
  processor:
    concurrency: 4
    imagick:
      pool_size: 10
      memory_limit: "2GB"
      disk_limit: "10GB"
      raw:
        quality: 90
        format: "jpg"
        max_retries: 3
        retry_delay: "5s"
        supported_formats: ["CR2", "NEF", "ARW", "ORF", "RW2"]
    ffmpeg:
      binary_path: "/usr/bin/ffmpeg"
      probe_path: "/usr/bin/ffprobe"
      max_concurrency: 4
      process_timeout: "10m"
      thumbnail_offset: 1.5
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
    default_video_specs:
      - name: "preview"
        max_width: 1280
        quality: 23
        format: "mp4"
```

`internal/app/builder.go` 会在构建流程中调用 `BuildMediaProcessor`，自动把上述配置转换成 `mediaprocessor.Config`。

---

## 4. 实现要点与特性

### 4.1 图片处理（ImageMagick）
- 单例初始化（`sync.Once`）+ 引用计数防止过早释放。
- 资源池（`internal/pool`）缓存 `MagickWand`，避免频繁创建。
- `ProcessRAW` 针对 RAW 文件提供重试机制与格式判断。
- 缩放策略：
  - `Crop == true`：使用 `resizeToCover` + 居中裁剪，保证输出固定尺寸。
  - `Crop == false`：使用 `resizeToFit`，保持宽高比不失真。
- 元数据提取支持常见 EXIF 字段（相机信息、经纬度、拍摄时间等），失败容错但记录日志。

### 4.2 视频处理（FFmpeg/FFprobe）
- `ProcessVideo` 使用工作池并发执行规格转码，避免阻塞。
- `GenerateThumbnail` 支持自定义时间偏移并通过 `-vf scale` 保持比例。
- `ExtractMetadata` 解析 FFprobe JSON，提取时长、尺寸、编解码器、码率、声道等字段。
- 超时、并发数、二进制路径均可配置。

### 4.3 结果与容错
- `ProcessResult.GeneratedFiles` 返回所有成功生成的文件路径。
- `ProcessResult.Errors` 收集每个规格的失败信息，便于服务层记录日志或重试。
- 元数据提取失败不会导致整个处理失败，符合架构文档“容错处理”要求。

---

## 5. 集成指南

### 5.1 Service 层使用

`internal/service/media/service.go` 已集成媒体处理器，实现：

- 上传时探测 MIME 类型，记录 `PROCESSING` 状态并入队后台处理任务。
- 提供 `RegenerateThumbnail` / `RegeneratePreview` API 供运营或修复场景使用。
- 借助 `StorageManager` 获取本地绝对路径，调用 `MediaProcessor` 生成派生文件。

### 5.2 Worker 层使用

`internal/worker/media/handler.go` 注册后台任务处理，完成：

- 从任务参数读取 `media_uuid`、原始文件路径。
- 调用 `ProcessImage` / `ProcessVideo` 执行批量规格生成。
- 将提取到的元数据回写到 `medias` 表，更新处理状态（`COMPLETED`/`FAILED`）。

在 `cmd/server/main.go` 中：

```go
media.RegisterMediaProcessors(
    mux,
    app.MediaRepo,
    app.StorageManager,
    app.MediaProcessor,
)
```

确保任务队列和数据库、存储管理器协同工作。

### 5.3 应用生命周期

应用关闭时（例如 `App.Close()`），务必调用 `MediaProcessor.Close()` 释放 ImageMagick 资源：

```go
func (a *App) Close() error {
    if a.MediaProcessor != nil {
        return a.MediaProcessor.Close()
    }
    return nil
}
```

---

## 6. 独立使用示例

```go
package main

import (
    "context"
    "log"

    mediaprocessor "github.com/album/backend/pkg/media-processor"
)

func main() {
    cfg := mediaprocessor.DefaultConfig()
    processor, err := mediaprocessor.NewProcessor(cfg)
    if err != nil {
        log.Fatalf("init processor failed: %v", err)
    }
    defer processor.Close()

    ctx := context.Background()
    result, err := processor.ProcessImage(ctx, "/path/to/image.jpg", nil) // nil => 使用默认 specs
    if err != nil {
        log.Fatalf("process image failed: %v", err)
    }

    log.Printf("generated files: %v", result.GeneratedFiles)
    if result.Metadata != nil && result.Metadata.Width != nil {
        log.Printf("width: %d", *result.Metadata.Width)
    }
}
```

---

## 7. 注意事项

- **环境依赖**：ImageMagick（`libmagickwand`）、FFmpeg、FFprobe 必须正确安装并在配置中声明路径。
- **RAW 支持**：RAW 解码需安装 `dcraw`/`ufraw` 等依赖，详见操作系统发行版本说明。
- **并发限制**：默认使用 goroutine + channel 控制并发，确保磁盘与 CPU 不被打满，可通过配置调整。
- **文件权限**：生成的派生文件使用 `utils.EnsureDir` 创建目录，默认权限 `0755`，根据部署需求可调整。
- **容错策略**：部分规格失败不会终止整体流程，请在调用侧关注 `ProcessResult.Errors` 以进行后续补偿。

---

该模块已在 `internal/service/media` 与 `internal/worker/media` 中串联完成，可直接在 Album 项目中使用。如需在其他项目中集成，请复用上述构建流程（配置 -> 初始化 -> Worker 任务），并适当调整存储、仓储接口实现。欢迎根据业务需求扩展规格类型或新增处理实现。 Enjoy! 🎉

