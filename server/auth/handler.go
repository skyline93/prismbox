package auth

import (
	"errors"
	"server/core"
	"server/models"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AuthHandler struct {
	DB                    *gorm.DB
	JWTSecret             []byte
	AccessTokenExpiresIn  time.Duration
	RefreshTokenExpiresIn time.Duration
}

// --- DTOs (Data Transfer Objects) for Swagger ---

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
	Username string `json:"username" binding:"required" example:"newuser"`
	Password string `json:"password" binding:"required" example:"aVeryStrongPassword123"`
}

type UserLoginSuccessData struct {
	AccessToken  string `json:"access_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
	RefreshToken string `json:"refresh_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
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

type UserProfileResponse struct {
	ID        uint      `json:"id" example:"1"`
	Username  string    `json:"username" example:"testuser"`
	Email     string    `json:"email" example:"testuser@example.com"`
	CreatedAt time.Time `json:"created_at" example:"2023-10-27T10:00:00Z"`
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
// @Description  使用用户名和密码进行登录，成功后返回访问令牌和刷新令牌
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        credentials body UserLoginInput true "用户登录凭证"
// @Success      200 {object} core.ApiResponse{data=UserLoginSuccessData} "登录成功"
// @Failure      400 {object} core.ApiResponse "请求参数错误、用户名或密码无效或服务器内部错误"
// @Router       /auth/login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var input UserLoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.ErrorAuth(c, "Invalid input: "+err.Error())
		return
	}

	var user models.User
	if err := h.DB.Where("username = ?", input.Username).First(&user).Error; err != nil {
		core.ErrorAuth(c, "Invalid username or password")
		return
	}

	if !CheckPasswordHash(input.Password, user.Password) {
		core.ErrorAuth(c, "Invalid username or password")
		return
	}

	accessToken, err := GenerateAccessToken(user.ID, h.JWTSecret, h.AccessTokenExpiresIn)
	if err != nil {
		core.ErrorAuth(c, "Failed to generate access token")
		return
	}

	refreshToken, err := GenerateRefreshToken(user.ID, h.JWTSecret, h.RefreshTokenExpiresIn)
	if err != nil {
		core.ErrorAuth(c, "Failed to generate refresh token")
		return
	}

	rtRecord := models.RefreshToken{
		UserID:    user.ID,
		Token:     refreshToken,
		ExpiresAt: time.Now().Add(time.Hour * 24 * 30),
	}
	if err := h.DB.Create(&rtRecord).Error; err != nil {
		core.ErrorAuth(c, "Failed to save refresh token")
		return
	}

	core.Success(c, "Login successful", UserLoginSuccessData{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	})
}

// RefreshToken godoc
// @Summary      刷新访问令牌
// @Description  使用一个有效的、未过期的刷新令牌来获取一个新的访问令牌
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        token body RefreshTokenInput true "刷新令牌"
// @Success      200 {object} core.ApiResponse{data=RefreshTokenSuccessData} "成功刷新令牌"
// @Failure      400 {object} core.ApiResponse "请求参数错误或刷新令牌无效、已过期或已被撤销"
// @Router       /auth/refresh [post]
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

	// 3. 将数据库模型映射到安全的响应DTO
	// 这是非常关键的一步，确保不会泄露密码哈希等敏感字段
	userProfile := UserProfileResponse{
		ID:        user.ID,
		Username:  user.Username,
		Email:     user.Email,
		CreatedAt: user.CreatedAt,
	}

	// 4. 返回成功响应
	core.Success(c, "User profile retrieved successfully", userProfile)
}
