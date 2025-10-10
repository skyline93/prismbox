// auth/handler.go
package auth

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"server/core"
	"server/models"
	"strings"
	"time"

	"github.com/MicahParks/keyfunc/v3"
	ung "github.com/dillonstreator/go-unique-name-generator"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

// AppleAuthKeysURL 是 Apple 用于签发 Identity Token 的公钥集地址
const AppleAuthKeysURL = "https://appleid.apple.com/auth/keys"

const (
	AvatarSavePath = "./public/avatars/"
	MaxAvatarSize  = 5 << 20 // 5 MB
)

type AuthHandler struct {
	DB                    *gorm.DB
	AvatarBaseURL         string
	JWTSecret             []byte
	AccessTokenExpiresIn  time.Duration
	RefreshTokenExpiresIn time.Duration
	AppleAppBundleID      string
	appleKeyFunc          keyfunc.Keyfunc // <-- 持有 keyfunc.Keyfunc 接口
}

// --- DTOs (Data Transfer Objects) ---

type UserRegisterInput struct {
	Username string `json:"username" binding:"required" example:"newuser"`
	Email    string `json:"email" binding:"required,email" example:"user@example.com"`
	Password string `json:"password" binding:"required,min=8" example:"aVeryStrongPassword123"`
}

type UserRegisterSuccessData struct {
	UserID   uint   `json:"user_id" example:"1"`
	Username string `json:"username" example:"newuser"`
}

type UserLoginInput struct {
	Email    string `json:"email" binding:"required,email" example:"user@example.com"` // 修改: 使用 Email 登录
	Password string `json:"password" binding:"required" example:"aVeryStrongPassword123"`
}

type UserLoginSuccessData struct {
	AccessToken  string `json:"access_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
	RefreshToken string `json:"refresh_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
}

// 新增: Apple 登录 DTO
type AppleLoginInput struct {
	IdentityToken string `json:"identityToken" binding:"required"`
	FullName      *struct {
		GivenName  string `json:"givenName"`
		FamilyName string `json:"familyName"`
	} `json:"fullName"` // 首次授权时客户端传递，可能为 null
}

// 新增: 设置密码 DTO
type SetPasswordInput struct {
	Password string `json:"password" binding:"required,min=8"`
}

type RefreshTokenInput struct {
	RefreshToken string `json:"refresh_token" binding:"required" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
}

type RefreshTokenSuccessData struct {
	AccessToken string `json:"access_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
}

