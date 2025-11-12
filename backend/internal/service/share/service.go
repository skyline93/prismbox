package share

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/pkg/logger"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	// ErrShareNotFound 分享未找到
	ErrShareNotFound = errors.New("share not found")
	// ErrShareExpired 分享已过期
	ErrShareExpired = errors.New("share has expired")
	// ErrShareRevoked 分享已撤销
	ErrShareRevoked = errors.New("share has been revoked")
	// ErrMediaNotFound 媒体未找到
	ErrMediaNotFound = errors.New("media not found")
	// ErrMediaNotOwned 媒体不属于用户
	ErrMediaNotOwned = errors.New("media does not belong to user")
	// ErrUserNotFound 用户未找到
	ErrUserNotFound = errors.New("user not found")
)

// URLSigner URL签名器接口
type URLSigner interface {
	Generate(path string, userID uint, ttl time.Duration) (string, error)
}

// URLBuilder URL构建器接口
type URLBuilder interface {
	BuildPublicShareURL(shareToken string) string
	BuildMediaPreviewPath(mediaUUID string) string
}

// Service 分享服务接口
type Service interface {
	// CreateShare 创建分享
	CreateShare(ctx context.Context, ownerID uint, mediaUUID string, targetUserID *uint, durationMinute int) (string, error)
	// ListSharedWithMe 列出分享给我的内容
	ListSharedWithMe(ctx context.Context, userID uint) ([]*models.Share, error)
	// GetShareMetadata 获取分享元数据
	GetShareMetadata(ctx context.Context, shareToken string) (*ShareMetadata, error)
	// GetSharedResource 获取分享的资源（用于公开访问）
	GetSharedResource(ctx context.Context, shareToken string) (*SharedResource, error)
}

// ShareMetadata 分享元数据
type ShareMetadata struct {
	UUID             string     `json:"uuid"`
	OriginalFilename string     `json:"original_filename"`
	ItemType         string     `json:"item_type"`
	Width            int        `json:"width"`
	Height           int        `json:"height"`
	MediaTokenAt     *time.Time `json:"media_taken_at"`
	SignedURL        string     `json:"signed_url"`
}

// SharedResource 分享的资源
type SharedResource struct {
	Share     *models.Share
	SignedURL string
	MediaType string
}

type service struct {
	logger logger.Logger

	shareRepo repository.ShareRepository
	mediaRepo repository.MediaRepository
	userRepo  repository.UserRepository

	urlSigner        URLSigner
	urlBuilder       URLBuilder
	signedURLLoadTTL time.Duration
}

// NewService 创建分享服务
func NewService(
	shareRepo repository.ShareRepository,
	mediaRepo repository.MediaRepository,
	userRepo repository.UserRepository,
	urlSigner URLSigner,
	urlBuilder URLBuilder,
	signedURLLoadTTL time.Duration,
) Service {
	return &service{
		logger:           logger.New("service.share"),
		shareRepo:        shareRepo,
		mediaRepo:        mediaRepo,
		userRepo:         userRepo,
		urlSigner:        urlSigner,
		urlBuilder:       urlBuilder,
		signedURLLoadTTL: signedURLLoadTTL,
	}
}

func (s *service) CreateShare(ctx context.Context, ownerID uint, mediaUUID string, targetUserID *uint, durationMinute int) (string, error) {
	// 验证媒体是否存在且属于分享者
	media, err := s.mediaRepo.FindByUUID(ctx, mediaUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", ErrMediaNotFound
		}
		return "", fmt.Errorf("failed to find media: %w", err)
	}

	if media.UserID != ownerID {
		return "", ErrMediaNotOwned
	}

	// 如果指定了目标用户ID，验证该用户是否存在
	if targetUserID != nil {
		_, err := s.userRepo.FindByID(ctx, *targetUserID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return "", ErrUserNotFound
			}
			return "", fmt.Errorf("failed to find target user: %w", err)
		}
	}

	// 创建分享记录
	share := &models.Share{
		ShareToken:   uuid.NewString(),
		OwnerID:      ownerID,
		TargetUserID: targetUserID,
		MediaID:      media.ID,
		ExpiresAt:    time.Now().Add(time.Minute * time.Duration(durationMinute)),
		IsRevoked:    false,
	}

	if err := s.shareRepo.Create(ctx, share); err != nil {
		return "", fmt.Errorf("failed to create share: %w", err)
	}

	// 构建并返回公开链接
	publicURL := s.urlBuilder.BuildPublicShareURL(share.ShareToken)
	return publicURL, nil
}

func (s *service) ListSharedWithMe(ctx context.Context, userID uint) ([]*models.Share, error) {
	shares, err := s.shareRepo.FindByTargetUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list shares: %w", err)
	}
	return shares, nil
}

func (s *service) GetShareMetadata(ctx context.Context, shareToken string) (*ShareMetadata, error) {
	// 查找分享记录
	share, err := s.shareRepo.FindByToken(ctx, shareToken)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrShareNotFound
		}
		return nil, fmt.Errorf("failed to find share: %w", err)
	}

	// 验证分享链接的有效性
	if share.IsRevoked {
		return nil, ErrShareRevoked
	}
	if time.Now().After(share.ExpiresAt) {
		return nil, ErrShareExpired
	}

	// 生成一个极短时效的签名URL
	resourcePath := s.urlBuilder.BuildMediaPreviewPath(share.Media.UUID)
	signedURL, err := s.urlSigner.Generate(resourcePath, 0, s.signedURLLoadTTL)
	if err != nil {
		return nil, fmt.Errorf("failed to generate signed URL: %w", err)
	}

	return &ShareMetadata{
		UUID:             share.Media.UUID,
		ItemType:         share.Media.ItemType,
		OriginalFilename: share.Media.OriginalFilename,
		Width:            share.Media.Width,
		Height:           share.Media.Height,
		MediaTokenAt:     share.Media.MediaTakenAt,
		SignedURL:        signedURL,
	}, nil
}

func (s *service) GetSharedResource(ctx context.Context, shareToken string) (*SharedResource, error) {
	// 查找分享记录
	share, err := s.shareRepo.FindByToken(ctx, shareToken)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrShareNotFound
		}
		return nil, fmt.Errorf("failed to find share: %w", err)
	}

	// 验证分享链接的有效性
	if share.IsRevoked {
		return nil, ErrShareRevoked
	}
	if time.Now().After(share.ExpiresAt) {
		return nil, ErrShareExpired
	}

	// 为资源生成一个临时的、不记名的签名URL
	resourcePath := s.urlBuilder.BuildMediaPreviewPath(share.Media.UUID)
	signedURL, err := s.urlSigner.Generate(resourcePath, 0, s.signedURLLoadTTL)
	if err != nil {
		return nil, fmt.Errorf("failed to generate signed URL: %w", err)
	}

	return &SharedResource{
		Share:     share,
		SignedURL: signedURL,
		MediaType: share.Media.ItemType,
	}, nil
}
