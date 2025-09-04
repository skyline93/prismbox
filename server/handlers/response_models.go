// server/handlers/response_models.go
package handlers

import (
	"server/models"

	"gorm.io/gorm"
)

// UserSimpleResponse 是用于API响应的简化版用户信息，隐藏了敏感数据
type UserSimpleResponse struct {
	UserID    uint   `json:"user_id"`
	Username  string `json:"username"`
	AvatarURL string `json:"avatar_url"`
}

// ToUserSimpleResponse 是一个转换函数，将 models.User 转换为 UserSimpleResponse
func ToUserSimpleResponse(user models.User, avatorBaseUrl string) UserSimpleResponse {
	return UserSimpleResponse{
		UserID:    user.ID,
		Username:  user.Username,
		AvatarURL: avatorBaseUrl + user.Avatar,
	}
}

// // MediaResponse 是用于API响应的媒体信息结构
// type MediaResponse struct {
// 	UUID         string             `json:"uuid"`
// 	ItemType     constant.MediaType `json:"item_type"`
// 	Width        int                `json:"width"`
// 	Height       int                `json:"height"`
// 	CreatedAt    time.Time          `json:"created_at"`
// 	ThumbnailURL string             `json:"thumbnail_url"`
// 	PreviewURL   string             `json:"preview_url"`
// 	DownloadURL  string             `json:"download_url"`
// }

// GetMediaDetailsMap 批量获取媒体详情并返回一个以UUID为键的map
func GetMediaDetailsMap(db *gorm.DB, mediaUUIDs []string) map[string]MediaResponse {
	mediaDetailsMap := make(map[string]MediaResponse)
	if len(mediaUUIDs) == 0 {
		return mediaDetailsMap
	}

	var mediaList []models.Media
	db.Where("uuid IN ?", mediaUUIDs).Find(&mediaList)

	// TODO: 从配置中读取 BaseURL
	baseURL := "http://localhost:8080/media/"

	for _, m := range mediaList {
		mediaDetailsMap[m.UUID] = MediaResponse{
			UUID:         m.UUID,
			ItemType:     m.ItemType,
			Width:        m.Width,
			Height:       m.Height,
			CreatedAt:    m.CreatedAt,
			ThumbnailURL: baseURL + m.UUID + "/thumbnail",
			PreviewURL:   baseURL + m.UUID + "/preview",
			DownloadURL:  baseURL + m.UUID + "/original",
		}
	}
	return mediaDetailsMap
}
