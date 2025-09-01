// server/handlers/group/comment_handler.go
// [MODIFIED] 这个文件现在处理针对“帖子”的评论

package group

import (
	"errors"
	"server/core"
	"server/handlers"
	"server/models"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// CreateCommentInput 定义了创建评论的输入
type CreateCommentInput struct {
	Content string `json:"content" binding:"required"`
}

// CommentResponse 定义了返回给前端的评论结构
type CommentResponse struct {
	ID        uint                        `json:"id"`
	CreatedAt time.Time                   `json:"created_at"`
	Content   string                      `json:"content"`
	User      handlers.UserSimpleResponse `json:"user"`
}

// getPostAndCheckMembership 是一个新的辅助函数，用于获取帖子并验证用户成员资格
func (h *GroupHandler) getPostAndCheckMembership(postID uint, userID uint) (*models.GroupPost, error) {
	var post models.GroupPost
	if err := h.DB.First(&post, postID).Error; err != nil {
		return nil, errors.New("post not found")
	}

	// 检查用户是否是该帖子所在圈子的成员
	var memberCount int64
	h.DB.Model(&models.GroupMember{}).
		Where("group_id = ? AND user_id = ?", post.GroupID, userID).
		Count(&memberCount)

	if memberCount == 0 {
		return nil, errors.New("you are not a member of this group")
	}
	return &post, nil
}

// AddComment godoc
// @Summary      为帖子添加评论
// @Description  为一个帖子添加一条新评论
// @Tags         Posts
// @Accept       json
// @Produce      json
// @Param        postId path int true "帖子的ID"
// @Param        input body CreateCommentInput true "评论内容"
// @Success      201  {object}  core.ApiResponse{data=CommentResponse} "评论成功"
// @Failure      403  {object}  core.ApiResponse "无权限或帖子不存在"
// @Security     BearerAuth
// @Router       /posts/{postId}/comments [post]
func (h *GroupHandler) AddComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postID, err := strconv.ParseUint(c.Param("postId"), 10, 64)
	if err != nil {
		core.Error(c, "Invalid post ID")
		return
	}

	// [MODIFIED] 权限校验：确保用户是该帖子所在圈子的成员
	if _, err := h.getPostAndCheckMembership(uint(postID), userID); err != nil {
		core.Error(c, err.Error())
		return
	}

	var input CreateCommentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	comment := models.Comment{
		PostID:  uint(postID), // [MODIFIED] 使用 PostID
		UserID:  userID,
		Content: input.Content,
	}

	if err := h.DB.Create(&comment).Error; err != nil {
		core.Error(c, "Failed to add comment")
		return
	}

	// 查询完整的 user 信息以便返回
	h.DB.Preload("User").First(&comment, comment.ID)

	core.Success(c, "Comment added successfully", CommentResponse{
		ID:        comment.ID,
		CreatedAt: comment.CreatedAt,
		Content:   comment.Content,
		User:      handlers.ToUserSimpleResponse(comment.User), // [MODIFIED] 使用统一的响应模型
	})
}

// GetComments godoc
// @Summary      获取帖子的评论列表
// @Description  获取一个帖子的所有评论
// @Tags         Posts
// @Produce      json
// @Param        postId path int true "帖子的ID"
// @Success      200  {object}  core.ApiResponse{data=[]CommentResponse} "获取成功"
// @Failure      403  {object}  core.ApiResponse "无权限或帖子不存在"
// @Security     BearerAuth
// @Router       /posts/{postId}/comments [get]
func (h *GroupHandler) GetComments(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	postID, err := strconv.ParseUint(c.Param("postId"), 10, 64)
	if err != nil {
		core.Error(c, "Invalid post ID")
		return
	}

	// [MODIFIED] 权限校验
	if _, err := h.getPostAndCheckMembership(uint(postID), userID); err != nil {
		core.Error(c, err.Error())
		return
	}

	var comments []models.Comment
	err = h.DB.Where("post_id = ?", postID). // [MODIFIED] 使用 post_id 查询
							Preload("User").
							Order("created_at asc"). // 通常评论按时间正序排列
							Find(&comments).Error
	if err != nil {
		core.Error(c, "Failed to fetch comments")
		return
	}

	response := make([]CommentResponse, len(comments))
	for i, cm := range comments {
		response[i] = CommentResponse{
			ID:        cm.ID,
			CreatedAt: cm.CreatedAt,
			Content:   cm.Content,
			User:      handlers.ToUserSimpleResponse(cm.User), // [MODIFIED] 使用统一的响应模型
		}
	}

	core.Success(c, "Comments retrieved successfully", response)
}

// DeleteComment godoc
// @Summary      删除评论
// @Description  删除一条评论，仅限评论发布者或圈主/管理员操作
// @Tags         Comments
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
	if err := h.DB.Preload("Post.Group").First(&comment, uint(commentID)).Error; err != nil {
		core.Error(c, "Comment not found")
		return
	}

	// [MODIFIED] 权限校验逻辑更新
	// 1. 检查用户是否是圈子成员 (通过 Post -> Group)
	isMember, _ := IsUserMemberOfGroup(h.DB, comment.Post.Group.UUID, userID)
	if !isMember {
		core.Error(c, "You are not a member of this group")
		return
	}

	// 2. 检查用户是否有删除权限 (评论者本人 或 圈主/管理员)
	userRole, _ := h.getUserRoleInGroup(comment.Post.Group.UUID, userID)
	if comment.UserID != userID && userRole != models.RoleOwner && userRole != models.RoleAdmin {
		core.Error(c, "You do not have permission to delete this comment")
		return
	}

	if err := h.DB.Delete(&comment).Error; err != nil {
		core.Error(c, "Failed to delete comment")
		return
	}

	core.Success(c, "Comment deleted successfully", nil)
}

// IsUserMemberOfGroup 是一个辅助函数，用于检查用户是否是圈子成员
func IsUserMemberOfGroup(db *gorm.DB, groupUUID string, userID uint) (bool, error) {
	var count int64
	err := db.Model(&models.GroupMember{}).
		Joins("JOIN groups ON groups.id = group_members.group_id").
		Where("groups.uuid = ? AND group_members.user_id = ?", groupUUID, userID).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}
