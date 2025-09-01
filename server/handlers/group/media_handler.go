// server/handlers/group/media_handler.go
// This file contains handlers for managing media shared within a group.

package group

// import (
// 	"server/core"
// 	"server/models"
// 	"strconv"

// 	"github.com/gin-gonic/gin"
// 	"gorm.io/gorm"
// 	"server/handlers"
// )

// type GroupMediaWithCounts struct {
// 	models.GroupMedia
// 	LikesCount    int64 `gorm:"column:likes_count"`
// 	CommentsCount int64 `gorm:"column:comments_count"`
// }

// // ShareMediaToGroup godoc
// // @Summary      分享媒体到圈子
// // @Description  将当前用户拥有的一个或多个媒体分享到指定的圈子
// // @Tags         Groups
// // @Accept       json
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Param        input body ShareMediaInput true "要分享的媒体UUID列表和可选的说明"
// // @Success      200  {object}  core.ApiResponse "媒体分享成功"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误、照片未找到等"
// // @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/media [post]
// func (h *GroupHandler) ShareMediaToGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 1. 权限校验：确保用户是圈子成员
// 	// Using a helper method from group_helpers.go
// 	if _, err := h.getUserRoleInGroup(groupUUID, userID); err != nil {
// 		core.Error(c, "Group not found or you are not a member")
// 		return
// 	}

// 	// Using a helper method from group_helpers.go
// 	group, err := h.getGroupByUUID(groupUUID)
// 	if err != nil {
// 		core.Error(c, "Group not found")
// 		return
// 	}

// 	var input ShareMediaInput
// 	if err := c.ShouldBindJSON(&input); err != nil {
// 		core.Error(c, "Invalid input: "+err.Error())
// 		return
// 	}
// 	if len(input.MediaUUIDs) == 0 {
// 		core.Error(c, "media_uuids cannot be empty")
// 		return
// 	}

// 	// 2. 关键安全校验：确保要分享的照片属于当前用户
// 	var userMedia []models.Media
// 	if err := h.DB.Where("uuid IN ? AND user_id = ?", input.MediaUUIDs, userID).Find(&userMedia).Error; err != nil {
// 		core.Error(c, "Failed to verify media ownership")
// 		return
// 	}

// 	// 检查是否有部分照片不属于该用户
// 	if len(userMedia) != len(input.MediaUUIDs) {
// 		core.Error(c, "Some media were not found or you do not have permission to share them")
// 		return
// 	}

// 	// 3. 构造 GroupMedia 记录并批量插入
// 	var groupMediaRecords []models.GroupMedia
// 	for _, media := range userMedia {
// 		groupMediaRecords = append(groupMediaRecords, models.GroupMedia{
// 			GroupID:    group.ID,
// 			MediaUUID:  media.UUID,
// 			UploaderID: userID,
// 			Caption:    input.Caption,
// 		})
// 	}

// 	if err := h.DB.Create(&groupMediaRecords).Error; err != nil {
// 		core.Error(c, "Failed to share media to the group")
// 		return
// 	}

// 	core.Success(c, "Media shared successfully", nil)
// }

// // GetGroupFeed godoc
// // @Summary      获取圈子 Feed 流
// // @Description  分页获取圈子中的媒体分享，按分享时间倒序排列，包含点赞/评论数
// // @Tags         Groups
// // @Produce      json
// // @Param        uuid path string true "圈子的UUID" format(uuid)
// // @Param        page query int false "页码" default(1)
// // @Param        limit query int false "每页数量" default(20)
// // @Success      200  {object}  core.ApiResponse{data=[]GroupFeedItemResponse} "成功获取Feed流"
// // @Failure      400  {object}  core.ApiResponse "请求参数错误"
// // @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// // @Security     BearerAuth
// // @Router       /groups/{uuid}/media [get]
// func (h *GroupHandler) GetGroupFeed(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupUUID := c.Param("uuid")

// 	// 1. 权限校验：确保用户是圈子成员
// 	// (假设您有一个名为 IsUserMemberOfGroup 的辅助函数)
// 	isMember, err := IsUserMemberOfGroup(h.DB, groupUUID, userID)
// 	if err != nil {
// 		core.Error(c, "Error checking group membership")
// 		return
// 	}
// 	if !isMember {
// 		core.Error(c, "Group not found or you are not a member")
// 		return
// 	}

// 	// 2. 分页参数处理
// 	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
// 	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
// 	if page < 1 {
// 		page = 1
// 	}
// 	if limit <= 0 {
// 		limit = 20
// 	}
// 	offset := (page - 1) * limit

// 	// 3. 高性能查询：使用子查询在一次查询中计算出点赞和评论数
// 	var results []GroupMediaWithCounts

// 	subQueryLikes := h.DB.Model(&models.Like{}).Select("count(*)").Where("likes.group_media_id = group_media.id")
// 	subQueryComments := h.DB.Model(&models.Comment{}).Select("count(*)").Where("comments.group_media_id = group_media.id")

// 	err = h.DB.Table("group_media").
// 		Select("group_media.*, (?) as likes_count, (?) as comments_count", subQueryLikes, subQueryComments).
// 		Joins("JOIN groups ON groups.id = group_media.group_id").
// 		Where("groups.uuid = ?", groupUUID).
// 		Order("group_media.created_at desc").
// 		Limit(limit).
// 		Offset(offset).
// 		Preload("Uploader"). // 预加载完整的 User 对象，包括新加的 Avatar 字段
// 		Find(&results).Error

