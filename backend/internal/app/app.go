package app

import (
	"github.com/album/backend/internal/config"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/service/media"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/urlsigner"
	"github.com/album/backend/pkg/gq"
	"gorm.io/gorm"
)

// App 应用主结构体
type App struct {
	Config *config.Config

	// 数据库
	DB *gorm.DB

	// 存储
	PrimaryStorage storage.PrimaryStorage
	StorageManager *storage.StorageManager

	// 任务队列
	TaskQueueClient *gq.Client
	TaskQueueServer *gq.Server

	// 安全工具
	URLSigner *urlsigner.Signer

	// 仓储
	MediaRepo        repository.MediaRepository
	UserRepo         repository.UserRepository
	AuthProviderRepo repository.AuthProviderRepository
	RefreshTokenRepo repository.RefreshTokenRepository

	// 服务
	MediaService media.Service
	AuthService  auth.Service
}
