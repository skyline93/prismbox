package group

import (
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"

	"github.com/album/backend/internal/api/dto"
	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/response"
	"github.com/album/backend/internal/database/models"
	groupservice "github.com/album/backend/internal/service/group"
	mediaservice "github.com/album/backend/internal/service/media"
	"github.com/gin-gonic/gin"
)

// Handler 圈子处理器
type Handler struct {
	groupService groupservice.Service
	mediaService mediaservice.Service
}

// NewHandler 创建圈子处理器
func NewHandler(groupService groupservice.Service, mediaService mediaservice.Service) *Handler {
	return &Handler{
		groupService: groupService,
		mediaService: mediaService,
	}
}

// CreateGroup 创建圈子
// @Summary      创建圈子
// @Description  创建一个新的圈子（需要认证）
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.CreateGroupInput true "圈子信息"
// @Success      200 {object} response.ApiResponse "创建成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups [post]
func (h *Handler) CreateGroup(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	var input dto.CreateGroupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	group, err := h.groupService.CreateGroup(c.Request.Context(), userID, input.Name, input.Description)
	if err != nil {
		response.Error(c, "Failed to create group: "+err.Error())
		return
	}

	response.Success(c, "Group created successfully", group)
}

// GetMyGroups 获取我加入的圈子列表
// @Summary      获取我的圈子列表
// @Description  获取当前用户加入的所有圈子列表（需要认证）
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups [get]
func (h *Handler) GetMyGroups(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groups, err := h.groupService.GetMyGroups(c.Request.Context(), userID)
	if err != nil {
		response.Error(c, "Failed to fetch groups: "+err.Error())
		return
	}

	response.Success(c, "Groups retrieved successfully", groups)
}

// GetGroupDetails 获取圈子详情
// @Summary      获取圈子详情
// @Description  获取指定圈子的详细信息（需要认证，必须是圈子成员）
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid} [get]
func (h *Handler) GetGroupDetails(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	details, err := h.groupService.GetGroupDetails(c.Request.Context(), groupUUID, userID)
	if err != nil {
		if errors.Is(err, groupservice.ErrGroupNotFound) || errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, "Group not found or permission denied")
			return
		}
		response.Error(c, "Failed to get group details: "+err.Error())
		return
	}

	response.Success(c, "Group details retrieved successfully", details)
}

// UpdateGroup 更新圈子信息
// @Summary      更新圈子信息
// @Description  更新圈子的名称和描述（需要认证，必须是圈子管理员或所有者）
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Param        input body dto.UpdateGroupInput true "更新信息"
// @Success      200 {object} response.ApiResponse "更新成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Failure      403 {object} response.ApiResponse "权限不足，必须是管理员或所有者"
// @Router       /groups/{uuid} [put]
func (h *Handler) UpdateGroup(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	var input dto.UpdateGroupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	group, err := h.groupService.UpdateGroup(c.Request.Context(), groupUUID, userID, input.Name, input.Description)
	if err != nil {
		if errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, "Group not found or permission denied")
			return
		}
		if errors.Is(err, groupservice.ErrPermissionDenied) {
			c.JSON(403, response.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
			return
		}
		response.Error(c, "Failed to update group: "+err.Error())
		return
	}

	response.Success(c, "Group updated successfully", group)
}

// JoinGroup 使用邀请码加入圈子
// @Summary      加入圈子
// @Description  使用邀请码加入圈子（需要认证）
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.JoinGroupInput true "邀请码"
// @Success      200 {object} response.ApiResponse "加入成功"
// @Failure      400 {object} response.ApiResponse "邀请码无效、已过期或已是成员"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/join [post]
func (h *Handler) JoinGroup(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	var input dto.JoinGroupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	group, err := h.groupService.JoinGroup(c.Request.Context(), userID, input.Code)
	if err != nil {
		if errors.Is(err, groupservice.ErrInvalidInviteCode) {
			response.Error(c, "Invalid invitation code")
			return
		}
		if errors.Is(err, groupservice.ErrInviteCodeExpired) {
			response.Error(c, "Invitation code has expired")
			return
		}
		if errors.Is(err, groupservice.ErrAlreadyMember) {
			response.Error(c, "You are already a member of this group")
			return
		}
		response.Error(c, "Failed to join group: "+err.Error())
		return
	}

	response.Success(c, "Successfully joined the group", group)
}

