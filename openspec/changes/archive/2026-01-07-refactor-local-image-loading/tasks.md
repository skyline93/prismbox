## 1. 重构 LocalImageRequest 缩略图加载逻辑

- [x] 1.1 在 `LocalImageRequest` 中引入 `ThumbnailApiService` 依赖
- [x] 1.2 定义尺寸阈值常量（如：小于 512x512 的请求使用原生解码）
- [x] 1.3 修改 `_loadThumbnail` 方法：
  - [x] 1.3.1 判断请求尺寸是否小于阈值，或者明确标记为缩略图
  - [x] 1.3.2 优先尝试使用 `ThumbnailApiService.requestImageCodec` 调用原生解码
  - [x] 1.3.3 处理原生解码返回的 Codec（通过新增的 `requestImageCodec` 方法）
  - [x] 1.3.4 保持现有缓存逻辑（原生解码结果暂不缓存，降级时使用 Flutter 层缓存）
  - [x] 1.3.5 如果原生解码失败，降级到现有的 Flutter 层处理逻辑
- [x] 1.4 处理视频缩略图：视频缩略图也使用原生解码（通过 `isVideo=true` 参数）
- [x] 1.5 添加错误处理和日志记录
- [x] 1.6 确保请求取消机制正常工作（原生解码支持取消）

## 2. 保持 LocalFullImageProvider 不变

- [x] 2.1 确保原图加载继续使用 `ImmutableBuffer.fromFilePath` 直接读取文件
- [x] 2.2 确保与 `LocalThumbProvider` 的协同工作正常

## 3. RAW 格式支持增强

- [x] 3.1 添加 RAW 格式检测（通过文件扩展名或 MIME 类型）
- [x] 3.2 实现 RAW 解码失败的降级策略（降级到 Flutter 层或显示错误）
- [x] 3.3 添加 RAW 格式相关的错误处理和用户提示

## 4. 远程图片处理优化

- [x] 4.1 优化缓存策略（确保缓存键唯一性、过期策略合理）
- [x] 4.2 优化渐进式加载性能（缩略图 → 预览图 → 原图）
- [x] 4.3 添加性能监控和日志记录

## 5. 代码质量与文档

- [x] 5.1 运行 `dart format` 格式化 Dart 代码
- [x] 5.2 运行 `flutter analyze` 检查代码质量
- [x] 5.3 运行 `openspec validate refactor-local-image-loading --strict` 验证提案
- [x] 5.4 更新相关代码注释和文档

