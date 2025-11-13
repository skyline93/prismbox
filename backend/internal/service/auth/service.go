package auth

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/MicahParks/keyfunc/v3"
	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/pkg/logger"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

const (
	appleAuthKeysURL = "https://appleid.apple.com/auth/keys"

	fileTypeJPG  = ".jpg"
	fileTypeJPEG = ".jpeg"
	fileTypePNG  = ".png"
)

var (
	// ErrUserAlreadyExists 用户已存在错误。
	ErrUserAlreadyExists = errors.New("user already exists")
	// ErrInvalidCredentials 登录凭证无效。
	ErrInvalidCredentials = errors.New("invalid email or password")
	// ErrPasswordAlreadySet 密码已设置。
	ErrPasswordAlreadySet = errors.New("password already set")
	// ErrRefreshTokenInvalid 刷新令牌无效。
	ErrRefreshTokenInvalid = errors.New("refresh token is invalid or revoked")
	// ErrRefreshTokenExpired 刷新令牌已过期。
	ErrRefreshTokenExpired = errors.New("refresh token is expired")
	// ErrAppleTokenInvalid Apple Token 无效。
	ErrAppleTokenInvalid = errors.New("apple identity token is invalid")
	// ErrAvatarTooLarge 头像过大。
	ErrAvatarTooLarge = errors.New("avatar file size exceeds limit")
	// ErrAvatarFormatNotSupported 头像格式不支持。
	ErrAvatarFormatNotSupported = errors.New("unsupported avatar file format")
)

// Service 定义认证服务接口。
type Service interface {
	Register(ctx context.Context, input RegisterInput) (*models.User, error)
	Login(ctx context.Context, email, password string) (*TokenPair, error)
	AppleLogin(ctx context.Context, identityToken string, fullName *AppleFullName) (*TokenPair, error)
	SetPassword(ctx context.Context, userID uint, password string) error
	RefreshToken(ctx context.Context, refreshToken string) (string, error)
	Logout(ctx context.Context, refreshToken string) error
	GetProfile(ctx context.Context, userID uint) (*Profile, error)
	UploadAvatar(ctx context.Context, userID uint, originalFilename string, content io.Reader, size int64) (string, error)
	ValidateAccessToken(token string) (uint, error)
}

// RegisterInput 注册输入参数。
type RegisterInput struct {
	Username string
	Email    string
	Password string
}

// AppleFullName Apple 授权返回的姓名信息。
type AppleFullName struct {
	GivenName  string
	FamilyName string
}

// TokenPair 访问令牌与刷新令牌。
type TokenPair struct {
	AccessToken  string
	RefreshToken string
}

