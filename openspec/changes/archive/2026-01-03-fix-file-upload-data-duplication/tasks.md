# Tasks: 修复文件上传数据流重复写入问题

## 1. 修复 Service 层文件上传数据流处理

- [x] 1.1 修改 `backend/internal/service/media/service.go` 的 `UploadMedia` 方法
- [x] 1.2 移除 `wrapDataReader` 调用（第253行）
- [x] 1.3 直接传递 `tempFile` 给 `storageManager.Put` 方法
- [x] 1.4 确保文件指针已重置（`tempFile.Seek(0, 0)`）

## 2. 清理不必要的代码

- [x] 2.1 检查 `wrapDataReader` 函数是否在其他地方使用
- [x] 2.2 如果 `wrapDataReader` 未被使用，移除该函数（第339-344行）
- [x] 2.3 移除 `wrapDataReader` 相关的导入（如果不再需要）

