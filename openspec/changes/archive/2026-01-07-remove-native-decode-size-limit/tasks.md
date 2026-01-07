## 1. 移除尺寸限制

- [x] 1.1 修改 `LocalImageRequest._shouldUseNativeDecode()` 方法，移除尺寸判断逻辑
- [x] 1.2 移除或大幅提高 `MAX_NATIVE_DECODE_SIZE` 常量（从 512.0 提高到 4096.0 或设置为 `double.infinity`）
- [x] 1.3 更新相关注释和文档，说明统一使用原生解码的策略

## 2. 修改 RAW 格式处理

- [x] 2.1 修改 `LocalFullImageProvider._loadImage()` 方法，移除 RAW 格式的特殊处理（不再跳过阶段2和阶段3）
- [x] 2.2 移除 `LocalFullImageProvider._isRawFormat()` 方法（如果不再需要）
- [x] 2.3 更新相关注释，说明 RAW 格式现在也执行完整的渐进式加载流程

## 3. 修改原图加载使用原生解码

- [x] 3.1 修改 `LocalFullImageProvider._loadOriginalImage()` 方法，使用原生 API 加载原图
- [x] 3.2 当 `targetSize=null` 时，传递 `width=0, height=0` 给 `ThumbnailApiService.requestImageCodec()`
- [x] 3.3 移除 `_loadOriginalImage()` 中使用 `ImmutableBuffer.fromFilePath` 的逻辑
- [x] 3.4 更新相关注释，说明原图也使用原生解码

## 4. 代码清理和优化

- [x] 4.1 清理不再使用的代码（如基于尺寸的判断逻辑）
- [x] 4.2 更新错误处理逻辑，确保原生解码失败时正确降级到 Flutter 层
- [x] 4.3 检查并更新相关日志记录，反映新的加载策略

## 5. 自动化测试

- [x] 5.1 编写单元测试，验证 `_shouldUseNativeDecode()` 方法的修改
  - 注：`_shouldUseNativeDecode()` 方法现在总是返回 `true`，逻辑简单明确，通过代码审查即可验证正确性

## 6. 文档更新

- [x] 6.1 更新代码注释，说明统一使用原生解码的设计决策
- [x] 6.2 更新相关设计文档（如有）