type LogoutInput struct {
	RefreshToken string `json:"refresh_token" binding:"required" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
}

// 修改: 用户信息 DTO
type UserProfileResponse struct {
	ID           uint      `json:"id" example:"1"`
	Username     string    `json:"username" example:"testuser"`
	Email        string    `json:"email" example:"testuser@example.com"`
	AvatarURL    string    `json:"avatar_url,omitempty" example:"http://localhost:8080/static/avatars/1-1678886400.png"`
	HasPassword  bool      `json:"has_password"` // 新增: 便于前端判断
	UsedStorage  int64     `json:"used_storage,omitempty"`
	TotalStorage int64     `json:"total_storage,omitempty"`
	CreatedAt    time.Time `json:"created_at" example:"2023-10-27T10:00:00Z"`
}

type UploadAvatarSuccessData struct {
	AvatarURL string `json:"avatar_url" example:"http://localhost:8080/static/avatars/1-1678886400.png"`
}

// --- 辅助函数 (Apple Token 验证) ---

// AppleClaims 定义了从 Apple Identity Token 中解析出的数据结构
type AppleClaims struct {
	jwt.RegisteredClaims
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	IsPrivate     bool   `json:"is_private_email"`
}

func NewAuthHandler(db *gorm.DB, cfg *core.Config) (*AuthHandler, error) {
	// 1. 使用 keyfunc.NewDefault 创建一个 Keyfunc 实例。
	//    它接收一个 URL 的 slice。
	//    这个函数会自动处理 JWKS 的获取、缓存和后台刷新。
	jwks, err := keyfunc.NewDefault([]string{AppleAuthKeysURL})
	if err != nil {
		return nil, fmt.Errorf("failed to create JWKS from Apple URL: %w", err)
	}

	return &AuthHandler{
		DB:                    db,
		AvatarBaseURL:         cfg.PublicBaseURL + "/static/avatars/",
		JWTSecret:             cfg.JWTSecret,
		AccessTokenExpiresIn:  cfg.AccessTokenExpiresIn,
		RefreshTokenExpiresIn: cfg.RefreshTokenExpiresIn,
		AppleAppBundleID:      cfg.AppleAppBundleID,
		// 2. 将创建的 jwks 实例（它实现了 keyfunc.Keyfunc 接口）赋值给字段。
		appleKeyFunc: jwks,
	}, nil
}

func (h *AuthHandler) ValidateAppleToken(ctx context.Context, identityToken string) (*AppleClaims, error) {
	var claims AppleClaims
	// h.appleKeyFunc 实现了 Keyfunc 方法，可以直接作为参数传递给 jwt.ParseWithClaims
	token, err := jwt.ParseWithClaims(identityToken, &claims, h.appleKeyFunc.Keyfunc)
	if err != nil {
		return nil, fmt.Errorf("failed to parse or validate apple token signature: %w", err)
	}

	if !token.Valid {
		return nil, errors.New("apple token is invalid")
	}

	if claims.Issuer != "https://appleid.apple.com" {
		return nil, fmt.Errorf("invalid token issuer. expected 'https://appleid.apple.com', got '%s'", claims.Issuer)
	}

	isAudienceValid := false
	for _, aud := range claims.Audience {
		if aud == h.AppleAppBundleID {
			isAudienceValid = true
			break
		}
	}
	if !isAudienceValid {
		return nil, fmt.Errorf("invalid token audience. expected '%s', got '%v'", h.AppleAppBundleID, claims.Audience)
	}

	return &claims, nil
}

// --- Handlers ---

// Register godoc
// @Summary      注册新用户
// @Description  根据用户名、邮箱和密码创建一个新的用户账户
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        credentials body UserRegisterInput true "用户注册信息"
// @Success      200 {object} core.ApiResponse{data=UserRegisterSuccessData} "用户注册成功"
// @Failure      400 {object} core.ApiResponse "请求参数错误、用户已存在或服务器内部错误"
// @Router       /auth/register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var input UserRegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	var existingUser models.User
	if err := h.DB.Where("username = ? OR email = ?", input.Username, input.Email).First(&existingUser).Error; err == nil {
		core.Error(c, "Username or email already exists")
		return
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		core.Error(c, "Failed to hash password")
		return
	}

	user := models.User{Username: input.Username, Email: input.Email, Password: string(hashedPassword)}
	if err := h.DB.Create(&user).Error; err != nil {
		core.Error(c, "Failed to create user")
		return
	}

	core.Success(c, "User registered successfully", UserRegisterSuccessData{
		UserID:   user.ID,
		Username: user.Username,
	})
}

// Login godoc
// @Summary      用户登录
// @Description  使用邮箱和密码进行登录，成功后返回访问令牌和刷新令牌
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        credentials body UserLoginInput true "用户登录凭证"
// @Success      200 {object} core.ApiResponse{data=UserLoginSuccessData} "登录成功"
// @Failure      400 {object} core.ApiResponse "请求参数错误"
// @Failure      401 {object} core.ApiResponse "邮箱或密码无效，或该账户需通过 Apple 登录"
// @Router       /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var input UserLoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	var user models.User
	// --- 关键修改: 使用 Email 进行查询 ---
	if err := h.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		core.ErrorAuth(c, "Invalid email or password")
		return
	}

	// --- 关键修改: 检查用户是否设置了密码 ---
	if user.Password == "" {
		core.ErrorAuth(c, "Please log in with Apple or set a password for your account.")
		return
	}

	if !CheckPasswordHash(input.Password, user.Password) {
		core.ErrorAuth(c, "Invalid email or password")
		return
	}

	// 生成并保存 tokens (逻辑不变)
	accessToken, refreshToken, err := h.generateAndSaveTokens(user.ID)
	if err != nil {
		core.Error(c, "Failed to process tokens: "+err.Error())
		return
	}

	core.Success(c, "Login successful", UserLoginSuccessData{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

// AppleLogin godoc
// @Summary      通过 Apple ID 登录或注册
// @Description  使用从 Apple 获取的 identityToken 进行登录。如果用户不存在，则创建新用户；如果邮箱已存在，则关联账户。
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        credentials body AppleLoginInput true "Apple 登录凭证"
// @Success      200 {object} core.ApiResponse{data=UserLoginSuccessData} "登录成功"
// @Failure      400 {object} core.ApiResponse "请求参数错误"
// @Failure      401 {object} core.ApiResponse "Apple Token 验证失败"
// @Router       /auth/apple/login [post]
func (h *AuthHandler) AppleLogin(c *gin.Context) {
	var input AppleLoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	// 1. 验证 Apple Identity Token
	claims, err := h.ValidateAppleToken(c, input.IdentityToken)
	if err != nil {
		core.ErrorAuth(c, "Invalid Apple token: "+err.Error())
		return
	}

	appleUserID := claims.Subject // Apple 用户的唯一 ID ('sub')
	email := claims.Email

	// 2. 核心逻辑：通过邮箱查找用户
	var user models.User
	err = h.DB.Where("email = ?", email).First(&user).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		// 场景 A: 邮箱不存在 -> 全新注册
		tx := h.DB.Begin()

		// 创建 User，Password 为空
		newUser := models.User{
			Email: email,
			// 如果客户端首次提供了姓名，则使用
			Username: func() string {
				if input.FullName != nil && input.FullName.GivenName != "" {
					return input.FullName.GivenName
				}
				generator := ung.NewUniqueNameGenerator()
				return fmt.Sprintf("%d", generator.UniquenessCount())
			}(),
		}
		if err := tx.Create(&newUser).Error; err != nil {
			tx.Rollback()
			core.Error(c, "Failed to create user account")
			return
		}

		// 创建 AuthProvider 链接
		provider := models.AuthProvider{
			UserID:         newUser.ID,
			ProviderName:   "apple",
			ProviderUserID: appleUserID,
		}
		if err := tx.Create(&provider).Error; err != nil {
			tx.Rollback()
			core.Error(c, "Failed to link Apple account")
			return
		}

		if err := tx.Commit().Error; err != nil {
			core.Error(c, "Failed to complete registration transaction")
			return
		}
		user = newUser // 后续JWT生成使用此新用户

	} else if err != nil {
		// 其他数据库错误
		core.Error(c, "Database error")
		return

	} else {
		// 场景 B: 邮箱已存在 -> 账户链接
		// 检查此 Apple ID 是否已链接到其他账户 (防止恶意操作)
		var existingProvider models.AuthProvider
		if res := h.DB.Where("provider_name = ? AND provider_user_id = ?", "apple", appleUserID).First(&existingProvider); res.Error == nil {
			if existingProvider.UserID != user.ID {
				core.Error(c, "This Apple ID is already linked to another account.")
				return
			}
			// 如果已链接到当前账户，则直接走登录流程，无需操作
		} else if errors.Is(res.Error, gorm.ErrRecordNotFound) {
			// 如果 Apple ID 未被任何账户链接，则为当前用户创建新的链接
			provider := models.AuthProvider{
				UserID:         user.ID,
				ProviderName:   "apple",
				ProviderUserID: appleUserID,
			}
			if err := h.DB.Create(&provider).Error; err != nil {
				core.Error(c, "Failed to link Apple ID to existing account")
				return
			}
		} else {
			core.Error(c, "Database error while checking provider")
			return
		}
	}

	// 3. 为找到的或新创建的用户生成 JWT
	accessToken, refreshToken, err := h.generateAndSaveTokens(user.ID)
	if err != nil {
		core.Error(c, "Failed to process tokens: "+err.Error())
		return
	}

	core.Success(c, "Apple login successful", UserLoginSuccessData{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

// SetPassword godoc
// @Summary      为账户设置密码
// @Description  允许通过第三方登录且未设置密码的用户创建一个密码
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        password body SetPasswordInput true "新密码"
// @Success      204 "密码设置成功"
// @Failure      400 {object} core.ApiResponse "请求参数错误或用户已设置密码"
// @Failure      401 {object} core.ApiResponse "未授权"
// @Security     BearerAuth
// @Router       /auth/password/set [post]
func (h *AuthHandler) SetPassword(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var input SetPasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		core.Error(c, "User not found")
		return
	}

	if user.Password != "" {
		core.Error(c, "Password has already been set for this account.")
		return
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		core.Error(c, "Failed to hash password")
		return
	}

	if err := h.DB.Model(&user).Update("password", string(hashedPassword)).Error; err != nil {
		core.Error(c, "Failed to update password")
		return
	}

	core.NoContent(c)
}

// RefreshToken 保持不变
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var input RefreshTokenInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.ErrorAuth(c, "Invalid input: "+err.Error())
		return
	}

	var refreshTokenRecord models.RefreshToken
	err := h.DB.Where("token = ? AND is_revoked = ?", input.RefreshToken, false).First(&refreshTokenRecord).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "Invalid or revoked refresh token")
			return
		}
		core.ErrorAuth(c, "Database error")
		return
	}

	if time.Now().After(refreshTokenRecord.ExpiresAt) {
		core.ErrorAuth(c, "Refresh token is expired")
		return
	}

	newAccessToken, err := GenerateAccessToken(refreshTokenRecord.UserID, h.JWTSecret, h.AccessTokenExpiresIn)
	if err != nil {
		core.ErrorAuth(c, "Failed to generate new access token")
		return
	}

	core.Success(c, "Token refreshed successfully", RefreshTokenSuccessData{
		AccessToken: newAccessToken,
	})
}

// Logout godoc
// @Summary      用户登出
// @Description  通过撤销指定的刷新令牌来实现服务端登出
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        token body LogoutInput true "刷新令牌"
// @Success      200 {object} core.ApiResponse "成功登出"
// @Failure      400 {object} core.ApiResponse "请求参数错误或令牌无效"
// @Router       /auth/logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	var input LogoutInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	result := h.DB.Model(&models.RefreshToken{}).Where("token = ?", input.RefreshToken).Update("is_revoked", true)
	if result.Error != nil {
		core.Error(c, "Database error during logout")
		return
	}

	if result.RowsAffected == 0 {
		core.Error(c, "Invalid refresh token provided")
		return
	}

	core.Success(c, "Successfully logged out", nil)
}

// GetProfile godoc
// @Summary      获取当前用户信息
// @Description  获取当前已认证用户的个人资料（不含敏感信息）
// @Tags         Authentication
// @Produce      json
// @Success      200 {object} core.ApiResponse{data=UserProfileResponse} "成功获取用户资料"
// @Failure      401 {object} core.ApiResponse "未授权或Token无效"
// @Failure      404 {object} core.ApiResponse "用户不存在（Token有效但用户已被删除）"
// @Security     BearerAuth
// @Router       /auth/profile [get]
func (h *AuthHandler) GetProfile(c *gin.Context) {
	// 1. 从认证中间件设置的上下文中获取用户ID
	userID := c.MustGet("userID").(uint)

	// 2. 从数据库中查找该用户
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "User not found")
			return
		}
		core.Error(c, "Database error")
		return
	}

	var avatarURL string
	if user.Avatar != "" {
		avatarURL = h.AvatarBaseURL + user.Avatar
	}

	// 映射到安全的响应DTO
	userProfile := UserProfileResponse{
		ID:           user.ID,
		Username:     user.Username,
		Email:        user.Email,
		AvatarURL:    avatarURL,
		HasPassword:  user.Password != "", // 新增字段的赋值
		UsedStorage:  20,
		TotalStorage: 100,
		CreatedAt:    user.CreatedAt,
	}

	core.Success(c, "User profile retrieved successfully", userProfile)
}

// UploadAvatar godoc
// @Summary      上传用户头像
// @Description  为当前认证的用户上传一个新的头像图片。上传成功后立即返回可访问的URL。
// @Tags         Authentication
// @Accept       multipart/form-data
// @Produce      json
// @Param        avatar formData file true "头像文件 (png, jpg, jpeg)，最大5MB"
// @Success      200 {object} core.ApiResponse{data=UploadAvatarSuccessData} "头像上传成功"
// @Failure      400 {object} core.ApiResponse "请求错误（如文件太大、格式不对、未上传文件等）"
// @Failure      401 {object} core.ApiResponse "未授权或Token无效"
// @Failure      500 {object} core.ApiResponse "服务器内部错误（如文件保存失败）"
// @Security     BearerAuth
// @Router       /auth/avatar [post]
func (h *AuthHandler) UploadAvatar(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	file, err := c.FormFile("avatar")
	if err != nil {
		core.Error(c, "Failed to get file from form: "+err.Error())
		return
	}

	if file.Size > MaxAvatarSize {
		core.Error(c, "File size exceeds the limit of 5MB")
		return
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
		core.Error(c, "Invalid file type. Only jpg, jpeg, and png are allowed.")
		return
	}

	newFilename := fmt.Sprintf("%d-%d%s", userID, time.Now().Unix(), ext)
	savePath := filepath.Join(AvatarSavePath, newFilename)

	if err := os.MkdirAll(AvatarSavePath, 0755); err != nil {
		core.Error(c, "Failed to create save directory: "+err.Error())
		return
	}

	if err := c.SaveUploadedFile(file, savePath); err != nil {
		core.Error(c, "Failed to save file: "+err.Error())
		return
	}

	if err := h.DB.Model(&models.User{}).Where("id = ?", userID).Update("avatar", newFilename).Error; err != nil {
		core.Error(c, "Failed to update user avatar in database")
		return
	}

	fullAvatarURL := h.AvatarBaseURL + newFilename
	core.Success(c, "Avatar uploaded successfully", UploadAvatarSuccessData{
		AvatarURL: fullAvatarURL,
	})
}

// 封装 Token 生成和存储逻辑
func (h *AuthHandler) generateAndSaveTokens(userID uint) (string, string, error) {
	accessToken, err := GenerateAccessToken(userID, h.JWTSecret, h.AccessTokenExpiresIn)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate access token")
	}

	refreshToken, err := GenerateRefreshToken(userID, h.JWTSecret, h.RefreshTokenExpiresIn)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate refresh token")
	}

	rtRecord := models.RefreshToken{
		UserID:    userID,
		Token:     refreshToken,
		ExpiresAt: time.Now().Add(h.RefreshTokenExpiresIn),
	}
	if err := h.DB.Create(&rtRecord).Error; err != nil {
		return "", "", fmt.Errorf("failed to save refresh token")
	}

	return accessToken, refreshToken, nil
}
