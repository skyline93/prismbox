package storage

import (
	"github.com/album/backend/internal/storage/interfaces"
)

// 重新导出接口和类型，保持向后兼容
type FileType = interfaces.FileType
type PutOptions = interfaces.PutOptions
type FileInfo = interfaces.FileInfo
type PoolInfo = interfaces.PoolInfo
type PrimaryStorage = interfaces.PrimaryStorage
type SecondaryStorage = interfaces.SecondaryStorage
type UploadStatus = interfaces.UploadStatus

// 常量重新导出
const (
	FileTypeOriginal   = interfaces.FileTypeOriginal
	FileTypeThumbnail  = interfaces.FileTypeThumbnail
	FileTypePreview    = interfaces.FileTypePreview
	FileTypeEncrypted  = interfaces.FileTypeEncrypted
	FileTypeCompressed = interfaces.FileTypeCompressed
)