// LeaveGroup 退出圈子
// @Summary      退出圈子
// @Description  退出指定的圈子（需要认证，所有者不能退出）
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Success      200 {object} response.ApiResponse "退出成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在、不是成员或是所有者"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid}/leave [post]
func (h *Handler) LeaveGroup(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	err := h.groupService.LeaveGroup(c.Request.Context(), groupUUID, userID)
	if err != nil {
		if errors.Is(err, groupservice.ErrGroupNotFound) || errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, "Group not found or you are not a member")
			return
		}
		if errors.Is(err, groupservice.ErrOwnerCannotLeave) {
			response.Error(c, "Owner cannot leave the group. Please delete the group or transfer ownership first.")
			return
		}
		response.Error(c, "Failed to leave group: "+err.Error())
		return
	}

	response.Success(c, "Successfully left the group", nil)
}

// GetGroupMembers 获取圈子成员列表
// @Summary      获取圈子成员列表
// @Description  获取指定圈子的所有成员列表（需要认证，必须是圈子成员）
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid}/members [get]
func (h *Handler) GetGroupMembers(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	members, err := h.groupService.GetGroupMembers(c.Request.Context(), groupUUID, userID)
	if err != nil {
		if errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, "Group not found or permission denied")
			return
		}
		response.Error(c, "Failed to fetch group members: "+err.Error())
		return
	}

	response.Success(c, "Group members retrieved successfully", members)
}

// CreateInvite 创建邀请码
// @Summary      创建邀请码
// @Description  为圈子创建新的邀请码（需要认证，必须是圈子管理员或所有者）
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Success      200 {object} response.ApiResponse "创建成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Failure      403 {object} response.ApiResponse "权限不足，必须是管理员或所有者"
// @Router       /groups/{uuid}/members/invite [post]
func (h *Handler) CreateInvite(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	invite, err := h.groupService.CreateInvite(c.Request.Context(), groupUUID, userID)
	if err != nil {
		if errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, "Group not found or permission denied")
			return
		}
		if errors.Is(err, groupservice.ErrPermissionDenied) {
			c.JSON(403, response.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
			return
		}
		response.Error(c, "Failed to create invitation")
		return
	}

	response.Success(c, "Invitation created successfully", invite)
}

// RemoveMember 移除成员
// @Summary      移除成员
// @Description  从圈子中移除指定成员（需要认证，必须是圈子管理员或所有者，不能移除所有者）
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Param        userId path string true "用户 ID"
// @Success      200 {object} response.ApiResponse "移除成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在、用户不存在或不能移除所有者"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Failure      403 {object} response.ApiResponse "权限不足，必须是管理员或所有者"
// @Router       /groups/{uuid}/members/{userId} [delete]
func (h *Handler) RemoveMember(c *gin.Context) {
	operatorID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	memberIDStr := c.Param("userId")
	memberID, err := strconv.ParseUint(memberIDStr, 10, 64)
	if err != nil {
		response.Error(c, "Invalid user ID")
		return
	}

	err = h.groupService.RemoveMember(c.Request.Context(), groupUUID, operatorID, uint(memberID))
	if err != nil {
		if errors.Is(err, groupservice.ErrNotMember) || errors.Is(err, groupservice.ErrPermissionDenied) {
			c.JSON(403, response.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
			return
		}
		if errors.Is(err, groupservice.ErrGroupNotFound) {
			response.Error(c, "Group not found")
			return
		}
		if err.Error() == "cannot remove the group owner" {
			response.Error(c, "Cannot remove the group owner")
			return
		}
		response.Error(c, "Failed to remove member")
		return
	}

	response.Success(c, "Member removed successfully", nil)
}

// CreatePost 创建帖子
// @Summary      创建帖子
// @Description  在圈子中创建新帖子，分享媒体（需要认证，必须是圈子成员）
// @Tags         Posts
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Param        input body dto.CreatePostInput true "帖子信息"
// @Success      200 {object} response.ApiResponse "创建成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在、不是成员或媒体不存在"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid}/posts [post]
func (h *Handler) CreatePost(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	var input dto.CreatePostInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	post, err := h.groupService.CreatePost(c.Request.Context(), groupUUID, userID, input.MediaUUIDs, input.Caption)
	if err != nil {
		if errors.Is(err, groupservice.ErrGroupNotFound) || errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, err.Error())
			return
		}
		if errors.Is(err, groupservice.ErrMediaNotFound) || errors.Is(err, groupservice.ErrMediaNotOwned) {
			response.Error(c, "Some media were not found or you do not have permission to share them")
			return
		}
		response.Error(c, "Failed to create post: "+err.Error())
		return
	}

	response.Success(c, "Post created successfully", post)
}

