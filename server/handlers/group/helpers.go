// server/handlers/group/helpers.go
// This file contains helper functions used by various GroupHandler methods.

package group

import (
	"errors"
	"server/models"
)

// getUserRoleInGroup 是一个辅助函数，用于检查用户在特定圈子中的角色。
// 返回用户的角色或一个错误（如果圈子未找到或用户不是成员）。
func (h *GroupHandler) getUserRoleInGroup(groupUUID string, userID uint) (models.GroupRole, error) {
	var member models.GroupMember
	err := h.DB.Joins("JOIN groups on groups.id = group_members.group_id").
		Where("groups.uuid = ? AND group_members.user_id = ?", groupUUID, userID).
		First(&member).Error

	if err != nil {
		return "", err // 如果找不到记录，gorm会返回 err
	}
	return member.Role, nil
}

// getGroupMediaAndCheckMembership 检查用户是否有权访问某个 group_media。
// 它会验证 group_media 是否存在，并确认用户是该媒体所在圈子的成员。
func (h *GroupHandler) getGroupMediaAndCheckMembership(groupMediaID uint, userID uint) (*models.GroupMedia, error) {
	var groupMedia models.GroupMedia
	if err := h.DB.First(&groupMedia, groupMediaID).Error; err != nil {
		return nil, errors.New("media not found in any group")
	}

	var count int64
	h.DB.Model(&models.GroupMember{}).Where("group_id = ? AND user_id = ?", groupMedia.GroupID, userID).Count(&count)
	if count == 0 {
		return nil, errors.New("permission denied: you are not a member of the group containing this media")
	}

	return &groupMedia, nil
}

// getGroupByUUID 是一个辅助函数，通过 UUID 获取圈子信息。
func (h *GroupHandler) getGroupByUUID(uuid string) (*models.Group, error) {
	var group models.Group
	err := h.DB.Where("uuid = ?", uuid).First(&group).Error
	return &group, err
}

// getGroupByID 是一个辅助函数，通过 ID 获取圈子信息。
func (h *GroupHandler) getGroupByID(id uint) (*models.Group, error) {
	var group models.Group
	err := h.DB.First(&group, id).Error
	return &group, err
}
