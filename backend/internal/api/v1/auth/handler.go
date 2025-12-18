package auth

import (
	"errors"
	"fmt"

	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/response"
	authservice "github.com/album/backend/internal/service/auth"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Handler 认证处理器。
type Handler struct {
	authService authservice.Service
	log         logger.Logger
}

// NewHandler 创建认证处理器。
func NewHandler(authService authservice.Service) *Handler {
	return &Handler{
		authService: authService,
		log:         logger.New("api.v1.auth"),
	}
}

// RegisterInput 用户注册请求。
// @Description 用户注册请求体
type RegisterInput struct {
	Username string `json:"username" binding:"required" example:"john_doe"`            // 用户名
	Email    string `json:"email" binding:"required,email" example:"john@example.com"` // 邮箱地址
	Password string `json:"password" binding:"required,min=8" example:"password123"`   // 密码（至少8位）
}

// registerSuccessData 注册成功响应数据
type registerSuccessData struct {
	UserID   uint   `json:"user_id" example:"1"`         // 用户ID
	Username string `json:"username" example:"john_doe"` // 用户名
}

// LoginInput 用户登录请求。
// @Description 用户登录请求体
type LoginInput struct {
	Email    string `json:"email" binding:"required,email" example:"john@example.com"` // 邮箱地址
	Password string `json:"password" binding:"required" example:"password123"`         // 密码
}

// loginSuccessData 登录成功响应数据
type loginSuccessData struct {
	AccessToken  string `json:"access_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`  // 访问令牌
	RefreshToken string `json:"refresh_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."` // 刷新令牌
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

// Register 用户注册
// @Summary      用户注册
// @Description  创建新用户账号，需要提供用户名、邮箱和密码
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body RegisterInput true "注册信息"
// @Success      200 {object} response.ApiResponse{data=registerSuccessData} "注册成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误或用户名/邮箱已存在"
// @Router       /auth/register [post]
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

// Login 用户登录
// @Summary      用户登录
// @Description  使用邮箱和密码登录，返回访问令牌和刷新令牌
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body LoginInput true "登录信息"
// @Success      200 {object} response.ApiResponse{data=loginSuccessData} "登录成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "认证失败，邮箱或密码错误"
// @Router       /auth/login [post]
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

// AppleLogin Apple 登录
// @Summary      Apple 登录
// @Description  使用 Apple ID 登录，返回访问令牌和刷新令牌
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body AppleLoginInput true "Apple 登录信息"
// @Success      200 {object} response.ApiResponse{data=loginSuccessData} "登录成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "Apple token 无效"
// @Router       /auth/apple/login [post]
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

// SetPassword 设置密码
// @Summary      设置密码
// @Description  为用户账号设置密码（需要认证）
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body SetPasswordInput true "密码信息"
// @Success      204 "密码设置成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误或密码已设置"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Failure      404 {object} response.ApiResponse "用户不存在"
// @Router       /auth/password/set [post]
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

// RefreshToken 刷新访问令牌
// @Summary      刷新访问令牌
// @Description  使用刷新令牌获取新的访问令牌
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body RefreshTokenInput true "刷新令牌信息"
// @Success      200 {object} response.ApiResponse{data=map[string]string} "刷新成功"
// @Failure      400 {object} response.ApiResponse "刷新令牌无效或已撤销"
// @Failure      401 {object} response.ApiResponse "刷新令牌已过期"
// @Router       /auth/refresh [post]
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

// Logout 登出
// @Summary      用户登出
// @Description  撤销刷新令牌，登出用户
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body LogoutInput true "登出信息"
// @Success      200 {object} response.ApiResponse "登出成功"
// @Failure      400 {object} response.ApiResponse "刷新令牌无效"
// @Router       /auth/logout [post]
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

// GetProfile 获取用户资料
// @Summary      获取用户资料
// @Description  获取当前登录用户的资料信息（需要认证）
// @Tags         Auth
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      400 {object} response.ApiResponse "用户不存在"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /auth/profile [get]
func (h *Handler) GetProfile(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 获取设备信息（用于统计和审计）
	deviceID := middleware.MustGetDeviceID(c)
	deviceType := middleware.MustGetDeviceType(c)

	h.log.Info("Getting user profile",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
	)

	profile, err := h.authService.GetProfile(c.Request.Context(), userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			h.log.Warn("User not found",
				logger.Uint("user_id", userID),
				logger.String("device_id", deviceID),
			)
			response.Error(c, "User not found")
			return
		}
		h.log.Error("Database error getting profile",
			logger.Uint("user_id", userID),
			logger.Error(err),
		)
		response.Error(c, "Database error")
		return
	}

	h.log.Info("User profile retrieved successfully",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
	)

	response.Success(c, "User profile retrieved successfully", profile)
}

// UploadAvatar 上传头像
// @Summary      上传头像
// @Description  上传用户头像图片（需要认证），支持 jpg、jpeg、png 格式，最大 5MB
// @Tags         Auth
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        avatar formData file true "头像图片文件"
// @Success      200 {object} response.ApiResponse{data=uploadAvatarSuccessData} "上传成功"
// @Failure      400 {object} response.ApiResponse "文件格式不支持或文件过大"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /auth/avatar [post]
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
