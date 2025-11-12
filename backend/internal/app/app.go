package app

import (
	"github.com/album/backend/internal/config"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/service/media"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/urlsigner"
	"github.com/album/backend/pkg/gq"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
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
	GroupRepo        repository.GroupRepository
	GroupMemberRepo  repository.GroupMemberRepository
	GroupPostRepo    repository.GroupPostRepository
	GroupMediaRepo   repository.GroupMediaRepository
	CommentRepo      repository.CommentRepository
	LikeRepo         repository.LikeRepository
	GroupInviteRepo  repository.GroupInviteRepository
	ShareRepo        repository.ShareRepository

	// 媒体处理
	MediaProcessor       mediaprocessor.MediaProcessor
	MediaProcessorConfig *mediaprocessor.Config

	// 服务
	MediaService media.Service
	AuthService  auth.Service
	GroupService interface{} // 使用interface{}避免循环依赖，实际类型为 group.Service
	ShareService interface{} // 使用interface{}避免循环依赖，实际类型为 share.Service
}

// Close 释放应用资源
func (a *App) Close() error {
	if a.MediaProcessor != nil {
		if err := a.MediaProcessor.Close(); err != nil {
			return err
		}
	}
	return nil
}