// Profile 用户资料。
type Profile struct {
	ID           uint      `json:"id"`
	Username     string    `json:"username"`
	Email        string    `json:"email"`
	AvatarURL    string    `json:"avatar_url,omitempty"`
	HasPassword  bool      `json:"has_password"`
	UsedStorage  int64     `json:"used_storage,omitempty"`
	TotalStorage int64     `json:"total_storage,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type service struct {
	logger logger.Logger

	db *gorm.DB

	userRepo         repository.UserRepository
	authProviderRepo repository.AuthProviderRepository
	refreshTokenRepo repository.RefreshTokenRepository

	authCfg   *modules.AuthConfig
	serverCfg *modules.ServerConfig

	jwtSecret  []byte
	accessTTL  time.Duration
	refreshTTL time.Duration

	avatarSavePath string
	avatarBaseURL  string
	maxAvatarSize  int64

	appleBundleID string
	appleKeyFunc  keyfunc.Keyfunc
}

// NewService 创建认证服务。
func NewService(
	db *gorm.DB,
	userRepo repository.UserRepository,
	authProviderRepo repository.AuthProviderRepository,
	refreshTokenRepo repository.RefreshTokenRepository,
	authCfg *modules.AuthConfig,
	serverCfg *modules.ServerConfig,
) (Service, error) {
	if db == nil {
		return nil, fmt.Errorf("db is required")
	}
	if userRepo == nil || authProviderRepo == nil || refreshTokenRepo == nil {
		return nil, fmt.Errorf("repositories are required")
	}
	if authCfg == nil {
		return nil, fmt.Errorf("auth config is required")
	}
	if serverCfg == nil {
		return nil, fmt.Errorf("server config is required")
	}

	var appleKey keyfunc.Keyfunc
	var err error
	if authCfg.AppleAppBundleID != "" {
		appleKey, err = keyfunc.NewDefault([]string{appleAuthKeysURL})
		if err != nil {
			return nil, fmt.Errorf("init apple jwks: %w", err)
		}
	}

	avatarBaseURL := strings.TrimRight(serverCfg.PublicBaseURL, "/") + "/static/avatars/"

	return &service{
		logger: logger.New("service.auth"),

		db: db,

		userRepo:         userRepo,
		authProviderRepo: authProviderRepo,
		refreshTokenRepo: refreshTokenRepo,

		authCfg:   authCfg,
		serverCfg: serverCfg,

		jwtSecret:  []byte(authCfg.JWTSecret),
		accessTTL:  authCfg.AccessTokenExpiresIn.Duration(),
		refreshTTL: authCfg.RefreshTokenExpiresIn.Duration(),

		avatarSavePath: authCfg.AvatarSavePath,
		avatarBaseURL:  avatarBaseURL,
		maxAvatarSize:  authCfg.MaxAvatarSize.Int64(),

		appleBundleID: authCfg.AppleAppBundleID,
		appleKeyFunc:  appleKey,
	}, nil
}

func (s *service) Register(ctx context.Context, input RegisterInput) (*models.User, error) {
	exists, err := s.userRepo.ExistsByUsernameOrEmail(ctx, input.Username, input.Email)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, ErrUserAlreadyExists
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		return nil, err
	}

	user := &models.User{
		Username: input.Username,
		Email:    input.Email,
		Password: hashedPassword,
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	return user, nil
}

func (s *service) Login(ctx context.Context, email, password string) (*TokenPair, error) {
	user, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}

	if user.Password == "" {
		return nil, ErrInvalidCredentials
	}

	if !CheckPasswordHash(password, user.Password) {
		return nil, ErrInvalidCredentials
	}

	return s.generateAndSaveTokens(ctx, user.ID)
}

func (s *service) AppleLogin(ctx context.Context, identityToken string, fullName *AppleFullName) (*TokenPair, error) {
	if s.appleBundleID == "" || s.appleKeyFunc == nil {
		return nil, fmt.Errorf("apple login is not configured")
	}

	claims, err := s.validateAppleToken(ctx, identityToken)
	if err != nil {
		return nil, err
	}

	email := strings.ToLower(claims.Email)
	if email == "" {
		return nil, ErrAppleTokenInvalid
	}

	user, err := s.userRepo.FindByEmail(ctx, email)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	appleUserID := claims.Subject

	if errors.Is(err, gorm.ErrRecordNotFound) {
		var createdUser *models.User
		err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
			username := ""
			if fullName != nil && fullName.GivenName != "" {
				username = fullName.GivenName
			}
			if username == "" {
				username = fmt.Sprintf("user-%d", time.Now().UnixNano())
			}

			newUser := &models.User{
				Email:    email,
				Username: username,
			}

			if err := tx.Create(newUser).Error; err != nil {
				return err
			}

			provider := &models.AuthProvider{
				UserID:         newUser.ID,
				ProviderName:   "apple",
				ProviderUserID: appleUserID,
			}

			if err := tx.Create(provider).Error; err != nil {
				return err
			}

			createdUser = newUser
			return nil
		})
		if err != nil {
			return nil, err
		}
		user = createdUser
	} else {
		existingProvider, err := s.authProviderRepo.FindByProviderUserID(ctx, "apple", appleUserID)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, err
		}

		if existingProvider != nil && existingProvider.UserID != user.ID {
			return nil, fmt.Errorf("apple account already linked to another user")
		}

		if existingProvider == nil {
			provider := &models.AuthProvider{
				UserID:         user.ID,
				ProviderName:   "apple",
				ProviderUserID: appleUserID,
			}
			if err := s.authProviderRepo.Create(ctx, provider); err != nil {
				return nil, err
			}
		}
	}

	return s.generateAndSaveTokens(ctx, user.ID)
}

func (s *service) SetPassword(ctx context.Context, userID uint, password string) error {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		return err
	}

	if user.Password != "" {
		return ErrPasswordAlreadySet
	}

	hashed, err := HashPassword(password)
	if err != nil {
		return err
	}

	return s.userRepo.UpdatePassword(ctx, userID, hashed)
}

func (s *service) RefreshToken(ctx context.Context, token string) (string, error) {
	record, err := s.refreshTokenRepo.FindActiveByToken(ctx, token)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", ErrRefreshTokenInvalid
		}
		return "", err
	}

	if time.Now().After(record.ExpiresAt) {
		return "", ErrRefreshTokenExpired
	}

	accessToken, err := GenerateAccessToken(record.UserID, s.jwtSecret, s.accessTTL)
	if err != nil {
		return "", err
	}

	return accessToken, nil
}

func (s *service) Logout(ctx context.Context, token string) error {
	ok, err := s.refreshTokenRepo.RevokeByToken(ctx, token)
	if err != nil {
		return err
	}
	if !ok {
		return ErrRefreshTokenInvalid
	}
	return nil
}

func (s *service) GetProfile(ctx context.Context, userID uint) (*Profile, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	avatarURL := ""
	if user.Avatar != "" {
		avatarURL = s.avatarBaseURL + user.Avatar
	}

	return &Profile{
		ID:           user.ID,
		Username:     user.Username,
		Email:        user.Email,
		AvatarURL:    avatarURL,
		HasPassword:  user.Password != "",
		UsedStorage:  20,
		TotalStorage: 100,
		CreatedAt:    user.CreatedAt,
	}, nil
}

func (s *service) UploadAvatar(ctx context.Context, userID uint, originalFilename string, content io.Reader, size int64) (string, error) {
	if size > s.maxAvatarSize {
		return "", ErrAvatarTooLarge
	}

	ext := strings.ToLower(filepath.Ext(originalFilename))
	if ext != fileTypeJPG && ext != fileTypeJPEG && ext != fileTypePNG {
		return "", ErrAvatarFormatNotSupported
	}

	if err := os.MkdirAll(s.avatarSavePath, 0o755); err != nil {
		return "", fmt.Errorf("create avatar directory: %w", err)
	}

	filename := fmt.Sprintf("%d-%d%s", userID, time.Now().Unix(), ext)
	savePath := filepath.Join(s.avatarSavePath, filename)

	file, err := os.Create(savePath)
	if err != nil {
		return "", fmt.Errorf("create avatar file: %w", err)
	}
	defer file.Close()

	if _, err := io.Copy(file, content); err != nil {
		return "", fmt.Errorf("write avatar file: %w", err)
	}

	if err := s.userRepo.UpdateAvatar(ctx, userID, filename); err != nil {
		return "", err
	}

	return s.avatarBaseURL + filename, nil
}

func (s *service) ValidateAccessToken(token string) (uint, error) {
	return ValidateToken(token, s.jwtSecret)
}

func (s *service) generateAndSaveTokens(ctx context.Context, userID uint) (*TokenPair, error) {
	accessToken, err := GenerateAccessToken(userID, s.jwtSecret, s.accessTTL)
	if err != nil {
		return nil, err
	}

	refreshToken, err := GenerateRefreshToken(userID, s.jwtSecret, s.refreshTTL)
	if err != nil {
		return nil, err
	}

	record := &models.RefreshToken{
		UserID:    userID,
		Token:     refreshToken,
		ExpiresAt: time.Now().Add(s.refreshTTL),
	}

	if err := s.refreshTokenRepo.Create(ctx, record); err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *service) validateAppleToken(ctx context.Context, identityToken string) (*AppleClaims, error) {
	var claims AppleClaims

	token, err := jwt.ParseWithClaims(identityToken, &claims, s.appleKeyFunc.Keyfunc)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrAppleTokenInvalid, err)
	}

	if !token.Valid {
		return nil, ErrAppleTokenInvalid
	}

	if claims.Issuer != "https://appleid.apple.com" {
		return nil, ErrAppleTokenInvalid
	}

	if len(claims.Audience) == 0 {
		return nil, ErrAppleTokenInvalid
	}

	validAudience := false
	for _, aud := range claims.Audience {
		if aud == s.appleBundleID {
			validAudience = true
			break
		}
	}
	if !validAudience {
		return nil, ErrAppleTokenInvalid
	}

	return &claims, nil
}
