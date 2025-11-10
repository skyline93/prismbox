package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

// NewUserRepository 创建用户仓储。
func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *userRepository) FindByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	if err := r.db.WithContext(ctx).
		Where("email = ?", email).
		First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByID(ctx context.Context, id uint) (*models.User, error) {
	var user models.User
	if err := r.db.WithContext(ctx).
		First(&user, id).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) ExistsByUsernameOrEmail(ctx context.Context, username, email string) (bool, error) {
	var count int64
	query := r.db.WithContext(ctx).Model(&models.User{}).Where("email = ?", email)
	if username != "" {
		query = query.Or("username = ?", username)
	}
	if err := query.Count(&count).Error; err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *userRepository) UpdatePassword(ctx context.Context, userID uint, hashedPassword string) error {
	return r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("id = ?", userID).
		Update("password", hashedPassword).Error
}

func (r *userRepository) UpdateAvatar(ctx context.Context, userID uint, filename string) error {
	return r.db.WithContext(ctx).
		Model(&models.User{}).
		Where("id = ?", userID).
		Update("avatar", filename).Error
}
