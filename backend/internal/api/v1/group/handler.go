package group

import (
	"errors"
	"strconv"

	"github.com/album/backend/internal/api/dto"
	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/response"
	groupservice "github.com/album/backend/internal/service/group"
	"github.com/gin-gonic/gin"
)

// Handler 圈子处理器
type Handler struct {
	groupService groupservice.Service
}

// NewHandler 创建圈子处理器
func NewHandler(groupService groupservice.Service) *Handler {
	return &Handler{
		groupService: groupService,
	}
}

// CreateGroup 创建圈子
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

// AddComment 添加评论
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
func (h *Handler) GetGroupMediaThumbnail(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	_ = c.Param("media_uuid") // TODO: 使用mediaUUID

	// 检查用户是否是圈子成员
	err := h.groupService.CheckGroupMembership(c.Request.Context(), groupUUID, userID)
	if err != nil {
		response.Error(c, "Permission denied or group not found")
		return
	}

	// TODO: 实现媒体文件下载逻辑
	// 这里需要调用media service来获取文件
	response.Error(c, "Not implemented yet")
}

// GetGroupMediaPreview 获取圈子媒体预览图
func (h *Handler) GetGroupMediaPreview(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	groupUUID := c.Param("uuid")
	_ = c.Param("media_uuid") // TODO: 使用mediaUUID

	// 检查用户是否是圈子成员
	err := h.groupService.CheckGroupMembership(c.Request.Context(), groupUUID, userID)
	if err != nil {
		response.Error(c, "Permission denied or group not found")
		return
	}

	// TODO: 实现媒体文件下载逻辑
	// 这里需要调用media service来获取文件
	response.Error(c, "Not implemented yet")
}
