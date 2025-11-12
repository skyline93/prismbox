package group

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/pkg/logger"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	// ErrGroupNotFound 圈子未找到
	ErrGroupNotFound = errors.New("group not found")
	// ErrNotMember 用户不是圈子成员
	ErrNotMember = errors.New("user is not a member of this group")
	// ErrPermissionDenied 权限不足
	ErrPermissionDenied = errors.New("permission denied")
	// ErrOwnerCannotLeave 圈主不能退出圈子
	ErrOwnerCannotLeave = errors.New("owner cannot leave the group")
	// ErrInvalidInviteCode 邀请码无效
	ErrInvalidInviteCode = errors.New("invalid invitation code")
	// ErrInviteCodeExpired 邀请码已过期
	ErrInviteCodeExpired = errors.New("invitation code has expired")
	// ErrAlreadyMember 用户已经是圈子成员
	ErrAlreadyMember = errors.New("user is already a member of this group")
	// ErrMediaNotFound 媒体未找到
	ErrMediaNotFound = errors.New("media not found")
	// ErrMediaNotOwned 媒体不属于用户
	ErrMediaNotOwned = errors.New("media does not belong to user")
	// ErrPostNotFound 帖子未找到
	ErrPostNotFound = errors.New("post not found")
	// ErrCommentNotFound 评论未找到
	ErrCommentNotFound = errors.New("comment not found")
)

const (
	inviteCodeCharset = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
	inviteCodeLength  = 8
)

// Service 圈子服务接口
type Service interface {
	// CreateGroup 创建圈子
	CreateGroup(ctx context.Context, userID uint, name, description string) (*models.Group, error)
	// GetMyGroups 获取我加入的圈子列表
	GetMyGroups(ctx context.Context, userID uint) ([]*models.Group, error)
	// GetGroupDetails 获取圈子详情
	GetGroupDetails(ctx context.Context, groupUUID string, userID uint) (*GroupDetail, error)
	// UpdateGroup 更新圈子信息
	UpdateGroup(ctx context.Context, groupUUID string, userID uint, name, description *string) (*models.Group, error)
	// JoinGroup 使用邀请码加入圈子
	JoinGroup(ctx context.Context, userID uint, code string) (*models.Group, error)
	// LeaveGroup 退出圈子
	LeaveGroup(ctx context.Context, groupUUID string, userID uint) error
	// GetGroupMembers 获取圈子成员列表
	GetGroupMembers(ctx context.Context, groupUUID string, userID uint) ([]*GroupMemberInfo, error)
	// CreateInvite 创建邀请码
	CreateInvite(ctx context.Context, groupUUID string, userID uint) (*models.GroupInvite, error)
	// RemoveMember 移除成员
	RemoveMember(ctx context.Context, groupUUID string, operatorID, memberID uint) error
	// CreatePost 创建帖子
	CreatePost(ctx context.Context, groupUUID string, userID uint, mediaUUIDs []string, caption string) (*models.GroupPost, error)
	// GetGroupFeed 获取圈子Feed流
	GetGroupFeed(ctx context.Context, groupUUID string, userID uint, page, pageSize int) (*GroupFeedResult, error)
	// AddComment 添加评论
	AddComment(ctx context.Context, postID uint, userID uint, content string, parentCommentID *uint) (*CommentInfo, error)
	// GetComments 获取评论列表
	GetComments(ctx context.Context, postID uint, userID uint) ([]*CommentInfo, error)
	// DeleteComment 删除评论
	DeleteComment(ctx context.Context, commentID uint, userID uint) error
	// GetUserRole 获取用户在圈子中的角色
	GetUserRole(ctx context.Context, groupUUID string, userID uint) (models.GroupRole, error)
	// CheckGroupMembership 检查用户是否是圈子成员
	CheckGroupMembership(ctx context.Context, groupUUID string, userID uint) error
}

