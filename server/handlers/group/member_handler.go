// server/handlers/member_handler.go
// This file contains handlers for group member management, including invites, joins, and removals.

package group

import (
	"math/rand"
	"server/core"
	"server/models"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// inviteCodeCharset 定义了邀请码中可以使用的字符集，移除了容易混淆的 'O' 和 '0'。
const inviteCodeCharset = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"

// seededRand 用于生成随机邀请码。
var seededRand *rand.Rand = rand.New(rand.NewSource(time.Now().UnixNano()))

// generateInviteCode 生成一个指定长度的随机字符串作为邀请码。
func generateInviteCode(length int) string {
	b := make([]byte, length)
	for i := range b {
		b[i] = inviteCodeCharset[seededRand.Intn(len(inviteCodeCharset))]
	}
	return string(b)
}

// GetGroupMembers godoc
// @Summary      获取圈子成员列表
// @Description  获取指定圈子的所有成员及其角色
// @Tags         Groups
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse{data=[]GroupMemberResponse} "成功获取成员列表"
// @Failure      400  {object}  core.ApiResponse "圈子未找到或无权限"
// @Security     BearerAuth
// @Router       /groups/{uuid}/members [get]
func (h *GroupHandler) GetGroupMembers(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")

	// 权限校验：确保用户是圈子成员
	// Using a helper method from group_helpers.go
	if _, err := h.getUserRoleInGroup(groupUUID, userID); err != nil {
		core.Error(c, "Group not found or permission denied")
		return
	}

	var members []GroupMemberResponse
	err := h.DB.Table("group_members").
		Select("group_members.user_id, users.username, group_members.role, group_members.joined_at").
		Joins("JOIN users ON users.id = group_members.user_id").
		Joins("JOIN groups ON groups.id = group_members.group_id").
		Where("groups.uuid = ?", groupUUID).
		Order("group_members.joined_at asc").
		Scan(&members).Error

	if err != nil {
		core.Error(c, "Failed to fetch group members: "+err.Error())
		return
	}

	core.Success(c, "Group members retrieved successfully", members)
}

// CreateInvite godoc
// @Summary      创建邀请码
// @Description  为指定的圈子创建一个有时效性的邀请码，仅限圈主或管理员操作。
// @Tags         Groups
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse{data=models.GroupInvite} "邀请码创建成功"
// @Failure      400  {object}  core.ApiResponse "圈子未找到"
// @Failure      403  {object}  core.ApiResponse "无权限操作"
// @Security     BearerAuth
// @Router       /groups/{uuid}/members/invite [post]
func (h *GroupHandler) CreateInvite(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")

	// 权限校验：必须是 owner 或 admin
	// Using a helper method from group_helpers.go
	role, err := h.getUserRoleInGroup(groupUUID, userID)
	if err != nil {
		core.Error(c, "Group not found or permission denied")
		return
	}
	if role != models.RoleOwner && role != models.RoleAdmin {
		c.JSON(403, core.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
		return
	}

	// Using a helper method from group_helpers.go
	group, err := h.getGroupByUUID(groupUUID)
	if err != nil {
		core.Error(c, "Group not found")
		return
	}

	// 创建邀请码
	invite := models.GroupInvite{
		GroupID:     group.ID,
		CreatedByID: userID,
		Code:        generateInviteCode(8),          // 生成一个8位的邀请码
		ExpiresAt:   time.Now().Add(48 * time.Hour), // 默认48小时后过期
		UsageLimit:  0,                              // 0表示无限制
	}

	if err := h.DB.Create(&invite).Error; err != nil {
		core.Error(c, "Failed to create invitation")
		return
	}

	core.Success(c, "Invitation created successfully", invite)
}

// JoinGroup godoc
// @Summary      使用邀请码加入圈子
// @Description  使用一个有效的邀请码加入对应的圈子
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Param        input body JoinGroupInput true "邀请码"
// @Success      200  {object}  core.ApiResponse{data=models.Group} "成功加入圈子"
// @Failure      400  {object}  core.ApiResponse "邀请码无效、已过期或用户已是成员"
// @Security     BearerAuth
// @Router       /groups/join [post]
func (h *GroupHandler) JoinGroup(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var input JoinGroupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	var invite models.GroupInvite
	// 1. 校验邀请码是否存在
	if err := h.DB.Where("code = ?", input.Code).First(&invite).Error; err != nil {
		core.Error(c, "Invalid invitation code")
		return
	}

	// 2. 校验邀请码是否过期
	if time.Now().After(invite.ExpiresAt) {
		core.Error(c, "Invitation code has expired")
		return
	}

	// 3. 校验用户是否已经是该圈子成员
	var count int64
	h.DB.Model(&models.GroupMember{}).Where("group_id = ? AND user_id = ?", invite.GroupID, userID).Count(&count)
	if count > 0 {
		core.Error(c, "You are already a member of this group")
		return
	}

	// TODO: UsageLimit check and decrement if not 0

	// 4. 将用户加入圈子
	member := models.GroupMember{
		GroupID: invite.GroupID,
		UserID:  userID,
		Role:    models.RoleMember, // 默认角色为 'member'
	}

	if err := h.DB.Create(&member).Error; err != nil {
		core.Error(c, "Failed to join group: "+err.Error())
		return
	}

	// 成功加入后，返回该圈子的信息
	var group models.Group
	// Using a helper method from group_helpers.go
	h.DB.First(&group, invite.GroupID) // Alternatively: h.getGroupByID(invite.GroupID)

	core.Success(c, "Successfully joined the group", group)
}

// RemoveMember godoc
// @Summary      移除成员
// @Description  从圈子中移除一个成员，仅限圈主或管理员操作
// @Tags         Groups
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Param        userId path int true "要移除的用户ID"
// @Success      200  {object}  core.ApiResponse "成员移除成功"
// @Failure      403  {object}  core.ApiResponse "无权限操作"
// @Security     BearerAuth
// @Router       /groups/{uuid}/members/{userId} [delete]
func (h *GroupHandler) RemoveMember(c *gin.Context) {
	operatorID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")
	memberToRemoveID, err := strconv.ParseUint(c.Param("userId"), 10, 64)
	if err != nil {
		core.Error(c, "Invalid user ID")
		return
	}

	// Using a helper method from group_helpers.go
	operatorRole, err := h.getUserRoleInGroup(groupUUID, operatorID)
	if err != nil || (operatorRole != models.RoleOwner && operatorRole != models.RoleAdmin) {
		c.JSON(403, core.ApiResponse{Code: 1, Message: "Permission denied: must be an owner or admin"})
		return
	}

	// Using a helper method from group_helpers.go
	group, err := h.getGroupByUUID(groupUUID)
	if err != nil {
		core.Error(c, "Group not found")
		return
	}

	if group.OwnerID == uint(memberToRemoveID) {
		core.Error(c, "Cannot remove the group owner")
		return
	}

	// 删除成员关系
	result := h.DB.Where("group_id = ? AND user_id = ?", group.ID, memberToRemoveID).Delete(&models.GroupMember{})
	if result.Error != nil {
		core.Error(c, "Failed to remove member")
		return
	}
	if result.RowsAffected == 0 {
		core.Error(c, "Member not found in this group")
		return
	}

	core.Success(c, "Member removed successfully", nil)
}

// LeaveGroup godoc
// @Summary      退出圈子
// @Description  当前用户主动退出一个圈子，圈主无法退出
// @Tags         Groups
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "成功退出圈子"
// @Failure      400  {object}  core.ApiResponse "圈主无法退出"
// @Security     BearerAuth
// @Router       /groups/{uuid}/leave [post]
func (h *GroupHandler) LeaveGroup(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")

	// Using a helper method from group_helpers.go
	group, err := h.getGroupByUUID(groupUUID)
	if err != nil {
		core.Error(c, "Group not found or you are not a member")
		return
	}

	if group.OwnerID == userID {
		core.Error(c, "Owner cannot leave the group. Please delete the group or transfer ownership first.")
		return
	}

	result := h.DB.Where("group_id = ? AND user_id = ?", group.ID, userID).Delete(&models.GroupMember{})
	if result.Error != nil || result.RowsAffected == 0 {
		core.Error(c, "Failed to leave group")
		return
	}

	core.Success(c, "Successfully left the group", nil)
}
