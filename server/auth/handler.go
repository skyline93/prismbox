// auth/handler.go
package auth

import (
	"net/http"
	"server/core"
	"server/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AuthHandler struct {
	DB        *gorm.DB
	JWTSecret []byte
}

func (h *AuthHandler) Register(c *gin.Context) {
	var input struct {
		Username string `json:"username" binding:"required"`
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=8"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, http.StatusBadRequest, "Invalid input: "+err.Error())
		return
	}

	var existingUser models.User
	if err := h.DB.Where("username = ? OR email = ?", input.Username, input.Email).First(&existingUser).Error; err == nil {
		core.Error(c, http.StatusConflict, "Username or email already exists")
		return
	}

	hashedPassword, err := HashPassword(input.Password)
	if err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to hash password")
		return
	}

	user := models.User{Username: input.Username, Email: input.Email, Password: string(hashedPassword)}
	if err := h.DB.Create(&user).Error; err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to create user")
		return
	}

	core.Success(c, "User registered successfully", gin.H{"user_id": user.ID, "username": user.Username})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var input struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, http.StatusBadRequest, "Invalid input: "+err.Error())
		return
	}

	var user models.User
	if err := h.DB.Where("username = ?", input.Username).First(&user).Error; err != nil {
		core.Error(c, http.StatusUnauthorized, "Invalid username or password")
		return
	}

	if !CheckPasswordHash(input.Password, user.Password) {
		core.Error(c, http.StatusUnauthorized, "Invalid username or password")
		return
	}

	tokenString, err := GenerateJWT(user.ID, h.JWTSecret)
	if err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to generate token")
		return
	}

	core.Success(c, "Login successful", gin.H{"token": tokenString})
}
