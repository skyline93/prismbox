// server/handlers/group/comment_handler.go

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

type CreateCommentInput struct {
	Content         string  `json:"content" binding:"required"`
	ParentCommentID *string `json:"parent_comment_id"`
}

type CommentResponse struct {
	ID         string                      `json:"id"`
	CreatedAt  time.Time                   `json:"created_at"`
	Content    string                      `json:"content"`
	User       handlers.UserSimpleResponse `json:"author"`
	LikesCount int                         `json:"likes_count"`
	Replies    []*CommentResponse          `json:"replies,omitempty"`
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

// [重写] AddComment - 支持回复
// AddComment godoc
// @Summary      为帖子添加评论或回复
// @Description  为一个帖子添加一条新评论，或回复一条已有评论
// @Tags         Posts
// @Accept       json
// @Produce      json
// @Param        postId path string true "帖子的ID"
// @Param        input body CreateCommentInput true "评论内容和可选的父评论ID"
// @Success      200  {object}  core.ApiResponse{data=CommentResponse} "评论成功"
// @Failure      400  {object}  core.ApiResponse "输入无效"
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
		PostID:  uint(postID),
		UserID:  userID,
		Content: input.Content,
	}

	// 如果是回复，处理父评论ID
	if input.ParentCommentID != nil {
		parentID, err := strconv.ParseUint(*input.ParentCommentID, 10, 64)
		if err != nil {
			core.Error(c, "Invalid parent comment ID")
			return
		}
		// 验证父评论是否存在且属于同一个帖子
		var parentComment models.Comment
		if err := h.DB.First(&parentComment, uint(parentID)).Error; err != nil || parentComment.PostID != uint(postID) {
			core.Error(c, "Parent comment not found or does not belong to this post")
			return
		}
		comment.ParentCommentID = &parentComment.ID
	}

	if err := h.DB.Create(&comment).Error; err != nil {
		core.Error(c, "Failed to add comment")
		return
	}

	h.DB.Preload("User").Preload("Likes").First(&comment, comment.ID)

	response := CommentResponse{
		ID:         strconv.FormatUint(uint64(comment.ID), 10),
		CreatedAt:  comment.CreatedAt,
		Content:    comment.Content,
		User:       handlers.ToUserSimpleResponse(comment.User, h.AvatarBaseURL),
		LikesCount: len(comment.Likes),
		Replies:    []*CommentResponse{}, // 新评论没有回复
	}

	core.Success(c, "Comment added successfully", response)
}

// [重写] GetComments - 返回树状结构
// GetComments godoc
// @Summary      获取帖子的评论列表（树状结构）
// @Description  获取一个帖子的所有评论，并组织成父子关系的树状结构
// @Tags         Posts
// @Produce      json
// @Param        postId path string true "帖子的ID"
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

	if _, err := h.getPostAndCheckMembership(uint(postID), userID); err != nil {
		core.Error(c, err.Error())
		return
	}

	var comments []models.Comment
	err = h.DB.Where("post_id = ?", postID).
		Preload("User").
		Preload("Likes"). // 预加载点赞信息
		Order("created_at asc").
		Find(&comments).Error

	if err != nil {
		core.Error(c, "Failed to fetch comments")
		return
	}

	// 核心逻辑：将扁平列表转换为树状结构
	commentMap := make(map[uint]*CommentResponse)
	var rootComments []*CommentResponse

	// 第一遍：创建所有评论的 Response 对象并存入 map
	for _, cm := range comments {
		commentMap[cm.ID] = &CommentResponse{
			ID:         strconv.FormatUint(uint64(cm.ID), 10),
			CreatedAt:  cm.CreatedAt,
			Content:    cm.Content,
			User:       handlers.ToUserSimpleResponse(cm.User, h.AvatarBaseURL),
			LikesCount: len(cm.Likes),
			Replies:    []*CommentResponse{},
		}
	}

	// 第二遍：构建父子关系
	for _, cm := range comments {
		if cm.ParentCommentID != nil {
			// 如果是子评论，找到父评论并添加到其 Replies 列表中
			if parent, ok := commentMap[*cm.ParentCommentID]; ok {
				parent.Replies = append(parent.Replies, commentMap[cm.ID])
			}
		} else {
			// 如果是顶级评论，直接添加到根列表
			rootComments = append(rootComments, commentMap[cm.ID])
		}
	}

	core.Success(c, "Comments retrieved successfully", rootComments)
}

// DeleteComment godoc
// @Summary      删除评论
// @Description  删除一条评论，仅限评论发布者或圈主/管理员操作
// @Tags         Comments
// @Produce      json
// @Param        commentId path string true "评论的ID"
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
