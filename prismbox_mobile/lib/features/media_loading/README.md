# 媒体资源展示模块实现说明

## 概述

媒体资源展示模块已根据详细设计文档完成实现，提供了完整的图片加载、缓存和展示功能。

## 已实现组件

### 1. 实体类（Domain Layer）

- **BaseAsset** (`lib/domain/entities/base_asset.dart`)
  - 基础资产实体抽象类
  - 定义了所有资产共有的属性和方法

- **LocalAsset** (`lib/domain/entities/local_asset.dart`)
  - 本地资产实体
  - 包含 photo_manager 的 AssetEntity 引用

- **RemoteAsset** (`lib/domain/entities/remote_asset.dart`)
  - 远程资产实体
  - 包含 ThumbHash 等远程资源特有属性

### 2. 配置类（Core Layer）

- **AppSetting** (`lib/core/settings/app_setting.dart`)
  - 应用设置工具类
  - 提供统一的设置访问接口
  - 支持 `preferRemoteImage`、`loadPreview`、`loadOriginal` 等设置

### 3. 缓存层（Core/Cache）

- **CustomImageCache** (`lib/core/cache/custom_image_cache.dart`)
  - 三级内存缓存实现
  - ThumbHash、小图、大图分离缓存
  - 防止大图驱逐小图

- **ThumbnailImageCacheManager** (`lib/core/cache/thumbnail_cache_manager.dart`)
  - 缩略图磁盘缓存管理器
  - 最多 5000 个对象，30 天过期

- **RemoteImageCacheManager** (`lib/core/cache/remote_image_cache_manager.dart`)
  - 远程图片磁盘缓存管理器
  - 最多 500 个对象，30 天过期

### 4. ImageProvider 层（Features/MediaLoading/Providers）

- **LocalThumbProvider** (`lib/features/media_loading/providers/local_thumb_provider.dart`)
  - 本地缩略图提供者
  - 使用 photo_manager 生成缩略图
  - 支持磁盘缓存

- **LocalFullImageProvider** (`lib/features/media_loading/providers/local_full_provider.dart`)
  - 本地原图提供者
  - 支持图片和视频资源

- **RemoteThumbProvider** (`lib/features/media_loading/providers/remote_thumb_provider.dart`)
  - 远程缩略图提供者
  - 支持流式下载和进度报告

- **RemoteFullImageProvider** (`lib/features/media_loading/providers/remote_full_provider.dart`)
  - 远程原图提供者
  - 支持渐进式加载（预览图 → 原图）

### 5. 占位符支持（Features/MediaLoading/Thumbhash）

- **ThumbHashProvider** (`lib/features/media_loading/thumbhash/thumbhash_provider.dart`)
  - ThumbHash 解码提供者
  - 注意：当前为占位实现，需要完整的 ThumbHash 解码库

- **GradientPlaceholderProvider** (`lib/features/media_loading/thumbhash/gradient_placeholder_provider.dart`)
  - 渐变占位符提供者
  - 基于主题色生成渐变占位符

### 6. 资源选择工厂（Features/MediaLoading）

- **image_provider_factory.dart** (`lib/features/media_loading/image_provider_factory.dart`)
  - `getThumbnailImageProvider()`: 获取缩略图提供者
  - `getFullImageProvider()`: 获取原图提供者
  - `getPlaceholderProvider()`: 获取占位符提供者
  - 智能资源选择逻辑

### 7. UI 组件（Presentation/Widgets/Media）

- **MediaImageWidget** (`lib/presentation/widgets/media/media_image_widget.dart`)
  - 媒体图片组件
  - 支持渐进式加载和错误处理
  - 支持占位符和加载进度显示

- **ThumbnailWidget** (`lib/presentation/widgets/media/thumbnail_widget.dart`)
  - 缩略图组件
  - MediaImageWidget 的便捷封装

- **GradientPlaceholderWidget** (`lib/presentation/widgets/media/gradient_placeholder_widget.dart`)
  - 渐变占位符组件
  - 用于图片加载时的占位显示

## 使用方法

### 基本使用

```dart
import 'package:prismbox/presentation/widgets/media/media_image_widget.dart';
import 'package:prismbox/domain/entities/local_asset.dart';

// 显示缩略图
MediaImageWidget(
  asset: localAsset,
  isThumbnail: true,
)

// 显示原图
MediaImageWidget(
  asset: localAsset,
  isThumbnail: false,
  loadOriginal: true,
)
```

### 使用缩略图组件

```dart
import 'package:prismbox/presentation/widgets/media/thumbnail_widget.dart';

ThumbnailWidget(
  asset: asset,
  size: const Size(200, 200),
)
```

### 初始化 CustomImageCache

在 `main.dart` 中初始化：

```dart
import 'package:prismbox/core/cache/custom_image_cache.dart';
import 'package:flutter/painting.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 替换默认 ImageCache
  final customCache = CustomImageCache();
  PaintingBinding.instance.imageCache = customCache;
  
  runApp(MyApp());
}
```

## 注意事项

1. **ThumbHash 解码**：当前 ThumbHashProvider 为占位实现，需要集成完整的 ThumbHash 解码库（如 `thumbhash` 包）。

2. **依赖要求**：
   - `photo_manager: ^3.7.1` - 已添加到 pubspec.yaml
   - `flutter_cache_manager: ^3.4.1` - 已添加到 pubspec.yaml

3. **AssetEntity 加载**：LocalAsset 需要包含 AssetEntity 才能使用本地资源提供者。如果 AssetEntity 为 null，需要先通过 photo_manager 加载。

4. **服务器 URL**：使用远程资源提供者时，需要提供正确的服务器 URL。

5. **错误处理**：所有 ImageProvider 都包含完整的错误处理和日志记录。

## 后续工作

1. **ThumbHash 解码**：集成完整的 ThumbHash 解码库
2. **性能优化**：根据实际使用情况调整缓存策略
3. **测试**：编写单元测试和集成测试
4. **文档完善**：补充 API 文档和使用示例

## 文件结构

```
lib/
├── domain/entities/
│   ├── base_asset.dart
│   ├── local_asset.dart
│   └── remote_asset.dart
├── core/
│   ├── settings/
│   │   └── app_setting.dart
│   └── cache/
│       ├── custom_image_cache.dart
│       ├── thumbnail_cache_manager.dart
│       └── remote_image_cache_manager.dart
├── features/media_loading/
│   ├── providers/
│   │   ├── local_thumb_provider.dart
│   │   ├── local_full_provider.dart
│   │   ├── remote_thumb_provider.dart
│   │   └── remote_full_provider.dart
│   ├── thumbhash/
│   │   ├── thumbhash_provider.dart
│   │   └── gradient_placeholder_provider.dart
│   ├── image_provider_factory.dart
│   └── README.md
└── presentation/widgets/media/
    ├── media_image_widget.dart
    ├── thumbnail_widget.dart
    └── gradient_placeholder_widget.dart
```