// GroupDetail 圈子详情
type GroupDetail struct {
	UUID            string         `json:"uuid"`
	Name            string         `json:"name"`
	Description     string         `json:"description"`
	CoverMediaUUID  string         `json:"cover_media_uuid"`
	OwnerID         uint           `json:"owner_id"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	MemberCount     int64          `json:"member_count"`
	CurrentUserID   uint           `json:"current_user_id"`
	CurrentUserRole models.GroupRole `json:"current_user_role"`
}

// GroupMemberInfo 圈子成员信息
type GroupMemberInfo struct {
	UserID   uint             `json:"user_id"`
	Username string           `json:"username"`
	Role     models.GroupRole `json:"role"`
	JoinedAt time.Time        `json:"joined_at"`
}

// GroupFeedResult Feed流结果
type GroupFeedResult struct {
	Posts []*GroupPostInfo `json:"posts"`
	Total int              `json:"total"`
	Page  int              `json:"page"`
	Limit int              `json:"limit"`
}

// GroupPostInfo 帖子信息
type GroupPostInfo struct {
	ID            uint                   `json:"id"`
	Caption       string                 `json:"caption"`
	CreatedAt     time.Time              `json:"created_at"`
	Creator       *UserSimpleInfo        `json:"creator"`
	Media         []*MediaInfo           `json:"media"`
	LikesCount    int64                  `json:"likes_count"`
	CommentsCount int64                  `json:"comments_count"`
}

// UserSimpleInfo 用户简单信息
type UserSimpleInfo struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	AvatarURL string `json:"avatar_url"`
}

// MediaInfo 媒体信息
type MediaInfo struct {
	UUID         string `json:"uuid"`
	ItemType     string `json:"item_type"`
	ThumbnailURL string `json:"thumbnail_url,omitempty"`
	PreviewURL   string `json:"preview_url,omitempty"`
}

// CommentInfo 评论信息
type CommentInfo struct {
	ID         string         `json:"id"`
	CreatedAt  time.Time      `json:"created_at"`
	Content    string         `json:"content"`
	User       *UserSimpleInfo `json:"author"`
	LikesCount int            `json:"likes_count"`
	Replies    []*CommentInfo `json:"replies,omitempty"`
}

type service struct {
	logger logger.Logger
	db     *gorm.DB

	groupRepo         repository.GroupRepository
	groupMemberRepo   repository.GroupMemberRepository
	groupPostRepo     repository.GroupPostRepository
	groupMediaRepo    repository.GroupMediaRepository
	commentRepo       repository.CommentRepository
	likeRepo          repository.LikeRepository
	groupInviteRepo   repository.GroupInviteRepository
	mediaRepo         repository.MediaRepository

	avatarBaseURL string
	urlBuilder    URLBuilder
}

// URLBuilder URL构建器接口
type URLBuilder interface {
	BuildGroupMediaURL(groupUUID, mediaUUID string) string
}

// NewService 创建圈子服务
func NewService(
	db *gorm.DB,
	groupRepo repository.GroupRepository,
	groupMemberRepo repository.GroupMemberRepository,
	groupPostRepo repository.GroupPostRepository,
	groupMediaRepo repository.GroupMediaRepository,
	commentRepo repository.CommentRepository,
	likeRepo repository.LikeRepository,
	groupInviteRepo repository.GroupInviteRepository,
	mediaRepo repository.MediaRepository,
	avatarBaseURL string,
	urlBuilder URLBuilder,
) Service {
	return &service{
		logger:          logger.New("service.group"),
		db:              db,
		groupRepo:       groupRepo,
		groupMemberRepo: groupMemberRepo,
		groupPostRepo:   groupPostRepo,
		groupMediaRepo:  groupMediaRepo,
		commentRepo:     commentRepo,
		likeRepo:        likeRepo,
		groupInviteRepo: groupInviteRepo,
		mediaRepo:       mediaRepo,
		avatarBaseURL:   avatarBaseURL,
		urlBuilder:      urlBuilder,
	}
}

func (s *service) CreateGroup(ctx context.Context, userID uint, name, description string) (*models.Group, error) {
	group := &models.Group{
		UUID:        uuid.New().String(),
		Name:        name,
		Description: description,
		OwnerID:     userID,
	}

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// 创建圈子
		if err := tx.Create(group).Error; err != nil {
			return err
		}

		// 将创建者作为所有者添加到成员表
		member := &models.GroupMember{
			GroupID: group.ID,
			UserID:  userID,
			Role:    models.RoleOwner,
		}
		if err := tx.Create(member).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to create group: %w", err)
	}

	return group, nil
}

func (s *service) GetMyGroups(ctx context.Context, userID uint) ([]*models.Group, error) {
	groups, err := s.groupRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get groups: %w", err)
	}
	return groups, nil
}

func (s *service) GetGroupDetails(ctx context.Context, groupUUID string, userID uint) (*GroupDetail, error) {
	// 检查用户是否是成员
	role, err := s.groupMemberRepo.GetUserRole(ctx, groupUUID, userID)
	if err != nil {
		return nil, ErrNotMember
	}

	// 获取圈子信息
	group, err := s.groupRepo.FindByUUID(ctx, groupUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrGroupNotFound
		}
		return nil, fmt.Errorf("failed to get group: %w", err)
	}

	// 获取成员数量
	memberCount, err := s.groupRepo.CountMembers(ctx, group.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to count members: %w", err)
	}

	return &GroupDetail{
		UUID:            group.UUID,
		Name:            group.Name,
		Description:     group.Description,
		CoverMediaUUID:  group.CoverMediaUUID,
		OwnerID:         group.OwnerID,
		CreatedAt:       group.CreatedAt,
		UpdatedAt:       group.UpdatedAt,
		MemberCount:     memberCount,
		CurrentUserID:   userID,
		CurrentUserRole: role,
	}, nil
}

func (s *service) UpdateGroup(ctx context.Context, groupUUID string, userID uint, name, description *string) (*models.Group, error) {
	// 检查权限
	role, err := s.groupMemberRepo.GetUserRole(ctx, groupUUID, userID)
	if err != nil {
		return nil, ErrNotMember
	}
	if role != models.RoleOwner && role != models.RoleAdmin {
		return nil, ErrPermissionDenied
	}

	// 构建更新字段
	updates := make(map[string]interface{})
	if name != nil {
		updates["name"] = *name
	}
	if description != nil {
		updates["description"] = *description
	}

	if len(updates) == 0 {
		// 没有需要更新的字段，直接返回
		return s.groupRepo.FindByUUID(ctx, groupUUID)
	}

	// 更新圈子
	if err := s.groupRepo.Update(ctx, groupUUID, updates); err != nil {
		return nil, fmt.Errorf("failed to update group: %w", err)
	}

	// 返回更新后的圈子
	return s.groupRepo.FindByUUID(ctx, groupUUID)
}

func (s *service) JoinGroup(ctx context.Context, userID uint, code string) (*models.Group, error) {
	// 查找邀请码
	invite, err := s.groupInviteRepo.FindByCode(ctx, code)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrInvalidInviteCode
		}
		return nil, fmt.Errorf("failed to find invite: %w", err)
	}

	// 检查邀请码是否过期
	if time.Now().After(invite.ExpiresAt) {
		return nil, ErrInviteCodeExpired
	}

	// 检查用户是否已经是成员
	isMember, err := s.groupMemberRepo.IsMember(ctx, invite.GroupID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if isMember {
		return nil, ErrAlreadyMember
	}

	// 添加成员
	member := &models.GroupMember{
		GroupID: invite.GroupID,
		UserID:  userID,
		Role:    models.RoleMember,
	}
	if err := s.groupMemberRepo.Create(ctx, member); err != nil {
		return nil, fmt.Errorf("failed to join group: %w", err)
	}

	// 返回圈子信息
	group, err := s.groupRepo.FindByID(ctx, invite.GroupID)
	if err != nil {
		return nil, fmt.Errorf("failed to get group: %w", err)
	}

	return group, nil
}

func (s *service) LeaveGroup(ctx context.Context, groupUUID string, userID uint) error {
	// 获取圈子信息
	group, err := s.groupRepo.FindByUUID(ctx, groupUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrGroupNotFound
		}
		return fmt.Errorf("failed to get group: %w", err)
	}

	// 检查是否是圈主
	if group.OwnerID == userID {
		return ErrOwnerCannotLeave
	}

	// 检查是否是成员
	isMember, err := s.groupMemberRepo.IsMember(ctx, group.ID, userID)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return ErrNotMember
	}

	// 删除成员关系
	if err := s.groupMemberRepo.Delete(ctx, group.ID, userID); err != nil {
		return fmt.Errorf("failed to leave group: %w", err)
	}

	return nil
}

func (s *service) GetGroupMembers(ctx context.Context, groupUUID string, userID uint) ([]*GroupMemberInfo, error) {
	// 检查用户是否是成员
	if _, err := s.groupMemberRepo.GetUserRole(ctx, groupUUID, userID); err != nil {
		return nil, ErrNotMember
	}

	// 获取成员列表
	members, err := s.groupMemberRepo.FindByGroupUUID(ctx, groupUUID)
	if err != nil {
		return nil, fmt.Errorf("failed to get members: %w", err)
	}

	// 转换为响应格式
	result := make([]*GroupMemberInfo, 0, len(members))
	for _, m := range members {
		// 需要从User关联中获取username
		var user models.User
		if err := s.db.WithContext(ctx).First(&user, m.UserID).Error; err != nil {
			continue
		}
		result = append(result, &GroupMemberInfo{
			UserID:   m.UserID,
			Username: user.Username,
			Role:     m.Role,
			JoinedAt: m.JoinedAt,
		})
	}

	return result, nil
}

func (s *service) CreateInvite(ctx context.Context, groupUUID string, userID uint) (*models.GroupInvite, error) {
	// 检查权限
	role, err := s.groupMemberRepo.GetUserRole(ctx, groupUUID, userID)
	if err != nil {
		return nil, ErrNotMember
	}
	if role != models.RoleOwner && role != models.RoleAdmin {
		return nil, ErrPermissionDenied
	}

	// 获取圈子信息
	group, err := s.groupRepo.FindByUUID(ctx, groupUUID)
	if err != nil {
		return nil, ErrGroupNotFound
	}

	// 生成邀请码
	code := generateInviteCode()

	// 创建邀请
	invite := &models.GroupInvite{
		GroupID:     group.ID,
		CreatedByID: userID,
		Code:        code,
		ExpiresAt:   time.Now().Add(48 * time.Hour),
		UsageLimit:  0, // 0表示无限制
	}

	if err := s.groupInviteRepo.Create(ctx, invite); err != nil {
		return nil, fmt.Errorf("failed to create invite: %w", err)
	}

	return invite, nil
}

func (s *service) RemoveMember(ctx context.Context, groupUUID string, operatorID, memberID uint) error {
	// 检查操作者权限
	role, err := s.groupMemberRepo.GetUserRole(ctx, groupUUID, operatorID)
	if err != nil {
		return ErrNotMember
	}
	if role != models.RoleOwner && role != models.RoleAdmin {
		return ErrPermissionDenied
	}

	// 获取圈子信息
	group, err := s.groupRepo.FindByUUID(ctx, groupUUID)
	if err != nil {
		return ErrGroupNotFound
	}

	// 不能移除圈主
	if group.OwnerID == memberID {
		return errors.New("cannot remove the group owner")
	}

	// 删除成员关系
	if err := s.groupMemberRepo.Delete(ctx, group.ID, memberID); err != nil {
		return fmt.Errorf("failed to remove member: %w", err)
	}

	return nil
}

func (s *service) CreatePost(ctx context.Context, groupUUID string, userID uint, mediaUUIDs []string, caption string) (*models.GroupPost, error) {
	// 检查用户是否是成员
	group, err := s.groupRepo.FindByUUID(ctx, groupUUID)
	if err != nil {
		return nil, ErrGroupNotFound
	}

	isMember, err := s.groupMemberRepo.IsMember(ctx, group.ID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return nil, ErrNotMember
	}

	// 验证媒体所有权
	var userMedias []*models.Media
	for _, mediaUUID := range mediaUUIDs {
		media, err := s.mediaRepo.FindByUUID(ctx, mediaUUID)
		if err != nil {
			return nil, ErrMediaNotFound
		}
		if media.UserID != userID {
			return nil, ErrMediaNotOwned
		}
		userMedias = append(userMedias, media)
	}

	// 使用事务创建帖子和关联的媒体记录
	var createdPost *models.GroupPost
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// 创建帖子
		post := &models.GroupPost{
			GroupID:   group.ID,
			CreatorID: userID,
			Caption:   caption,
		}
		if err := tx.Create(post).Error; err != nil {
			return err
		}

		// 创建GroupMedia记录
		var groupMedias []*models.GroupMedia
		for _, media := range userMedias {
			groupMedias = append(groupMedias, &models.GroupMedia{
				GroupID:   group.ID,
				PostID:    post.ID,
				MediaUUID: media.UUID,
			})
		}
		if err := tx.Create(groupMedias).Error; err != nil {
			return err
		}

		// 预加载创建者信息
		if err := tx.Preload("Creator").First(post, post.ID).Error; err != nil {
			return err
		}
		createdPost = post
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to create post: %w", err)
	}

	return createdPost, nil
}

func (s *service) GetGroupFeed(ctx context.Context, groupUUID string, userID uint, page, pageSize int) (*GroupFeedResult, error) {
	// 检查用户是否是成员
	group, err := s.groupRepo.FindByUUID(ctx, groupUUID)
	if err != nil {
		return nil, ErrGroupNotFound
	}

	isMember, err := s.groupMemberRepo.IsMember(ctx, group.ID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return nil, ErrNotMember
	}

	// 计算分页
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	// 获取帖子列表
	posts, err := s.groupPostRepo.FindByGroupID(ctx, group.ID, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get posts: %w", err)
	}

	if len(posts) == 0 {
		return &GroupFeedResult{
			Posts: []*GroupPostInfo{},
			Total: 0,
			Page:  page,
			Limit: pageSize,
		}, nil
	}

	// 收集所有需要的数据
	postIDs := make([]uint, len(posts))
	for i, p := range posts {
		postIDs[i] = p.ID
	}

	// 批量获取GroupMedia
	var allGroupMedias []*models.GroupMedia
	for _, postID := range postIDs {
		medias, err := s.groupMediaRepo.FindByPostID(ctx, postID)
		if err == nil {
			allGroupMedias = append(allGroupMedias, medias...)
		}
	}

	// 收集所有media UUID
	mediaUUIDs := make([]string, 0, len(allGroupMedias))
	for _, gm := range allGroupMedias {
		mediaUUIDs = append(mediaUUIDs, gm.MediaUUID)
	}

	// 批量获取媒体详情
	mediaMap := make(map[string]*models.Media)
	for _, mediaUUID := range mediaUUIDs {
		media, err := s.mediaRepo.FindByUUID(ctx, mediaUUID)
		if err == nil {
			mediaMap[mediaUUID] = media
		}
	}

	// 批量获取点赞数
	likesCountMap, err := s.likeRepo.CountByPostIDs(ctx, postIDs)
	if err != nil {
		likesCountMap = make(map[uint]int64)
	}

	// 批量获取评论数
	commentsCountMap := make(map[uint]int64)
	for _, postID := range postIDs {
		count, err := s.commentRepo.CountByPostID(ctx, postID)
		if err == nil {
			commentsCountMap[postID] = count
		}
	}

	// 构建响应
	postMediaMap := make(map[uint][]*MediaInfo)
	for _, gm := range allGroupMedias {
		if media, ok := mediaMap[gm.MediaUUID]; ok {
			mediaInfo := &MediaInfo{
				UUID:     media.UUID,
				ItemType: media.ItemType,
			}
			if s.urlBuilder != nil {
				mediaInfo.ThumbnailURL = s.urlBuilder.BuildGroupMediaURL(groupUUID, media.UUID)
			}
			postMediaMap[gm.PostID] = append(postMediaMap[gm.PostID], mediaInfo)
		}
	}

	result := make([]*GroupPostInfo, len(posts))
	for i, post := range posts {
		creatorInfo := &UserSimpleInfo{
			UserID:   post.Creator.ID,
			Username: post.Creator.Username,
		}
		if post.Creator.Avatar != "" {
			creatorInfo.AvatarURL = s.avatarBaseURL + post.Creator.Avatar
		}

		result[i] = &GroupPostInfo{
			ID:            post.ID,
			Caption:       post.Caption,
			CreatedAt:     post.CreatedAt,
			Creator:       creatorInfo,
			Media:         postMediaMap[post.ID],
			LikesCount:    likesCountMap[post.ID],
			CommentsCount: commentsCountMap[post.ID],
		}
	}

	return &GroupFeedResult{
		Posts: result,
		Total: len(result),
		Page:  page,
		Limit: pageSize,
	}, nil
}

func (s *service) AddComment(ctx context.Context, postID uint, userID uint, content string, parentCommentID *uint) (*CommentInfo, error) {
	// 获取帖子
	post, err := s.groupPostRepo.FindByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	// 检查用户是否是圈子成员
	isMember, err := s.groupMemberRepo.IsMember(ctx, post.GroupID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return nil, ErrNotMember
	}

	// 如果是回复，验证父评论
	if parentCommentID != nil {
		parentComment, err := s.commentRepo.FindByID(ctx, *parentCommentID)
		if err != nil || parentComment.PostID != postID {
			return nil, errors.New("parent comment not found or does not belong to this post")
		}
	}

	// 创建评论
	comment := &models.Comment{
		PostID:  postID,
		UserID:  userID,
		Content: content,
	}
	if parentCommentID != nil {
		comment.ParentCommentID = parentCommentID
	}

	if err := s.commentRepo.Create(ctx, comment); err != nil {
		return nil, fmt.Errorf("failed to create comment: %w", err)
	}

	// 获取用户信息
	var user models.User
	if err := s.db.WithContext(ctx).First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// 构建响应
	userInfo := &UserSimpleInfo{
		UserID:   user.ID,
		Username: user.Username,
	}
	if user.Avatar != "" {
		userInfo.AvatarURL = s.avatarBaseURL + user.Avatar
	}

	return &CommentInfo{
		ID:         strconv.FormatUint(uint64(comment.ID), 10),
		CreatedAt:  comment.CreatedAt,
		Content:    comment.Content,
		User:       userInfo,
		LikesCount: 0,
		Replies:    []*CommentInfo{},
	}, nil
}

func (s *service) GetComments(ctx context.Context, postID uint, userID uint) ([]*CommentInfo, error) {
	// 获取帖子
	post, err := s.groupPostRepo.FindByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	// 检查用户是否是圈子成员
	isMember, err := s.groupMemberRepo.IsMember(ctx, post.GroupID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return nil, ErrNotMember
	}

	// 获取所有评论
	comments, err := s.commentRepo.FindByPostID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("failed to get comments: %w", err)
	}

	// 构建用户信息映射
	userMap := make(map[uint]*UserSimpleInfo)
	for _, comment := range comments {
		if _, ok := userMap[comment.UserID]; !ok {
			var user models.User
			if err := s.db.WithContext(ctx).First(&user, comment.UserID).Error; err == nil {
				userInfo := &UserSimpleInfo{
					UserID:   user.ID,
					Username: user.Username,
				}
				if user.Avatar != "" {
					userInfo.AvatarURL = s.avatarBaseURL + user.Avatar
				}
				userMap[user.ID] = userInfo
			}
		}
	}

	// 转换为树状结构
	commentMap := make(map[uint]*CommentInfo)
	var rootComments []*CommentInfo

	// 第一遍：创建所有评论的Response对象
	for _, cm := range comments {
		userInfo := userMap[cm.UserID]
		if userInfo == nil {
			continue
		}
		commentMap[cm.ID] = &CommentInfo{
			ID:         strconv.FormatUint(uint64(cm.ID), 10),
			CreatedAt:  cm.CreatedAt,
			Content:    cm.Content,
			User:       userInfo,
			LikesCount: len(cm.Likes),
			Replies:    []*CommentInfo{},
		}
	}

	// 第二遍：构建父子关系
	for _, cm := range comments {
		if commentInfo, ok := commentMap[cm.ID]; ok {
			if cm.ParentCommentID != nil {
				// 如果是子评论，添加到父评论的Replies中
				if parent, ok := commentMap[*cm.ParentCommentID]; ok {
					parent.Replies = append(parent.Replies, commentInfo)
				}
			} else {
				// 如果是顶级评论，添加到根列表
				rootComments = append(rootComments, commentInfo)
			}
		}
	}

	return rootComments, nil
}

func (s *service) DeleteComment(ctx context.Context, commentID uint, userID uint) error {
	// 获取评论
	comment, err := s.commentRepo.FindByID(ctx, commentID)
	if err != nil {
		return ErrCommentNotFound
	}

	// 获取帖子
	post, err := s.groupPostRepo.FindByID(ctx, comment.PostID)
	if err != nil {
		return ErrPostNotFound
	}

	// 检查用户是否是圈子成员
	isMember, err := s.groupMemberRepo.IsMember(ctx, post.GroupID, userID)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if !isMember {
		return ErrNotMember
	}

	// 检查权限：评论者本人或圈主/管理员
	role, err := s.groupMemberRepo.GetUserRole(ctx, post.Group.UUID, userID)
	if err != nil {
		return ErrNotMember
	}
	if comment.UserID != userID && role != models.RoleOwner && role != models.RoleAdmin {
		return ErrPermissionDenied
	}

	// 删除评论
	if err := s.commentRepo.Delete(ctx, commentID); err != nil {
		return fmt.Errorf("failed to delete comment: %w", err)
	}

	return nil
}

func (s *service) GetUserRole(ctx context.Context, groupUUID string, userID uint) (models.GroupRole, error) {
	return s.groupMemberRepo.GetUserRole(ctx, groupUUID, userID)
}

func (s *service) CheckGroupMembership(ctx context.Context, groupUUID string, userID uint) error {
	_, err := s.groupMemberRepo.GetUserRole(ctx, groupUUID, userID)
	if err != nil {
		return ErrNotMember
	}
	return nil
}

// generateInviteCode 生成邀请码
func generateInviteCode() string {
	seededRand := rand.New(rand.NewSource(time.Now().UnixNano()))
	b := make([]byte, inviteCodeLength)
	for i := range b {
		b[i] = inviteCodeCharset[seededRand.Intn(len(inviteCodeCharset))]
	}
	return string(b)
}

