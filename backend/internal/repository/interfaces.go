package repository

import (
	"context"
	"time"

	"github.com/album/backend/internal/database/models"
)

// MediaRepository 媒体仓储接口
type MediaRepository interface {
	// Create 创建媒体记录
	Create(ctx context.Context, media *models.Media) error

	// FindByUUID 根据UUID查找媒体
	FindByUUID(ctx context.Context, uuid string) (*models.Media, error)

	// FindByUserID 根据用户ID查找媒体列表
	FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.Media, error)

	// Update 更新媒体记录
	Update(ctx context.Context, uuid string, updates map[string]interface{}) error

	// Delete 删除媒体记录（软删除）
	Delete(ctx context.Context, uuid string) error

	// FindByHash 根据Hash查找媒体（用于去重）
	FindByHash(ctx context.Context, userID uint, hash string) (*models.Media, error)

	// FindByUserIDWithFilter 根据用户ID和过滤条件查找媒体列表
	FindByUserIDWithFilter(ctx context.Context, userID uint, itemType string, limit, offset int) ([]*models.Media, error)

	// CountByUserID 统计用户媒体数量
	CountByUserID(ctx context.Context, userID uint, itemType string) (int64, error)

	// FindHashesByUserID 根据用户ID和哈希列表查找已存在的哈希
	FindHashesByUserID(ctx context.Context, userID uint, hashes []string) ([]string, error)

	// FindChangesSince 查找指定时间之后的媒体变更
	FindChangesSince(ctx context.Context, userID uint, since interface{}) ([]*models.Media, error)

	// FindActiveByUUIDAndUser 查找一个未被软删除的媒体记录
	FindActiveByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error)

	// FindInBinByUUIDAndUser 查找一个在回收站中（已被软删除）的媒体记录
	FindInBinByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error)

	// Purge 永久删除媒体记录（硬删除）
	Purge(ctx context.Context, uuid string) error
}

// UserRepository 用户仓储接口
// 负责用户注册、查询及资料更新等操作。
type UserRepository interface {
	Create(ctx context.Context, user *models.User) error
	FindByEmail(ctx context.Context, email string) (*models.User, error)
	FindByID(ctx context.Context, id uint) (*models.User, error)
	ExistsByUsernameOrEmail(ctx context.Context, username, email string) (bool, error)
	UpdatePassword(ctx context.Context, userID uint, hashedPassword string) error
	UpdateAvatar(ctx context.Context, userID uint, filename string) error
}

// AuthProviderRepository 认证提供商仓储接口
// 用于维护用户与第三方账号的关联关系。
type AuthProviderRepository interface {
	Create(ctx context.Context, provider *models.AuthProvider) error
	FindByProviderAndUserID(ctx context.Context, provider string, userID uint) (*models.AuthProvider, error)
	FindByProviderUserID(ctx context.Context, provider, providerUserID string) (*models.AuthProvider, error)
}

// RefreshTokenRepository 刷新令牌仓储接口
type RefreshTokenRepository interface {
	Create(ctx context.Context, token *models.RefreshToken) error
	FindActiveByToken(ctx context.Context, token string) (*models.RefreshToken, error)
	RevokeByToken(ctx context.Context, token string) (bool, error)
}

// GroupRepository 圈子仓储接口
type GroupRepository interface {
	// Create 创建圈子
	Create(ctx context.Context, group *models.Group) error
	// FindByUUID 根据UUID查找圈子
	FindByUUID(ctx context.Context, uuid string) (*models.Group, error)
	// FindByID 根据ID查找圈子
	FindByID(ctx context.Context, id uint) (*models.Group, error)
	// Update 更新圈子信息
	Update(ctx context.Context, uuid string, updates map[string]interface{}) error
	// FindByUserID 查找用户加入的所有圈子
	FindByUserID(ctx context.Context, userID uint) ([]*models.Group, error)
	// CountMembers 统计圈子成员数量
	CountMembers(ctx context.Context, groupID uint) (int64, error)
}

