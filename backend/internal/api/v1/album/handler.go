package album

import (
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/pkg/logger"
	"gorm.io/gorm"
)

// Handler 相册处理器
type Handler struct {
	albumRepo repository.AlbumRepository
	mediaRepo repository.MediaRepository
	db        *gorm.DB
	log       logger.Logger
}

// NewHandler 创建相册处理器
func NewHandler(
	albumRepo repository.AlbumRepository,
	mediaRepo repository.MediaRepository,
	db *gorm.DB,
) *Handler {
	return &Handler{
		albumRepo: albumRepo,
		mediaRepo: mediaRepo,
		db:        db,
		log:       logger.New("api.v1.album"),
	}
}
