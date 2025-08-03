package routing

import "fmt"

// URL的路径格式统一定义为内部常量
const (
	publicSharePath    = "/s/%s"
	photoPreviewPath   = "/api/v1/photos/%s/download/preview"
	photoThumbnailPath = "/api/v1/photos/%s/download/thumbnail"
	photoOriginalPath  = "/api/v1/photos/%s/download/original"
)

// URLBuilder 是一个负责生成应用内URL的结构体
type URLBuilder struct {
	// 公开服务的基地址, e.g., "https://your.domain.com"
	PublicBaseURL string
}

// NewURLBuilder 创建一个新的URLBuilder实例
func NewURLBuilder(baseURL string) *URLBuilder {
	return &URLBuilder{PublicBaseURL: baseURL}
}

// BuildPublicShareURL 生成一个完整的、面向公众的分享链接
func (b *URLBuilder) BuildPublicShareURL(shareToken string) string {
	path := fmt.Sprintf(publicSharePath, shareToken)
	return b.PublicBaseURL + path
}

// BuildPhotoPreviewPath 生成照片预览的相对路径 (用于签名)
func (b *URLBuilder) BuildPhotoPreviewPath(photoUUID string) string {
	return fmt.Sprintf(photoPreviewPath, photoUUID)
}

// BuildPhotoThumbnailPath 生成照片缩略图的相对路径 (用于签名)
func (b *URLBuilder) BuildPhotoThumbnailPath(photoUUID string) string {
	return fmt.Sprintf(photoThumbnailPath, photoUUID)
}

// BuildPhotoOriginalPath 生成照片原始文件的相对路径 (用于签名)
func (b *URLBuilder) BuildPhotoOriginalPath(photoUUID string) string {
	return fmt.Sprintf(photoOriginalPath, photoUUID)
}
