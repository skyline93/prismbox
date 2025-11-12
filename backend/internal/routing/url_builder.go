package routing

import "fmt"

// URLBuilder URL构建器
type URLBuilder struct {
	PublicBaseURL string
}

// NewURLBuilder 创建URL构建器
func NewURLBuilder(baseURL string) *URLBuilder {
	return &URLBuilder{PublicBaseURL: baseURL}
}

// BuildGroupMediaURL 构建圈子媒体URL
func (b *URLBuilder) BuildGroupMediaURL(groupUUID, mediaUUID string) string {
	return fmt.Sprintf("%s/api/v1/groups/%s/media/%s/thumbnail", b.PublicBaseURL, groupUUID, mediaUUID)
}

// BuildPublicShareURL 构建公开分享URL
func (b *URLBuilder) BuildPublicShareURL(shareToken string) string {
	return fmt.Sprintf("%s/s/%s", b.PublicBaseURL, shareToken)
}

// BuildMediaPreviewPath 构建媒体预览路径
func (b *URLBuilder) BuildMediaPreviewPath(mediaUUID string) string {
	return fmt.Sprintf("%s/api/v1/media/%s/download/preview", b.PublicBaseURL, mediaUUID)
}

