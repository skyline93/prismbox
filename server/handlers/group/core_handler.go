// server/handlers/core_handler.go
// This file contains the GroupHandler struct and core group management logic.

package group

import (
	"server/core"
	"server/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// GroupHandler 封装了所有与圈子相关的HTTP处理器
// 它包含数据库连接，并将作为所有圈子相关方法的接收者。
type GroupHandler struct {
	DB *gorm.DB
}

// CreateGroup godoc
// @Summary      创建新圈子
// @Description  为当前登录的用户创建一个新的圈子，创建者自动成为“所有者”
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Param        group body CreateGroupInput true "圈子信息"
// @Success      200  {object}  core.ApiResponse{data=models.Group} "圈子创建成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误或服务器内部错误"
// @Security     BearerAuth
// @Router       /groups [post]
func (h *GroupHandler) CreateGroup(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var input CreateGroupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	group := models.Group{
		UUID:        uuid.New().String(),
		Name:        input.Name,
		Description: input.Description,
		OwnerID:     userID,
	}

	// 使用事务确保数据一致性
	err := h.DB.Transaction(func(tx *gorm.DB) error {
		// 1. 创建圈子
		if err := tx.Create(&group).Error; err != nil {
			return err
		}

		// 2. 将创建者作为所有者添加到成员表
		member := models.GroupMember{
			GroupID: group.ID,
			UserID:  userID,
			Role:    models.RoleOwner,
		}
		if err := tx.Create(&member).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		core.Error(c, "Failed to create group: "+err.Error())
		return
	}

	core.Success(c, "Group created successfully", group)
}

// GetMyGroups godoc
// @Summary      获取我加入的圈子列表
// @Description  获取当前用户加入的所有圈子列表
// @Tags         Groups
// @Produce      json
// @Success      200  {object}  core.ApiResponse{data=[]models.Group} "成功获取圈子列表"
// @Failure      400  {object}  core.ApiResponse "数据库错误"
// @Security     BearerAuth
// @Router       /groups [get]
func (h *GroupHandler) GetMyGroups(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var groups []models.Group
	err := h.DB.Joins("JOIN group_members on group_members.group_id = groups.id").
		Where("group_members.user_id = ?", userID).
		Order("groups.created_at desc").
		Find(&groups).Error

	if err != nil {
		core.Error(c, "Failed to fetch groups: "+err.Error())
		return
	}

	core.Success(c, "Groups retrieved successfully", groups)
}

// GetGroupDetails godoc
// @Summary      获取圈子详情
// @Description  获取单个圈子的详细信息，并包含当前用户的角色信息
// @Tags         Groups
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse{data=group.GroupDetailResponse} "成功获取圈子详情"
// @Failure      400  {object}  core.ApiResponse "圈子未找到或无权限"
// @Security     BearerAuth
// @Router       /groups/{uuid} [get]
func (h *GroupHandler) GetGroupDetails(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	groupUUID := c.Param("uuid")

	// --- 修改开始 ---

	// 1. 权限校验：确保用户是圈子成员，并获取其角色
	role, err := h.getUserRoleInGroup(groupUUID, userID)
	if err != nil {
		core.Error(c, "Group not found or permission denied")
		return
	}

	// 2. 获取圈子基础信息
	var group models.Group
	if err := h.DB.First(&group, "uuid = ?", groupUUID).Error; err != nil {
		core.Error(c, "Group not found")
		return
	}

	// 3. (可选但推荐) 获取圈子成员总数
	var memberCount int64
	h.DB.Model(&models.GroupMember{}).Where("group_id = ?", group.ID).Count(&memberCount)

	// 4. 构建专门的响应 DTO
	response := GroupDetailResponse{
		UUID:            group.UUID,
		Name:            group.Name,
		Description:     group.Description,
		CoverMediaUUID:  group.CoverMediaUUID,
		OwnerID:         group.OwnerID,
		CreatedAt:       group.CreatedAt,
		UpdatedAt:       group.UpdatedAt,
		MemberCount:     memberCount,
		CurrentUserID:   userID, // 附加上下文信息：当前用户ID
		CurrentUserRole: role,   // 附加上下文信息：当前用户角色
	}

	// 5. 返回构建好的 DTO
	core.Success(c, "Group details retrieved successfully", response)

	// --- 修改结束 ---
}

// UpdateGroup godoc
// @Summary      更新圈子信息
// @Description  更新圈子名称或描述，仅限圈主或管理员操作
// @Tags         Groups
// @Accept       json
// @Produce      json
// @Param        uuid path string true "圈子的UUID" format(uuid)
// @Param        group body UpdateGroupInput true "要更新的圈子信息"
// @Success      200  {object}  core.ApiResponse{data=models.Group} "圈子信息更新成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误"
// @Failure      403  {object}  core.ApiResponse "无权限操作"
// @Security     BearerAuth
// @Router       /groups/{uuid} [put]
func (h *GroupHandler) UpdateGroup(c *gin.Context) {
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

	var input UpdateGroupInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	var group models.Group
	// Using a helper method from group_helpers.go
	if err := h.DB.First(&group, "uuid = ?", groupUUID).Error; err != nil {
		core.Error(c, "Group not found")
		return
	}

	updates := make(map[string]interface{})
	if input.Name != nil {
		updates["name"] = *input.Name
	}
	if input.Description != nil {
		updates["description"] = *input.Description
	}

	// 只有当有实际的更新字段时才执行更新操作
	if len(updates) > 0 {
		if err := h.DB.Model(&group).Updates(updates).Error; err != nil {
			core.Error(c, "Failed to update group: "+err.Error())
			return
		}
	}

	core.Success(c, "Group updated successfully", group)
}
