// server/handlers/group/group_helpers.go
package group

import (
	"errors"
	"server/models"
)

// getGroupAndCheckMembership 是一个组合了“获取圈子”和“检查成员资格”的辅助函数
// 这样可以避免在每个 handler 中重复编写相同的权限校验逻辑
func (h *GroupHandler) getGroupAndCheckMembership(groupUUID string, userID uint) (*models.Group, error) {
	// 首先，根据 UUID 查找圈子
	var group models.Group
	if err := h.DB.Where("uuid = ?", groupUUID).First(&group).Error; err != nil {
		return nil, errors.New("group not found")
	}

	// 然后，检查用户是否是该圈子的成员
	var memberCount int64
	h.DB.Model(&models.GroupMember{}).
		Where("group_id = ? AND user_id = ?", group.ID, userID).
		Count(&memberCount)

	if memberCount == 0 {
		return nil, errors.New("you are not a member of this group")
	}

	return &group, nil
}
