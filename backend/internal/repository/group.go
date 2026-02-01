package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

// groupRepository 圈子仓储实现
type groupRepository struct {
	db *gorm.DB
}

// NewGroupRepository 创建圈子仓储
func NewGroupRepository(db *gorm.DB) GroupRepository {
	return &groupRepository{db: db}
}

func (r *groupRepository) Create(ctx context.Context, group *models.Group) error {
	return r.db.WithContext(ctx).Create(group).Error
}

func (r *groupRepository) FindByUUID(ctx context.Context, uuid string) (*models.Group, error) {
	var group models.Group
	err := r.db.WithContext(ctx).Where("uuid = ?", uuid).First(&group).Error
	if err != nil {
		return nil, err
	}
	return &group, nil
}

func (r *groupRepository) FindByID(ctx context.Context, id uint) (*models.Group, error) {
	var group models.Group
	err := r.db.WithContext(ctx).First(&group, id).Error
	if err != nil {
		return nil, err
	}
	return &group, nil
}

func (r *groupRepository) Update(ctx context.Context, uuid string, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).
		Model(&models.Group{}).
		Where("uuid = ?", uuid).
		Updates(updates).Error
}

func (r *groupRepository) FindByUserID(ctx context.Context, userID uint) ([]*models.Group, error) {
	var groups []*models.Group
	err := r.db.WithContext(ctx).
		Joins("JOIN group_members ON group_members.group_id = groups.id").
		Where("group_members.user_id = ?", userID).
		Order("groups.created_at DESC").
		Find(&groups).Error
	return groups, err
}

func (r *groupRepository) CountMembers(ctx context.Context, groupID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.GroupMember{}).
		Where("group_id = ?", groupID).
		Count(&count).Error
	return count, err
}

// groupMemberRepository 圈子成员仓储实现
type groupMemberRepository struct {
	db *gorm.DB
}

// NewGroupMemberRepository 创建圈子成员仓储
func NewGroupMemberRepository(db *gorm.DB) GroupMemberRepository {
	return &groupMemberRepository{db: db}
}

func (r *groupMemberRepository) Create(ctx context.Context, member *models.GroupMember) error {
	return r.db.WithContext(ctx).Create(member).Error
}

func (r *groupMemberRepository) FindByGroupAndUser(ctx context.Context, groupID, userID uint) (*models.GroupMember, error) {
	var member models.GroupMember
	err := r.db.WithContext(ctx).
		Where("group_id = ? AND user_id = ?", groupID, userID).
		First(&member).Error
	if err != nil {
		return nil, err
	}
	return &member, nil
}

func (r *groupMemberRepository) GetUserRole(ctx context.Context, groupUUID string, userID uint) (models.GroupRole, error) {
	var member models.GroupMember
	err := r.db.WithContext(ctx).
		Joins("JOIN groups ON groups.id = group_members.group_id").
		Where("groups.uuid = ? AND group_members.user_id = ?", groupUUID, userID).
		First(&member).Error
	if err != nil {
		return "", err
	}
	return member.Role, nil
}

func (r *groupMemberRepository) FindByGroupUUID(ctx context.Context, groupUUID string) ([]*models.GroupMember, error) {
	var members []*models.GroupMember
	err := r.db.WithContext(ctx).
		Joins("JOIN groups ON groups.id = group_members.group_id").
		Joins("JOIN users ON users.id = group_members.user_id").
		Where("groups.uuid = ?", groupUUID).
		Order("group_members.joined_at ASC").
		Find(&members).Error
	return members, err
}

func (r *groupMemberRepository) Delete(ctx context.Context, groupID, userID uint) error {
	return r.db.WithContext(ctx).
		Where("group_id = ? AND user_id = ?", groupID, userID).
		Delete(&models.GroupMember{}).Error
}

func (r *groupMemberRepository) IsMember(ctx context.Context, groupID, userID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.GroupMember{}).
		Where("group_id = ? AND user_id = ?", groupID, userID).
		Count(&count).Error
	return count > 0, err
}

// groupPostRepository 圈子帖子仓储实现
type groupPostRepository struct {
	db *gorm.DB
}

// NewGroupPostRepository 创建圈子帖子仓储
func NewGroupPostRepository(db *gorm.DB) GroupPostRepository {
	return &groupPostRepository{db: db}
}

func (r *groupPostRepository) Create(ctx context.Context, post *models.GroupPost) error {
	return r.db.WithContext(ctx).Create(post).Error
}

func (r *groupPostRepository) FindByID(ctx context.Context, id uint) (*models.GroupPost, error) {
	var post models.GroupPost
	err := r.db.WithContext(ctx).
		Preload("Creator").
		First(&post, id).Error
	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *groupPostRepository) FindByGroupID(ctx context.Context, groupID uint, limit, offset int) ([]*models.GroupPost, error) {
	var posts []*models.GroupPost
	err := r.db.WithContext(ctx).
		Where("group_id = ?", groupID).
		Preload("Creator").
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&posts).Error
	return posts, err
}

