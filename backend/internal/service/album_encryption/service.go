package album_encryption

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/pkg/logger"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	// ErrAlbumNotFound 相册不存在
	ErrAlbumNotFound = errors.New("album not found")
	// ErrAlbumNotEncrypted 相册未加密
	ErrAlbumNotEncrypted = errors.New("album is not encrypted")
	// ErrInvalidPassword 密码无效
	ErrInvalidPassword = errors.New("invalid password")
	// ErrPasswordNotSet 密码未设置
	ErrPasswordNotSet = errors.New("password not set")
	// ErrSessionTokenInvalid 会话令牌无效
	ErrSessionTokenInvalid = errors.New("session token is invalid or expired")
)

// Service 加密空间认证服务接口
type Service interface {
	// GetOrCreateEncryptedAlbum 获取或创建用户的加密空间相册
	GetOrCreateEncryptedAlbum(ctx context.Context, userID uint) (*models.Album, error)

	// SetPassword 设置或更新相册密码
	SetPassword(ctx context.Context, albumID string, userID uint, password string) error

	// ChangePassword 更改相册密码（需要验证旧密码）
	ChangePassword(ctx context.Context, albumID string, userID uint, oldPassword, newPassword string) error

	// VerifyPassword 验证密码并返回会话令牌
	VerifyPassword(ctx context.Context, albumID string, userID uint, password string) (*SessionToken, error)

	// ValidateSessionToken 验证会话令牌
	ValidateSessionToken(ctx context.Context, albumID string, userID uint, token string) error

	// RevokeAllSessions 撤销所有会话令牌（密码更改时）
	RevokeAllSessions(ctx context.Context, albumID string, userID uint) error

	// RevokeSession 撤销特定会话令牌
	RevokeSession(ctx context.Context, sessionID string, userID uint) error
}

// SessionToken 会话令牌信息
type SessionToken struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

type service struct {
	logger logger.Logger
	db     *gorm.DB

	albumRepo        repository.AlbumRepository
	albumSessionRepo repository.AlbumSessionRepository
}

// NewService 创建加密空间认证服务
func NewService(
	db *gorm.DB,
	albumRepo repository.AlbumRepository,
	albumSessionRepo repository.AlbumSessionRepository,
) Service {
	return &service{
		logger:           logger.New("service.album_encryption"),
		db:               db,
		albumRepo:        albumRepo,
		albumSessionRepo: albumSessionRepo,
	}
}

// SetPassword 设置或更新相册密码
func (s *service) SetPassword(ctx context.Context, albumID string, userID uint, password string) error {
	// 获取相册
	album, err := s.albumRepo.FindByUUID(ctx, albumID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrAlbumNotFound
		}
		return err
	}

	// 验证用户权限
	if album.UserID != userID {
		return ErrAlbumNotFound // 不暴露相册存在性
	}

	// 哈希密码
	passwordHash, err := auth.HashPassword(password)
	if err != nil {
		return err
	}

	// 更新相册密码哈希
	album.PasswordHash = &passwordHash
	album.IsEncrypted = true
	album.AlbumType = models.AlbumTypeEncryptedSpace

	if err := s.albumRepo.Update(ctx, album); err != nil {
		return err
	}

	// 撤销所有现有会话令牌
	if err := s.RevokeAllSessions(ctx, albumID, userID); err != nil {
		s.logger.Warn("Failed to revoke sessions after password change", logger.Error(err))
		// 不返回错误，密码已成功设置
	}

	return nil
}

// ChangePassword 更改相册密码（需要验证旧密码）
func (s *service) ChangePassword(ctx context.Context, albumID string, userID uint, oldPassword, newPassword string) error {
	// 获取相册
	album, err := s.albumRepo.FindByUUID(ctx, albumID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrAlbumNotFound
		}
		return err
	}

	// 验证用户权限
	if album.UserID != userID {
		return ErrAlbumNotFound // 不暴露相册存在性
	}

	// 验证相册是否加密
	if !album.IsEncrypted {
		return ErrAlbumNotEncrypted
	}

	// 验证密码是否已设置
	if album.PasswordHash == nil || *album.PasswordHash == "" {
		return ErrPasswordNotSet
	}

	// 验证旧密码
	if !auth.CheckPasswordHash(oldPassword, *album.PasswordHash) {
		return ErrInvalidPassword
	}

	// 哈希新密码
	newPasswordHash, err := auth.HashPassword(newPassword)
	if err != nil {
		return err
	}

	// 更新相册密码哈希
	album.PasswordHash = &newPasswordHash

	if err := s.albumRepo.Update(ctx, album); err != nil {
		return err
	}

	// 撤销所有现有会话令牌
	if err := s.RevokeAllSessions(ctx, albumID, userID); err != nil {
		s.logger.Warn("Failed to revoke sessions after password change", logger.Error(err))
		// 不返回错误，密码已成功更改
	}

	return nil
}