// GroupMemberRepository 圈子成员仓储接口
type GroupMemberRepository interface {
	// Create 添加成员
	Create(ctx context.Context, member *models.GroupMember) error
	// FindByGroupAndUser 查找成员关系
	FindByGroupAndUser(ctx context.Context, groupID, userID uint) (*models.GroupMember, error)
	// GetUserRole 获取用户在圈子中的角色
	GetUserRole(ctx context.Context, groupUUID string, userID uint) (models.GroupRole, error)
	// FindByGroupUUID 查找圈子的所有成员
	FindByGroupUUID(ctx context.Context, groupUUID string) ([]*models.GroupMember, error)
	// Delete 删除成员关系
	Delete(ctx context.Context, groupID, userID uint) error
	// IsMember 检查用户是否是圈子成员
	IsMember(ctx context.Context, groupID, userID uint) (bool, error)
}

// GroupPostRepository 圈子帖子仓储接口
type GroupPostRepository interface {
	// Create 创建帖子
	Create(ctx context.Context, post *models.GroupPost) error
	// FindByID 根据ID查找帖子
	FindByID(ctx context.Context, id uint) (*models.GroupPost, error)
	// FindByGroupID 查找圈子的帖子列表（分页）
	FindByGroupID(ctx context.Context, groupID uint, limit, offset int) ([]*models.GroupPost, error)
	// FindByGroupIDs 查找多个圈子的帖子列表（分页，按 created_at DESC）
	FindByGroupIDs(ctx context.Context, groupIDs []uint, limit, offset int) ([]*models.GroupPost, error)
	// Delete 删除帖子（软删除）
	Delete(ctx context.Context, id uint) error
}

// GroupMediaRepository 圈子媒体仓储接口
type GroupMediaRepository interface {
	// Create 创建圈子媒体关联
	Create(ctx context.Context, groupMedia *models.GroupMedia) error
	// CreateBatch 批量创建圈子媒体关联
	CreateBatch(ctx context.Context, groupMedias []*models.GroupMedia) error
	// FindByPostID 查找帖子关联的所有媒体
	FindByPostID(ctx context.Context, postID uint) ([]*models.GroupMedia, error)
	// FindByGroupAndMediaUUID 查找圈子中的媒体
	FindByGroupAndMediaUUID(ctx context.Context, groupID uint, mediaUUID string) (*models.GroupMedia, error)
}

// CommentRepository 评论仓储接口
type CommentRepository interface {
	// Create 创建评论
	Create(ctx context.Context, comment *models.Comment) error
	// FindByID 根据ID查找评论
	FindByID(ctx context.Context, id uint) (*models.Comment, error)
	// FindByPostID 查找帖子的所有评论
	FindByPostID(ctx context.Context, postID uint) ([]*models.Comment, error)
	// Delete 删除评论（软删除）
	Delete(ctx context.Context, id uint) error
	// CountByPostID 统计帖子的评论数
	CountByPostID(ctx context.Context, postID uint) (int64, error)
}

// LikeRepository 点赞仓储接口
type LikeRepository interface {
	// Create 创建点赞
	Create(ctx context.Context, like *models.Like) error
	// CountByPostID 统计帖子的点赞数
	CountByPostID(ctx context.Context, postID uint) (int64, error)
	// CountByPostIDs 批量统计帖子的点赞数
	CountByPostIDs(ctx context.Context, postIDs []uint) (map[uint]int64, error)
}

// GroupInviteRepository 圈子邀请仓储接口
type GroupInviteRepository interface {
	// Create 创建邀请码
	Create(ctx context.Context, invite *models.GroupInvite) error
	// FindByCode 根据邀请码查找
	FindByCode(ctx context.Context, code string) (*models.GroupInvite, error)
}