// GetGroupFeed 获取圈子Feed流
// @Summary      获取圈子Feed流
// @Description  获取圈子的帖子Feed流，支持分页（需要认证，必须是圈子成员）
// @Tags         Posts
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Param        page query int false "页码（默认1）" default(1) minimum(1)
// @Param        limit query int false "每页数量（默认20）" default(20) minimum(1)
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      400 {object} response.ApiResponse "圈子不存在或不是成员"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid}/feed [get]
func (h *Handler) GetGroupFeed(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")

	// 解析分页参数
	page := 1
	limit := 20
	if pageStr := c.Query("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	result, err := h.groupService.GetGroupFeed(c.Request.Context(), groupUUID, userID, page, limit)
	if err != nil {
		if errors.Is(err, groupservice.ErrGroupNotFound) || errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, err.Error())
			return
		}
		response.Error(c, "Failed to fetch group feed")
		return
	}

	if len(result.Posts) == 0 {
		response.Success(c, "Feed is empty", []interface{}{})
		return
	}

	response.Success(c, "Feed retrieved successfully", result.Posts)
}

// GetMyFeed 获取全部圈子 Feed 流（当前用户加入的所有圈子的帖子混排）
// @Summary      获取全部圈子 Feed
// @Description  获取当前用户作为成员的所有圈子中的帖子，按发布时间倒序分页（需要认证）
// @Tags         Posts
// @Produce      json
// @Security     BearerAuth
// @Param        page query int false "页码（默认1）" default(1) minimum(1)
// @Param        limit query int false "每页数量（默认20）" default(20) minimum(1)
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/feed [get]
func (h *Handler) GetMyFeed(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	page := 1
	limit := 20
	if pageStr := c.Query("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	result, err := h.groupService.GetMyFeed(c.Request.Context(), userID, page, limit)
	if err != nil {
		response.Error(c, "Failed to fetch feed")
		return
	}

	if len(result.Posts) == 0 {
		response.Success(c, "Feed is empty", []interface{}{})
		return
	}

	response.Success(c, "Feed retrieved successfully", result.Posts)
}

// AddComment 添加评论
// @Summary      添加评论
// @Description  为帖子添加评论，支持回复其他评论（需要认证，必须是圈子成员）
// @Tags         Comments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        postId path string true "帖子 ID"
// @Param        input body dto.CreateCommentInput true "评论内容"
// @Success      200 {object} response.ApiResponse "添加成功"
// @Failure      400 {object} response.ApiResponse "帖子不存在或不是成员"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /posts/{postId}/comments [post]
func (h *Handler) AddComment(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	postIDStr := c.Param("postId")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		response.Error(c, "Invalid post ID")
		return
	}

	var input dto.CreateCommentInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	var parentCommentID *uint
	if input.ParentCommentID != nil {
		parentID, err := strconv.ParseUint(*input.ParentCommentID, 10, 64)
		if err != nil {
			response.Error(c, "Invalid parent comment ID")
			return
		}
		parentIDUint := uint(parentID)
		parentCommentID = &parentIDUint
	}

	comment, err := h.groupService.AddComment(c.Request.Context(), uint(postID), userID, input.Content, parentCommentID)
	if err != nil {
		if errors.Is(err, groupservice.ErrPostNotFound) || errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, err.Error())
			return
		}
		response.Error(c, "Failed to add comment")
		return
	}

	response.Success(c, "Comment added successfully", comment)
}

// GetComments 获取评论列表
// @Summary      获取评论列表
// @Description  获取帖子的所有评论（需要认证，必须是圈子成员）
// @Tags         Comments
// @Produce      json
// @Security     BearerAuth
// @Param        postId path string true "帖子 ID"
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      400 {object} response.ApiResponse "帖子不存在或不是成员"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /posts/{postId}/comments [get]
func (h *Handler) GetComments(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	postIDStr := c.Param("postId")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		response.Error(c, "Invalid post ID")
		return
	}

	comments, err := h.groupService.GetComments(c.Request.Context(), uint(postID), userID)
	if err != nil {
		if errors.Is(err, groupservice.ErrPostNotFound) || errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, err.Error())
			return
		}
		response.Error(c, "Failed to fetch comments")
		return
	}

	response.Success(c, "Comments retrieved successfully", comments)
}

// DeleteComment 删除评论
// @Summary      删除评论
// @Description  删除指定的评论（需要认证，必须是评论作者或圈子管理员）
// @Tags         Comments
// @Produce      json
// @Security     BearerAuth
// @Param        commentId path string true "评论 ID"
// @Success      200 {object} response.ApiResponse "删除成功"
// @Failure      400 {object} response.ApiResponse "评论不存在、不是成员或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /comments/{commentId} [delete]
func (h *Handler) DeleteComment(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	commentIDStr := c.Param("commentId")
	commentID, err := strconv.ParseUint(commentIDStr, 10, 64)
	if err != nil {
		response.Error(c, "Invalid comment ID")
		return
	}

	err = h.groupService.DeleteComment(c.Request.Context(), uint(commentID), userID)
	if err != nil {
		if errors.Is(err, groupservice.ErrCommentNotFound) {
			response.Error(c, "Comment not found")
			return
		}
		if errors.Is(err, groupservice.ErrNotMember) {
			response.Error(c, "You are not a member of this group")
			return
		}
		if errors.Is(err, groupservice.ErrPermissionDenied) {
			response.Error(c, "You do not have permission to delete this comment")
			return
		}
		response.Error(c, "Failed to delete comment")
		return
	}

	response.Success(c, "Comment deleted successfully", nil)
}