// VerifyPassword 验证密码并返回会话令牌
func (s *service) VerifyPassword(ctx context.Context, albumID string, userID uint, password string) (*SessionToken, error) {
	// 获取相册
	album, err := s.albumRepo.FindByUUID(ctx, albumID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrAlbumNotFound
		}
		return nil, err
	}

	// 验证用户权限
	if album.UserID != userID {
		return nil, ErrAlbumNotFound
	}

	// 验证相册是否加密
	if !album.IsEncrypted {
		return nil, ErrAlbumNotEncrypted
	}

	// 验证密码是否已设置
	if album.PasswordHash == nil || *album.PasswordHash == "" {
		return nil, ErrPasswordNotSet
	}

	// 验证密码
	if !auth.CheckPasswordHash(password, *album.PasswordHash) {
		return nil, ErrInvalidPassword
	}

	// 生成会话令牌
	token, err := generateSessionToken()
	if err != nil {
		return nil, err
	}

	// 哈希令牌（存储哈希值，不存储明文）
	tokenHash, err := auth.HashPassword(token)
	if err != nil {
		return nil, err
	}

	// 设置过期时间（1小时）
	expiresAt := time.Now().Add(1 * time.Hour)

	// 生成会话ID
	sessionID, err := generateSessionToken()
	if err != nil {
		return nil, err
	}

	// 创建会话记录
	session := &models.AlbumSession{
		ID:           sessionID,
		AlbumID:      albumID,
		UserID:       userID,
		SessionToken: tokenHash,
		ExpiresAt:    expiresAt,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.albumSessionRepo.Create(ctx, session); err != nil {
		return nil, err
	}

	return &SessionToken{
		Token:     token,
		ExpiresAt: expiresAt,
	}, nil
}

// ValidateSessionToken 验证会话令牌
func (s *service) ValidateSessionToken(ctx context.Context, albumID string, userID uint, token string) error {
	// 获取所有有效会话
	sessions, err := s.albumSessionRepo.FindByAlbumID(ctx, albumID)
	if err != nil {
		return err
	}

	// 查找匹配的会话
	for _, session := range sessions {
		// 验证用户ID
		if session.UserID != userID {
			continue
		}

		// 验证过期时间
		if time.Now().After(session.ExpiresAt) {
			continue
		}

		// 验证令牌哈希
		if auth.CheckPasswordHash(token, session.SessionToken) {
			return nil
		}
	}

	return ErrSessionTokenInvalid
}

// RevokeAllSessions 撤销所有会话令牌
func (s *service) RevokeAllSessions(ctx context.Context, albumID string, userID uint) error {
	return s.albumSessionRepo.DeleteByAlbumID(ctx, albumID)
}

// RevokeSession 撤销特定会话令牌
func (s *service) RevokeSession(ctx context.Context, sessionID string, userID uint) error {
	session, err := s.albumSessionRepo.FindByID(ctx, sessionID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrSessionTokenInvalid
		}
		return err
	}

	// 验证用户权限
	if session.UserID != userID {
		return ErrSessionTokenInvalid
	}

	return s.albumSessionRepo.Delete(ctx, sessionID)
}

// GetOrCreateEncryptedAlbum 获取或创建用户的加密空间相册
func (s *service) GetOrCreateEncryptedAlbum(ctx context.Context, userID uint) (*models.Album, error) {
	// 尝试查找现有加密空间相册
	album, err := s.albumRepo.FindEncryptedAlbumByUserID(ctx, userID)
	if err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}
		// 不存在，创建新的加密空间相册
		album = &models.Album{
			UUID:        generateUUID(),
			Name:        "加密空间",
			Description: "您的私密照片和视频",
			UserID:      userID,
			IsEncrypted: true,
			AlbumType:   models.AlbumTypeEncryptedSpace,
			Order:       1,
		}

		if err := s.albumRepo.Create(ctx, album); err != nil {
			return nil, err
		}

		s.logger.Info("Created encrypted space album", logger.String("albumID", album.UUID), logger.Int("userID", int(userID)))
	}

	return album, nil
}

// generateSessionToken 生成随机会话令牌
func generateSessionToken() (string, error) {
	b := make([]byte, 32) // 256 bits
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

// generateUUID 生成UUID
func generateUUID() string {
	return uuid.New().String()
}
