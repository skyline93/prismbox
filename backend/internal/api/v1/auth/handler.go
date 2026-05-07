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

// RegisterInput is the user registration request body.
// @Description User registration request body
type RegisterInput struct {
	Username string `json:"username" binding:"required" example:"john_doe"`            // Username
	Email    string `json:"email" binding:"required,email" example:"john@example.com"` // Email
	Password string `json:"password" binding:"required,min=8" example:"password123"`   // Password (min 8 characters)
}

// registerSuccessData is returned on successful registration.
type registerSuccessData struct {
	UserID   uint   `json:"user_id" example:"1"`         // User ID
	Username string `json:"username" example:"john_doe"` // Username
}

// LoginInput is the email/password login request body.
// @Description User login request body
type LoginInput struct {
	Email    string `json:"email" binding:"required,email" example:"john@example.com"` // Email
	Password string `json:"password" binding:"required" example:"password123"`         // Password
}

// loginSuccessData is returned on successful login.
type loginSuccessData struct {
	AccessToken  string `json:"access_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`  // Access token
	RefreshToken string `json:"refresh_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."` // Refresh token
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

// Register creates a new user account.
// @Summary      Register user
// @Description  Creates a new account with username, email, and password
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body RegisterInput true "Registration payload"
// @Success      200 {object} response.ApiResponse{data=registerSuccessData} "OK"
// @Failure      400 {object} response.ApiResponse "Bad request or username/email already exists"
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

// Login authenticates with email and password.
// @Summary      Login
// @Description  Returns access and refresh tokens
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body LoginInput true "Login payload"
// @Success      200 {object} response.ApiResponse{data=loginSuccessData} "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Invalid email or password"
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

// AppleLogin signs in with Apple.
// @Summary      Apple Sign In
// @Description  Returns access and refresh tokens using Apple identity token
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body AppleLoginInput true "Apple Sign In payload"
// @Success      200 {object} response.ApiResponse{data=loginSuccessData} "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Invalid Apple token"
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

// SetPassword sets the account password for the current user.
// @Summary      Set password
// @Description  Sets password for the authenticated user account
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body SetPasswordInput true "Password payload"
// @Success      204 "No content"
// @Failure      400 {object} response.ApiResponse "Bad request or password already set"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      404 {object} response.ApiResponse "User not found"
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

// RefreshToken exchanges a refresh token for a new access token.
// @Summary      Refresh access token
// @Description  Issues a new access token using a refresh token
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body RefreshTokenInput true "Refresh token payload"
// @Success      200 {object} response.ApiResponse{data=map[string]string} "OK"
// @Failure      400 {object} response.ApiResponse "Invalid or revoked refresh token"
// @Failure      401 {object} response.ApiResponse "Refresh token expired"
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

// Logout revokes the refresh token.
// @Summary      Logout
// @Description  Revokes the provided refresh token
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        input body LogoutInput true "Logout payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Invalid refresh token"
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

// GetProfile returns the authenticated user's profile.
// @Summary      Get profile
// @Description  Returns profile for the current user (authentication required)
// @Tags         Auth
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "User not found"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// UploadAvatar uploads the user's avatar image.
// @Summary      Upload avatar
// @Description  Uploads avatar image (authentication required); jpg, jpeg, or png, max 5MB
// @Tags         Auth
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        avatar formData file true "Avatar image file"
// @Success      200 {object} response.ApiResponse{data=uploadAvatarSuccessData} "OK"
// @Failure      400 {object} response.ApiResponse "Unsupported format or file too large"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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
