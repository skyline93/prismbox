// server/handlers/group/comment_handler.go
// This file contains handlers for comments on group media.

package group

import (
	"errors"
	"server/core"
	"server/models"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AddComment godoc
// @Summary      添加评论
// @Description  为圈子中的某个媒体添加一条评论
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Param        groupMediaId path int true "圈子媒体的ID (group_media_id)"
// @Param        input body CreateCommentInput true "评论内容"
// @Success      200  {object}  core.ApiResponse{data=models.Comment} "评论成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误"
// @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// @Security     BearerAuth
// @Router       /group-media/{groupMediaId}/comments [post]
func (h *GroupHandler) AddComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupMediaID, err := strconv.ParseUint(c.Param("groupMediaId"), 10, 64)
	if err != nil {
		core.Error(c, "Invalid group media ID")
		return
	}

	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "User not found")
			return
		}
		core.Error(c, "Database error")
		return
	}

	// 权限校验：确保用户是该媒体所在圈子的成员
	// Using a helper method from group_helpers.go
	_, err = h.getGroupMediaAndCheckMembership(uint(groupMediaID), userID)
	if err != nil {
		core.Error(c, err.Error())
		return
	}

	var input CreateCommentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	comment := models.Comment{
		GroupMediaID: uint(groupMediaID),
		UserID:       userID,
		Content:      input.Content,
	}

	if err := h.DB.Create(&comment).Error; err != nil {
		core.Error(c, "Failed to add comment")
		return
	}

	resp := &CommentResponse{
		ID:        comment.ID,
		CreatedAt: comment.CreatedAt,
		Content:   comment.Content,
		User: UserInfo{
			UserID:   userID,
			Username: user.Username,
		},
	}

	core.Success(c, "Comment added successfully", resp)
}

// GetComments godoc
// @Summary      获取评论列表
// @Description  获取圈子中某个媒体的所有评论
// @Tags         Groups
// @Produce      json
// @Param        groupMediaId path int true "圈子媒体的ID (group_media_id)"
// @Success      200  {object}  core.ApiResponse{data=[]CommentResponse} "获取评论列表成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误"
// @Failure      403  {object}  core.ApiResponse "无权限操作（非圈子成员）"
// @Security     BearerAuth
// @Router       /group-media/{groupMediaId}/comments [get]
func (h *GroupHandler) GetComments(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupMediaID, err := strconv.ParseUint(c.Param("groupMediaId"), 10, 64)
	if err != nil {
		core.Error(c, "Invalid group media ID")
		return
	}

	// Using a helper method from group_helpers.go
	if _, err := h.getGroupMediaAndCheckMembership(uint(groupMediaID), userID); err != nil {
		core.Error(c, err.Error())
		return
	}

	var comments []models.Comment
	err = h.DB.Where("group_media_id = ?", groupMediaID).
		Preload("User"). // 预加载用户信息
		Order("created_at desc").
		Find(&comments).Error
	if err != nil {
		core.Error(c, "Failed to fetch comments")
		return
	}

	// 构建响应 DTO
	response := make([]CommentResponse, len(comments))
	for i, cm := range comments {
		response[i] = CommentResponse{
			ID:        cm.ID,
			CreatedAt: cm.CreatedAt,
			Content:   cm.Content,
			User: UserInfo{
				UserID:   cm.User.ID,
				Username: cm.User.Username,
			},
		}
	}

	core.Success(c, "Comments retrieved successfully", response)
}

// DeleteComment godoc
// @Summary      删除评论
// @Description  删除一条评论，仅限评论发布者或圈主/管理员操作
// @Tags         Groups
// @Produce      json
// @Param        commentId path int true "评论的ID"
// @Success      200  {object}  core.ApiResponse "评论删除成功"
// @Failure      403  {object}  core.ApiResponse "无权限操作"
// @Security     BearerAuth
// @Router       /comments/{commentId} [delete]
func (h *GroupHandler) DeleteComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	commentID, err := strconv.ParseUint(c.Param("commentId"), 10, 64)
	if err != nil {
		core.Error(c, "Invalid comment ID")
		return
	}

	var comment models.Comment
	if err := h.DB.First(&comment, uint(commentID)).Error; err != nil {
		core.Error(c, "Comment not found")
		return
	}

	// Using helper methods from group_helpers.go
	groupMedia, err := h.getGroupMediaAndCheckMembership(comment.GroupMediaID, userID)
	if err != nil {
		core.Error(c, err.Error())
		return
	}

	group, _ := h.getGroupByID(groupMedia.GroupID)
	userRole, _ := h.getUserRoleInGroup(group.UUID, userID)

	// 权限校验：必须是评论发布者或圈主/管理员
	if comment.UserID != userID && userRole != models.RoleOwner && userRole != models.RoleAdmin {
		c.JSON(403, core.ApiResponse{Code: 1, Message: "You do not have permission to delete this comment"})
		return
	}

	if err := h.DB.Delete(&comment).Error; err != nil {
		core.Error(c, "Failed to delete comment")
		return
	}

	core.Success(c, "Comment deleted successfully", nil)
}
