package storage

import (
	"github.com/album/backend/internal/storage/interfaces"
)

// 重新导出接口和类型，保持向后兼容
type PutOptions = interfaces.PutOptions
type FileInfo = interfaces.FileInfo
type PoolInfo = interfaces.PoolInfo
type PrimaryStorage = interfaces.PrimaryStorage
type SecondaryStorage = interfaces.SecondaryStorage
type UploadStatus = interfaces.UploadStatus

// 注意：FileType 已移除，请使用业务层的 MediaFileType 和存储层的 Extension + Variant