func (r *groupPostRepository) FindByGroupIDs(ctx context.Context, groupIDs []uint, limit, offset int) ([]*models.GroupPost, error) {
	if len(groupIDs) == 0 {
		return nil, nil
	}
	var posts []*models.GroupPost
	err := r.db.WithContext(ctx).
		Where("group_id IN ?", groupIDs).
		Preload("Creator").
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&posts).Error
	return posts, err
}

func (r *groupPostRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).
		Delete(&models.GroupPost{}, id).Error
}

// groupMediaRepository 圈子媒体仓储实现
type groupMediaRepository struct {
	db *gorm.DB
}

// NewGroupMediaRepository 创建圈子媒体仓储
func NewGroupMediaRepository(db *gorm.DB) GroupMediaRepository {
	return &groupMediaRepository{db: db}
}

func (r *groupMediaRepository) Create(ctx context.Context, groupMedia *models.GroupMedia) error {
	return r.db.WithContext(ctx).Create(groupMedia).Error
}

func (r *groupMediaRepository) CreateBatch(ctx context.Context, groupMedias []*models.GroupMedia) error {
	return r.db.WithContext(ctx).Create(groupMedias).Error
}

func (r *groupMediaRepository) FindByPostID(ctx context.Context, postID uint) ([]*models.GroupMedia, error) {
	var groupMedias []*models.GroupMedia
	err := r.db.WithContext(ctx).
		Where("post_id = ?", postID).
		Find(&groupMedias).Error
	return groupMedias, err
}

func (r *groupMediaRepository) FindByGroupAndMediaUUID(ctx context.Context, groupID uint, mediaUUID string) (*models.GroupMedia, error) {
	var groupMedia models.GroupMedia
	err := r.db.WithContext(ctx).
		Where("group_id = ? AND media_uuid = ?", groupID, mediaUUID).
		First(&groupMedia).Error
	if err != nil {
		return nil, err
	}
	return &groupMedia, nil
}

// commentRepository 评论仓储实现
type commentRepository struct {
	db *gorm.DB
}

// NewCommentRepository 创建评论仓储
func NewCommentRepository(db *gorm.DB) CommentRepository {
	return &commentRepository{db: db}
}

func (r *commentRepository) Create(ctx context.Context, comment *models.Comment) error {
	return r.db.WithContext(ctx).Create(comment).Error
}

func (r *commentRepository) FindByID(ctx context.Context, id uint) (*models.Comment, error) {
	var comment models.Comment
	err := r.db.WithContext(ctx).
		Preload("User").
		Preload("Post.Group").
		First(&comment, id).Error
	if err != nil {
		return nil, err
	}
	return &comment, nil
}

func (r *commentRepository) FindByPostID(ctx context.Context, postID uint) ([]*models.Comment, error) {
	var comments []*models.Comment
	err := r.db.WithContext(ctx).
		Where("post_id = ?", postID).
		Preload("User").
		Preload("Likes").
		Order("created_at ASC").
		Find(&comments).Error
	return comments, err
}

func (r *commentRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).
		Delete(&models.Comment{}, id).Error
}

func (r *commentRepository) CountByPostID(ctx context.Context, postID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.Comment{}).
		Where("post_id = ?", postID).
		Count(&count).Error
	return count, err
}

// likeRepository 点赞仓储实现
type likeRepository struct {
	db *gorm.DB
}

// NewLikeRepository 创建点赞仓储
func NewLikeRepository(db *gorm.DB) LikeRepository {
	return &likeRepository{db: db}
}

func (r *likeRepository) Create(ctx context.Context, like *models.Like) error {
	return r.db.WithContext(ctx).Create(like).Error
}

func (r *likeRepository) CountByPostID(ctx context.Context, postID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&models.Like{}).
		Where("post_id = ?", postID).
		Count(&count).Error
	return count, err
}

func (r *likeRepository) CountByPostIDs(ctx context.Context, postIDs []uint) (map[uint]int64, error) {
	type Result struct {
		PostID uint  `gorm:"column:post_id"`
		Total  int64 `gorm:"column:total"`
	}
	var results []Result

	if len(postIDs) == 0 {
		return make(map[uint]int64), nil
	}

	err := r.db.WithContext(ctx).
		Model(&models.Like{}).
		Select("post_id as post_id, count(*) as total").
		Where("post_id IN ?", postIDs).
		Group("post_id").
		Scan(&results).Error

	if err != nil {
		return nil, err
	}

	countsMap := make(map[uint]int64)
	for _, res := range results {
		countsMap[res.PostID] = res.Total
	}
	return countsMap, nil
}

// groupInviteRepository 圈子邀请仓储实现
type groupInviteRepository struct {
	db *gorm.DB
}

// NewGroupInviteRepository 创建圈子邀请仓储
func NewGroupInviteRepository(db *gorm.DB) GroupInviteRepository {
	return &groupInviteRepository{db: db}
}

func (r *groupInviteRepository) Create(ctx context.Context, invite *models.GroupInvite) error {
	return r.db.WithContext(ctx).Create(invite).Error
}

func (r *groupInviteRepository) FindByCode(ctx context.Context, code string) (*models.GroupInvite, error) {
	var invite models.GroupInvite
	err := r.db.WithContext(ctx).
		Where("code = ?", code).
		First(&invite).Error
	if err != nil {
		return nil, err
	}
	return &invite, nil
}
