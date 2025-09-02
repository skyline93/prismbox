// routing/url_builder.go

package routing

import "fmt"

// URL的路径格式统一定义为内部常量
const (
	publicSharePath    = "%s/s/%s"
	mediaPreviewPath   = "%s/api/v1/media/%s/download/preview"
	mediaThumbnailPath = "%s/api/v1/media/%s/download/thumbnail"
	mediaOriginalPath  = "%s/api/v1/media/%s/download/original"
	groupMediaPath     = "%s/api/v1/groups/%s/media/thumbnail/%s"
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
	return fmt.Sprintf(publicSharePath, b.PublicBaseURL, shareToken)
}

// BuildMediaPreviewPath 生成照片预览的相对路径 (用于签名)
func (b *URLBuilder) BuildMediaPreviewPath(mediaUUID string) string {
	return fmt.Sprintf(mediaPreviewPath, b.PublicBaseURL, mediaUUID)
}

// BuildMediaThumbnailPath 生成照片缩略图的相对路径 (用于签名)
func (b *URLBuilder) BuildMediaThumbnailPath(mediaUUID string) string {
	return fmt.Sprintf(mediaThumbnailPath, b.PublicBaseURL, mediaUUID)
}

// BuildMediaOriginalPath 生成照片原始文件的相对路径 (用于签名)
func (b *URLBuilder) BuildMediaOriginalPath(mediaUUID string) string {
	return fmt.Sprintf(mediaOriginalPath, b.PublicBaseURL, mediaUUID)
}

// BuildGroupMediaURL 生成一个安全的、需要访问控制的圈子内部媒体链接。
// 此 URL 指向的端点将在提供内容前验证用户的圈子成员资格。
func (b *URLBuilder) BuildGroupMediaURL(groupUUID, mediaUUID string) string {
	return fmt.Sprintf(groupMediaPath, b.PublicBaseURL, groupUUID, mediaUUID)
}