// ShareRepository 分享仓储接口
type ShareRepository interface {
	// Create 创建分享记录
	Create(ctx context.Context, share *models.Share) error
	// FindByToken 根据分享令牌查找
	FindByToken(ctx context.Context, token string) (*models.Share, error)
	// FindByTargetUserID 查找分享给指定用户的所有有效分享
	FindByTargetUserID(ctx context.Context, userID uint) ([]*models.Share, error)
	// Revoke 撤销分享
	Revoke(ctx context.Context, shareID uint) error
}

// StoragePoolRepository 存储池仓储接口
type StoragePoolRepository interface {
	FindEnabledByStorageType(ctx context.Context, storageType string) ([]*models.StoragePool, error)
	List(ctx context.Context, filter StoragePoolFilter) ([]*models.StoragePool, error)
	FindByUUID(ctx context.Context, uuid string) (*models.StoragePool, error)
	Create(ctx context.Context, pool *models.StoragePool) error
	UpdateByUUID(ctx context.Context, uuid string, updates map[string]interface{}) error
	SetEnabled(ctx context.Context, uuid string, enabled bool) error
	IncrementCurrentSize(ctx context.Context, poolUUID string, delta int64) error
	UpdateCurrentSize(ctx context.Context, poolUUID string, size int64) error
	UpdateState(ctx context.Context, poolUUID string, enabled bool, status string, currentSize int64, lastCheckedAt *time.Time) error
	FindUsage(ctx context.Context, poolUUID string) ([]StoragePoolUsageRow, error)
}

// StoragePoolFilter 查询条件
type StoragePoolFilter struct {
	StorageType string
	Status      string
}

// StoragePoolUsageRow 用于容量统计的结果
type StoragePoolUsageRow struct {
	UUID          string
	DatabaseSize  int64
	ActualSize    int64
	LastCheckedAt *time.Time
}

// SyncRepository 同步仓储接口
type SyncRepository interface {
	// GetAssetsWithCursor 使用游标分页获取资产列表
	GetAssetsWithCursor(ctx context.Context, userID uint, batchSize int, lastID string) ([]*models.Media, string, error)
	// GetAssetsSince 获取指定时间之后的资产（用于增量同步）
	GetAssetsSince(ctx context.Context, userID uint, since *time.Time, batchSize int) ([]*models.Media, error)
	// GetDeletedAssetsSince 获取指定时间之后被软删除的资产UUID列表（用于增量同步）
	GetDeletedAssetsSince(ctx context.Context, userID uint, since *time.Time, batchSize int) ([]string, error)
}

// CheckpointRepository 检查点仓储接口
type CheckpointRepository interface {
	// GetCheckpoint 获取检查点
	GetCheckpoint(ctx context.Context, userID uint, deviceID string, syncType string) (*models.SyncCheckpoint, error)
	// SetCheckpoint 设置检查点
	SetCheckpoint(ctx context.Context, userID uint, deviceID string, syncType string, ack string) error
	// DeleteCheckpoint 删除检查点
	DeleteCheckpoint(ctx context.Context, userID uint, deviceID string, syncType string) error
	// ResetSyncProgress 重置同步进度（删除所有检查点）
	ResetSyncProgress(ctx context.Context, userID uint, deviceID string) error
	// GetNowID 获取当前时间ID（用于生成checkpoint）
	GetNowID() string
}

// AlbumRepository 相册仓储接口
type AlbumRepository interface {
	// Create 创建相册
	Create(ctx context.Context, album *models.Album) error
	// FindByUUID 根据UUID查找相册
	FindByUUID(ctx context.Context, uuid string) (*models.Album, error)
	// FindByUserID 根据用户ID查找相册列表
	FindByUserID(ctx context.Context, userID uint) ([]*models.Album, error)
	// Update 更新相册信息
	Update(ctx context.Context, album *models.Album) error
	// Delete 删除相册
	Delete(ctx context.Context, uuid string) error
}