// 	if err != nil {
// 		core.Error(c, "Failed to fetch group feed: "+err.Error())
// 		return
// 	}

// 	if len(results) == 0 {
// 		core.Success(c, "Group feed is empty", []GroupFeedItemResponse{})
// 		return
// 	}

// 	// 4. 批量获取媒体详情
// 	mediaUUIDs := make([]string, len(results))
// 	for i, res := range results {
// 		mediaUUIDs[i] = res.MediaUUID
// 	}

// 	mediaDetailsMap := make(map[string]handlers.MediaResponse)
// 	if len(mediaUUIDs) > 0 {
// 		var mediaList []models.Media
// 		h.DB.Where("uuid IN ?", mediaUUIDs).Find(&mediaList)
// 		for _, m := range mediaList {
// 			// 在这里填充媒体详情，包含宽高
// 			mediaDetailsMap[m.UUID] = handlers.MediaResponse{
// 				UUID:         m.UUID,
// 				Filename:     m.Filename,
// 				ItemType:     m.ItemType,
// 				Width:        m.Width,
// 				Height:       m.Height,
// 				CreatedAt:    m.CreatedAt,
// 				ThumbnailURL: "http://localhost:8080/media/" + m.UUID + "/thumbnail", // TODO: 使用 URL Builder
// 				PreviewURL:   "http://localhost:8080/media/" + m.UUID + "/preview",   // TODO: 使用 URL Builder
// 				DownloadURL:  "http://localhost:8080/media/" + m.UUID + "/original",  // TODO: 使用 URL Builder
// 			}
// 		}
// 	}

// 	// 5. 组装最终响应
// 	response := make([]GroupFeedItemResponse, len(results))
// 	baseURL := "http://localhost:8080" // TODO: 从配置中读取

// 	for i, res := range results {
// 		var uploaderInfo UploaderInfo
// 		if res.Uploader.ID != 0 {
// 			avatarURL := ""
// 			// 只有当用户设置了头像时才生成URL
// 			if res.Uploader.Avatar != "" {
// 				avatarURL = baseURL + "/avatars/" + res.Uploader.Avatar // TODO: 使用 URL Builder
// 			}
// 			uploaderInfo = UploaderInfo{
// 				UserID:    res.Uploader.ID,
// 				Username:  res.Uploader.Username,
// 				AvatarURL: avatarURL,
// 			}
// 		}

// 		response[i] = GroupFeedItemResponse{
// 			GroupMediaID:  res.ID,
// 			Caption:       res.Caption,
// 			SharedAt:      res.CreatedAt,
// 			LikesCount:    res.LikesCount,
// 			CommentsCount: res.CommentsCount,
// 			Uploader:      uploaderInfo,
// 			MediaDetails:  mediaDetailsMap[res.MediaUUID],
// 		}
// 	}

// 	core.Success(c, "Group feed retrieved successfully", response)
// }

// // IsUserMemberOfGroup 是一个辅助函数，用于检查用户是否是圈子成员
// func IsUserMemberOfGroup(db *gorm.DB, groupUUID string, userID uint) (bool, error) {
// 	var count int64
// 	err := db.Model(&models.GroupMember{}).
// 		Joins("JOIN groups ON groups.id = group_members.group_id").
// 		Where("groups.uuid = ? AND group_members.user_id = ?", groupUUID, userID).
// 		Count(&count).Error
// 	if err != nil {
// 		return false, err
// 	}
// 	return count > 0, nil
// }

// // RemoveMediaFromGroup godoc
// // @Summary      从圈子移除照片
// // @Description  从圈子中移除一张照片，仅限照片上传者或圈主/管理员操作
// // @Tags         Groups
// // @Produce      json
// // @Param        groupMediaId path int true "圈子媒体的ID (group_media_id)"
// // @Success      200  {object}  core.ApiResponse "照片移除成功"
// // @Failure      403  {object}  core.ApiResponse "无权限操作"
// // @Security     BearerAuth
// // @Router       /group-media/{groupMediaId} [delete]
// func (h *GroupHandler) RemoveMediaFromGroup(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	groupMediaID, err := strconv.ParseUint(c.Param("groupMediaId"), 10, 64)
// 	if err != nil {
// 		core.Error(c, "Invalid group media ID")
// 		return
// 	}

// 	// Using a helper method from group_helpers.go
// 	groupMedia, err := h.getGroupMediaAndCheckMembership(uint(groupMediaID), userID)
// 	if err != nil {
// 		core.Error(c, err.Error())
// 		return
// 	}

// 	// Using helper methods from group_helpers.go
// 	group, _ := h.getGroupByID(groupMedia.GroupID)
// 	userRole, _ := h.getUserRoleInGroup(group.UUID, userID)

// 	// 权限校验：必须是上传者或圈主/管理员
// 	if groupMedia.UploaderID != userID && userRole != models.RoleOwner && userRole != models.RoleAdmin {
// 		c.JSON(403, core.ApiResponse{Code: 1, Message: "You do not have permission to remove this media"})
// 		return
// 	}

// 	if err := h.DB.Delete(&models.GroupMedia{}, groupMedia.ID).Error; err != nil {
// 		core.Error(c, "Failed to remove media from group")
// 		return
// 	}

// 	core.Success(c, "Media removed from group successfully", nil)
// }
