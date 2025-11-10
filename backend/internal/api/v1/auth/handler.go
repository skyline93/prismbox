package auth

import (
	"errors"
	"fmt"

	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/response"
	authservice "github.com/album/backend/internal/service/auth"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Handler 认证处理器。
type Handler struct {
	authService authservice.Service
}

// NewHandler 创建认证处理器。
func NewHandler(authService authservice.Service) *Handler {
	return &Handler{
		authService: authService,
	}
}

// RegisterInput 用户注册请求。
type RegisterInput struct {
	Username string `json:"username" binding:"required"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
}

type registerSuccessData struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
}

// LoginInput 用户登录请求。
type LoginInput struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type loginSuccessData struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

// AppleLoginInput Apple 登录请求。
type AppleLoginInput struct {
	IdentityToken string `json:"identityToken" binding:"required"`
	FullName      *struct {
		GivenName  string `json:"givenName"`
		FamilyName string `json:"familyName"`
	} `json:"fullName"`
}

// SetPasswordInput 设置密码请求。
type SetPasswordInput struct {
	Password string `json:"password" binding:"required,min=8"`
}

// RefreshTokenInput 刷新令牌请求。
type RefreshTokenInput struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// LogoutInput 登出请求。
type LogoutInput struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type uploadAvatarSuccessData struct {
	AvatarURL string `json:"avatar_url"`
}

// Register 用户注册。
func (h *Handler) Register(c *gin.Context) {
	var input RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	user, err := h.authService.Register(c.Request.Context(), authservice.RegisterInput{
		Username: input.Username,
		Email:    input.Email,
		Password: input.Password,
	})
	if err != nil {
		if errors.Is(err, authservice.ErrUserAlreadyExists) {
			response.Error(c, "Username or email already exists")
			return
		}
		response.Error(c, "Failed to create user")
		return
	}

	response.Success(c, "User registered successfully", registerSuccessData{
		UserID:   user.ID,
		Username: user.Username,
	})
}

// Login 用户登录。
func (h *Handler) Login(c *gin.Context) {
	var input LoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	tokens, err := h.authService.Login(c.Request.Context(), input.Email, input.Password)
	if err != nil {
		if errors.Is(err, authservice.ErrInvalidCredentials) {
			response.ErrorAuth(c, "Invalid email or password")
			return
		}
		response.Error(c, "Failed to process tokens")
		return
	}

	response.Success(c, "Login successful", loginSuccessData{
		AccessToken:  tokens.AccessToken,
		RefreshToken: tokens.RefreshToken,
	})
}

// AppleLogin Apple 登录。
func (h *Handler) AppleLogin(c *gin.Context) {
	var input AppleLoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	var fullName *authservice.AppleFullName
	if input.FullName != nil {
		fullName = &authservice.AppleFullName{
			GivenName:  input.FullName.GivenName,
			FamilyName: input.FullName.FamilyName,
		}
	}

	tokens, err := h.authService.AppleLogin(c.Request.Context(), input.IdentityToken, fullName)
	if err != nil {
		if errors.Is(err, authservice.ErrAppleTokenInvalid) {
			response.ErrorAuth(c, "Invalid Apple token: "+err.Error())
			return
		}
		response.Error(c, "Invalid Apple token: "+err.Error())
		return
	}

	response.Success(c, "Apple login successful", loginSuccessData{
		AccessToken:  tokens.AccessToken,
		RefreshToken: tokens.RefreshToken,
	})
}

// SetPassword 设置密码。
func (h *Handler) SetPassword(c *gin.Context) {
	var input SetPasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	if err := h.authService.SetPassword(c.Request.Context(), userID, input.Password); err != nil {
		if errors.Is(err, authservice.ErrPasswordAlreadySet) {
			response.Error(c, "Password has already been set for this account.")
			return
		}
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.Error(c, "User not found")
			return
		}
		response.Error(c, "Failed to update password")
		return
	}

	response.NoContent(c)
}

// RefreshToken 刷新访问令牌。
func (h *Handler) RefreshToken(c *gin.Context) {
	var input RefreshTokenInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.ErrorAuth(c, "Invalid input: "+err.Error())
		return
	}

	accessToken, err := h.authService.RefreshToken(c.Request.Context(), input.RefreshToken)
	if err != nil {
		switch {
		case errors.Is(err, authservice.ErrRefreshTokenInvalid):
			response.Error(c, "Invalid or revoked refresh token")
		case errors.Is(err, authservice.ErrRefreshTokenExpired):
			response.ErrorAuth(c, "Refresh token is expired")
		default:
			response.ErrorAuth(c, "Failed to generate new access token")
		}
		return
	}

	response.Success(c, "Token refreshed successfully", map[string]string{
		"access_token": accessToken,
	})
}

// Logout 登出。
func (h *Handler) Logout(c *gin.Context) {
	var input LogoutInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	if err := h.authService.Logout(c.Request.Context(), input.RefreshToken); err != nil {
		if errors.Is(err, authservice.ErrRefreshTokenInvalid) {
			response.Error(c, "Invalid refresh token provided")
			return
		}
		response.Error(c, "Database error during logout")
		return
	}

	response.Success(c, "Successfully logged out", nil)
}

// GetProfile 获取用户资料。
func (h *Handler) GetProfile(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	profile, err := h.authService.GetProfile(c.Request.Context(), userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.Error(c, "User not found")
			return
		}
		response.Error(c, "Database error")
		return
	}

	response.Success(c, "User profile retrieved successfully", profile)
}

// UploadAvatar 上传头像。
func (h *Handler) UploadAvatar(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	fileHeader, err := c.FormFile("avatar")
	if err != nil {
		response.Error(c, "Failed to get file from form: "+err.Error())
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		response.Error(c, "Failed to open uploaded file: "+err.Error())
		return
	}
	defer file.Close()

	avatarURL, err := h.authService.UploadAvatar(
		c.Request.Context(),
		userID,
		fileHeader.Filename,
		file,
		fileHeader.Size,
	)
	if err != nil {
		switch {
		case errors.Is(err, authservice.ErrAvatarTooLarge):
			response.Error(c, "File size exceeds the limit of 5MB")
		case errors.Is(err, authservice.ErrAvatarFormatNotSupported):
			response.Error(c, "Invalid file type. Only jpg, jpeg, and png are allowed.")
		default:
			response.Error(c, fmt.Sprintf("Failed to save file: %v", err))
		}
		return
	}

	response.Success(c, "Avatar uploaded successfully", uploadAvatarSuccessData{
		AvatarURL: avatarURL,
	})
}