// GetGroupMediaThumbnail 获取圈子媒体缩略图
// @Summary      获取圈子媒体缩略图
// @Description  获取圈子中媒体的缩略图（需要认证，必须是圈子成员）
// @Tags         Groups
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Param        media_uuid path string true "媒体 UUID"
// @Success      200 "缩略图内容"
// @Failure      400 {object} response.ApiResponse "媒体不存在、权限不足或文件未处理完成"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid}/media/{media_uuid}/thumbnail [get]
func (h *Handler) GetGroupMediaThumbnail(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	mediaUUID := c.Param("media_uuid")
	if mediaUUID == "" {
		response.Error(c, "Media UUID is required")
		return
	}

	media, ok := h.authorizeGroupMedia(c, groupUUID, mediaUUID, userID)
	if !ok {
		return
	}

	if media.ProcessingStatus != "COMPLETED" {
		response.Error(c, fmt.Sprintf("Thumbnail is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	storageKey, err := h.mediaService.BuildThumbnailKey(media)
	if err != nil {
		response.Error(c, "Failed to build thumbnail key")
		return
	}

	mimeType := h.mediaService.GetThumbnailMimeType(media)
	h.serveMediaFile(c, storageKey, mimeType)
}

// GetGroupMediaPreview 获取圈子媒体预览图
// @Summary      获取圈子媒体预览图
// @Description  获取圈子中媒体的预览图（需要认证，必须是圈子成员）
// @Tags         Groups
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "圈子 UUID"
// @Param        media_uuid path string true "媒体 UUID"
// @Success      200 "预览图内容"
// @Failure      400 {object} response.ApiResponse "媒体不存在、权限不足或文件未处理完成"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /groups/{uuid}/media/{media_uuid}/preview [get]
func (h *Handler) GetGroupMediaPreview(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	mediaUUID := c.Param("media_uuid")
	if mediaUUID == "" {
		response.Error(c, "Media UUID is required")
		return
	}

	media, ok := h.authorizeGroupMedia(c, groupUUID, mediaUUID, userID)
	if !ok {
		return
	}

	if media.ProcessingStatus != "COMPLETED" {
		response.Error(c, fmt.Sprintf("Preview is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	storageKey, err := h.mediaService.BuildPreviewKey(media)
	if err != nil {
		response.Error(c, "Failed to build preview key")
		return
	}

	mimeType := h.mediaService.GetPreviewMimeType(media)
	h.serveMediaFile(c, storageKey, mimeType)
}

func (h *Handler) authorizeGroupMedia(c *gin.Context, groupUUID, mediaUUID string, userID uint) (*models.Media, bool) {
	// 检查用户是否是圈子成员
	if err := h.groupService.CheckGroupMembership(c.Request.Context(), groupUUID, userID); err != nil {
		response.Error(c, "Permission denied or group not found")
		return nil, false
	}

	media, err := h.groupService.GetGroupMedia(c.Request.Context(), groupUUID, mediaUUID)
	if err != nil {
		switch {
		case errors.Is(err, groupservice.ErrGroupNotFound):
			response.Error(c, "Group not found or permission denied")
		case errors.Is(err, groupservice.ErrGroupMediaNotFound), errors.Is(err, groupservice.ErrMediaNotFound):
			response.Error(c, "Media not found or permission denied")
		default:
			response.Error(c, "Failed to fetch media")
		}
		return nil, false
	}
	return media, true
}

func (h *Handler) serveMediaFile(c *gin.Context, storageKey, mimeType string) {
	reader, err := h.mediaService.GetFileReader(c.Request.Context(), storageKey)
	if err != nil {
		response.Error(c, "File not available on server")
		return
	}
	defer reader.Close()

	contentType := mimeType
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	c.Header("Content-Type", contentType)

	disposition := "inline"
	if !strings.HasPrefix(contentType, "image/") && !strings.HasPrefix(contentType, "video/") {
		disposition = "attachment"
	}
	c.Header("Content-Disposition", fmt.Sprintf("%s; filename=\"%s\"", disposition, getFilename(storageKey)))

	if _, err := io.Copy(c.Writer, reader); err != nil {
		if !c.Writer.Written() {
			response.Error(c, "Failed to serve file")
		}
		return
	}

	c.Status(200)
}

func getFilename(storageKey string) string {
	parts := strings.Split(storageKey, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return storageKey
}
