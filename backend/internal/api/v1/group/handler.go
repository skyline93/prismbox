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

// CreateGroup creates a group.
// @Summary      Create group
// @Description  Creates a new group (authentication required)
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.CreateGroupInput true "Group payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetMyGroups lists groups the current user belongs to.
// @Summary      List my groups
// @Description  Lists all groups the current user is a member of (authentication required)
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetGroupDetails returns group details.
// @Summary      Get group details
// @Description  Returns details for a group (authentication required; must be a member)
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// UpdateGroup updates group name and description.
// @Summary      Update group
// @Description  Updates name and description (authentication required; owner or admin)
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Param        input body dto.UpdateGroupInput true "Update payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      403 {object} response.ApiResponse "Forbidden; must be owner or admin"
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

// JoinGroup joins a group using an invite code.
// @Summary      Join group
// @Description  Joins a group with an invitation code (authentication required)
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.JoinGroupInput true "Invite code"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Invalid code, expired, or already a member"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// LeaveGroup leaves a group.
// @Summary      Leave group
// @Description  Leaves the specified group (authentication required; owner cannot leave)
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found, not a member, or owner"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetGroupMembers lists members of a group.
// @Summary      List group members
// @Description  Lists all members (authentication required; must be a member)
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// CreateInvite creates a new invite code for a group.
// @Summary      Create invite code
// @Description  Creates an invitation code (authentication required; owner or admin)
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      403 {object} response.ApiResponse "Forbidden; must be owner or admin"
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

// RemoveMember removes a member from a group.
// @Summary      Remove member
// @Description  Removes a member (authentication required; owner or admin; cannot remove owner)
// @Tags         Groups
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Param        userId path string true "User ID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group/user not found or cannot remove owner"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      403 {object} response.ApiResponse "Forbidden; must be owner or admin"
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

// CreatePost creates a post in a group.
// @Summary      Create post
// @Description  Creates a post with shared media (authentication required; must be a member)
// @Tags         Posts
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Param        input body dto.CreatePostInput true "Post payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found, not a member, or media error"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetGroupFeed returns the group post feed.
// @Summary      Get group feed
// @Description  Paginated post feed for a group (authentication required; must be a member)
// @Tags         Posts
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Param        page query int false "Page number (default 1)" default(1) minimum(1)
// @Param        limit query int false "Page size (default 20)" default(20) minimum(1)
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Group not found or not a member"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetMyFeed returns a merged feed from all groups the user belongs to.
// @Summary      Get merged feed
// @Description  Posts from all member groups, newest first, paginated (authentication required)
// @Tags         Posts
// @Produce      json
// @Security     BearerAuth
// @Param        page query int false "Page number (default 1)" default(1) minimum(1)
// @Param        limit query int false "Page size (default 20)" default(20) minimum(1)
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// AddComment adds a comment to a post.
// @Summary      Add comment
// @Description  Adds a comment or reply (authentication required; must be a member)
// @Tags         Comments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        postId path string true "Post ID"
// @Param        input body dto.CreateCommentInput true "Comment payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Post not found or not a member"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetComments lists comments on a post.
// @Summary      List comments
// @Description  Lists all comments for a post (authentication required; must be a member)
// @Tags         Comments
// @Produce      json
// @Security     BearerAuth
// @Param        postId path string true "Post ID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Post not found or not a member"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// DeleteComment deletes a comment.
// @Summary      Delete comment
// @Description  Deletes a comment (authentication required; author or group admin)
// @Tags         Comments
// @Produce      json
// @Security     BearerAuth
// @Param        commentId path string true "Comment ID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Comment not found, not a member, or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetGroupMediaThumbnail serves a thumbnail for group media.
// @Summary      Get group media thumbnail
// @Description  Thumbnail bytes (authentication required; must be a member)
// @Tags         Groups
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Param        media_uuid path string true "Media UUID"
// @Success      200 "Thumbnail bytes"
// @Failure      400 {object} response.ApiResponse "Media not found, forbidden, or not ready"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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
	h.serveMediaFile(c, storageKey, mimeType, media.LocalPoolUUID)
}

// GetGroupMediaPreview serves a preview image for group media.
// @Summary      Get group media preview
// @Description  Preview image bytes (authentication required; must be a member)
// @Tags         Groups
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "Group UUID"
// @Param        media_uuid path string true "Media UUID"
// @Success      200 "Preview bytes"
// @Failure      400 {object} response.ApiResponse "Media not found, forbidden, or not ready"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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
	h.serveMediaFile(c, storageKey, mimeType, media.LocalPoolUUID)
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

func (h *Handler) serveMediaFile(c *gin.Context, storageKey, mimeType string, poolID string) {
	reader, err := h.mediaService.GetFileReader(c.Request.Context(), storageKey, poolID)
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
