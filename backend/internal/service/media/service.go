package media

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/monitoring"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/storage/primary/local"
	"github.com/album/backend/internal/thumbhash"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/hashutil"
	"github.com/album/backend/pkg/logger"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
	"github.com/gabriel-vasile/mimetype"
	"gorm.io/gorm"
)

// UploadMediaRequest 上传媒体请求
type UploadMediaRequest struct {
	UserID           uint
	ItemType         string
	OriginalFilename string
	CloudUUID        string
	MediaTakenAt     *time.Time
	Filename         string
	FileSize         int64
	Data             io.Reader
	// LivePhotoVideoUUID 关联的 Live Photo 视频媒体 UUID（仅当当前上传的是图片时有效）
	LivePhotoVideoUUID *string
}

// GetMediasRequest 获取媒体列表请求
type GetMediasRequest struct {
	UserID   uint
	Page     int
	PageSize int
	ItemType string // "image" 或 "video"，空字符串表示全部
}

// GetMediasResult 获取媒体列表结果
type GetMediasResult struct {
	Medias   []*models.Media
	Total    int
	Page     int
	PageSize int
}

// CheckHashesResult 检查哈希结果
type CheckHashesResult struct {
	ExistingHashes []string
	MissingHashes  []string
}

// GetChangesRequest 获取媒体变更请求
type GetChangesRequest struct {
	UserID uint
	Since  *time.Time // 可选，如果为nil则返回所有变更
}

// MediaChange 媒体变更
type MediaChange struct {
	UUID      string
	Hash      string
	ItemType  string
	Action    string // "created", "updated", "deleted"
	UpdatedAt time.Time
}

// ThumbnailResult 缩略图结果
type ThumbnailResult struct {
	Reader        io.ReadCloser
	IsPlaceholder bool // 是否是占位符
}

// Service 媒体服务接口
type Service interface {
	// CheckInstantUpload 检查是否可以秒传（使用客户端传入的Hash）
	CheckInstantUpload(ctx context.Context, userID uint, hash string) (*models.Media, error)
	// UploadMedia 上传媒体文件（流式处理，使用客户端传入的Hash）
	UploadMedia(ctx context.Context, req *UploadMediaRequest) (*models.Media, error)
	// RegenerateThumbnail 重新生成缩略图
	RegenerateThumbnail(ctx context.Context, mediaUUID string, specName string) error
	// RegeneratePreview 重新生成预览图
	RegeneratePreview(ctx context.Context, mediaUUID string, specName string) error
	// GetAuthorizedMedia 获取授权的媒体（支持私有访问和公开分享）
	GetAuthorizedMedia(ctx context.Context, mediaUUID string, userID *uint) (*models.Media, error)
	// GetFileReader 获取文件读取器
	GetFileReader(ctx context.Context, storageKey string) (io.ReadCloser, error)
	// BuildThumbnailKey 构建缩略图存储key
	BuildThumbnailKey(media *models.Media) (string, error)
	// BuildDynamicThumbnailKey 构建动态尺寸缩略图存储key
	BuildDynamicThumbnailKey(media *models.Media, width, height int) (string, error)
	// GetOrGenerateThumbnail 获取或生成缩略图（按需生成）
	GetOrGenerateThumbnail(ctx context.Context, media *models.Media, sizeParam string) (io.ReadCloser, error)
	// GetOrGenerateThumbnailWithInfo 获取或生成缩略图（返回详细信息，包括是否是占位符）
	GetOrGenerateThumbnailWithInfo(ctx context.Context, media *models.Media, sizeParam string) (*ThumbnailResult, error)
	// BuildPreviewKey 构建预览图存储key
	BuildPreviewKey(media *models.Media) (string, error)
	// GetOriginalMimeType 获取原始文件的MIME类型
	GetOriginalMimeType(media *models.Media) string
	// GetPreviewMimeType 获取预览文件的MIME类型
	GetPreviewMimeType(media *models.Media) string
	// GetThumbnailMimeType 获取缩略图的MIME类型
	GetThumbnailMimeType(media *models.Media) string
	// GetMedias 获取媒体列表
	GetMedias(ctx context.Context, req *GetMediasRequest) (*GetMediasResult, error)
	// CheckHashes 检查哈希列表，返回已存在和缺失的哈希
	CheckHashes(ctx context.Context, userID uint, hashes []string) (*CheckHashesResult, error)
	// GetChanges 获取媒体变更（增量同步）
	GetChanges(ctx context.Context, req *GetChangesRequest) ([]*MediaChange, error)
	// DeleteMedia 删除媒体（软删除，移到回收站）
	DeleteMedia(ctx context.Context, userID uint, mediaUUID string) error
	// RestoreMedia 恢复媒体（从回收站恢复）
	RestoreMedia(ctx context.Context, userID uint, mediaUUID string) error
	// PurgeMedia 永久删除媒体（硬删除，删除数据库记录和存储文件）
	PurgeMedia(ctx context.Context, userID uint, mediaUUID string) error
	// GetThumbnailQueueStats 获取缩略图队列统计信息
	GetThumbnailQueueStats() map[string]interface{}
	// GetCleanupStats 获取清理服务统计信息
	GetCleanupStats() map[string]interface{}
}

// service 媒体服务实现
type service struct {
	log            logger.Logger
	repo           repository.MediaRepository
	storageManager *storage.StorageManager
	taskQueue      *gq.Client
	processor      mediaprocessor.MediaProcessor
	processorCfg   *mediaprocessor.Config
	storageAdapter *StorageAdapter
	thumbnailQueue *ThumbnailQueue          // 缩略图生成队列
	cleanupService *ThumbnailCleanupService // 动态缩略图清理服务
	cacheManager   *local.CacheManager      // 缓存管理器
}

// NewService 创建媒体服务
func NewService(
	repo repository.MediaRepository,
	storageManager *storage.StorageManager,
	taskQueue *gq.Client,
	processor mediaprocessor.MediaProcessor,
	processorCfg *mediaprocessor.Config,
) Service {
	thumbnailQueue := NewThumbnailQueue()
	// 启动清理任务（使用 context.Background，因为 service 生命周期与应用一致）
	thumbnailQueue.StartCleanup(context.Background())

	storageAdapter := NewStorageAdapter()

	// 创建动态缩略图清理服务
	// 默认配置：30天未访问的缩略图将被清理，每24小时执行一次清理
	cleanupService := NewThumbnailCleanupService(
		storageManager,
		storageAdapter,
		30*24*time.Hour, // 30天未访问
		24*time.Hour,    // 每24小时清理一次
	)
	cleanupService.StartCleanup(context.Background())

	// 获取 CacheManager（如果可用）
	var cacheManager *local.CacheManager
	if cm := storageManager.GetCacheManager(); cm != nil {
		cacheManager = cm
	}

	return &service{
		log:            logger.New("service.media"),
		repo:           repo,
		storageManager: storageManager,
		taskQueue:      taskQueue,
		processor:      processor,
		processorCfg:   processorCfg,
		storageAdapter: storageAdapter,
		thumbnailQueue: thumbnailQueue,
		cleanupService: cleanupService,
		cacheManager:   cacheManager,
	}
}

// CheckInstantUpload 检查是否可以秒传（使用客户端传入的Hash）
func (s *service) CheckInstantUpload(ctx context.Context, userID uint, hash string) (*models.Media, error) {
	existingMedia, err := s.repo.FindByHash(ctx, userID, hash)
	if err == nil && existingMedia != nil {
		// 文件已存在，可以秒传
		return existingMedia, nil
	}
	// 如果查询出错且不是记录不存在，返回错误
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("check instant upload: %w", err)
	}
	// 文件不存在，不能秒传
	return nil, nil
}

// UploadMedia 上传媒体文件（流式处理，后端计算 Hash）
func (s *service) UploadMedia(ctx context.Context, req *UploadMediaRequest) (*models.Media, error) {
	ext, normalizedExt := resolveExtensions(req.ItemType, req.Filename)

	// 0. 可选：校验 Live Photo 关联视频 UUID（仅对图片资产有效）
	// 为保持简单与鲁棒性，如果引用无效则记录日志并忽略该字段（不返回 4xx）。
	if req.LivePhotoVideoUUID != nil && *req.LivePhotoVideoUUID != "" && strings.ToLower(req.ItemType) == "image" {
		videoUUID := *req.LivePhotoVideoUUID
		videoMedia, err := s.repo.FindActiveByUUIDAndUser(ctx, videoUUID, req.UserID)
		if err != nil {
			// 如果不存在或查询错误，记录并忽略关联字段
			s.log.Warn("live photo video media not found, ignoring live_photo_video_uuid",
				logger.String("live_photo_video_uuid", videoUUID),
				logger.Uint("user_id", req.UserID),
				logger.Error(err),
			)
			req.LivePhotoVideoUUID = nil
		} else if !strings.EqualFold(videoMedia.ItemType, "video") {
			// 仅允许指向视频资产
			s.log.Warn("live photo video uuid does not point to a video item, ignoring",
				logger.String("live_photo_video_uuid", videoUUID),
				logger.String("item_type", videoMedia.ItemType),
				logger.Uint("user_id", req.UserID),
			)
			req.LivePhotoVideoUUID = nil
		}
	}

	// 1. 读取数据到临时文件（用于计算 hash 和后续存储）
	tempFile, err := os.CreateTemp("", "media_upload_*.tmp")
	if err != nil {
		return nil, fmt.Errorf("create temp file: %w", err)
	}
	defer os.Remove(tempFile.Name())
	defer tempFile.Close()

	// 读取数据到临时文件，同时获取实际文件大小
	actualSize, err := io.Copy(tempFile, req.Data)
	if err != nil {
		return nil, fmt.Errorf("copy data to temp file: %w", err)
	}

	// 2. 计算 hash（从临时文件）
	tempFile.Seek(0, 0)
	hash, err := hashutil.CalculateHashMD5(tempFile)
	if err != nil {
		return nil, fmt.Errorf("calculate hash: %w", err)
	}

	// 2.5. 检查文件是否已存在（去重检查）
	existingMedia, err := s.repo.FindByHash(ctx, req.UserID, hash)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("check existing media: %w", err)
	}
	if existingMedia != nil {
		// 文件已存在，返回已存在的记录
		s.log.Info("media already exists, skipping upload",
			logger.String("uuid", existingMedia.UUID),
			logger.String("hash", hash),
			logger.Uint("user_id", req.UserID),
		)
		return existingMedia, nil
	}

	// 3. 使用计算得到的 hash 构建存储 key
	storageKey, err := s.storageAdapter.BuildStorageKey(hash, req.ItemType, MediaFileTypeOriginal, normalizedExt)
	if err != nil {
		return nil, fmt.Errorf("build storage key: %w", err)
	}

	putOpts, err := s.storageAdapter.ToStorageOptions(req.ItemType, MediaFileTypeOriginal, normalizedExt)
	if err != nil {
		return nil, fmt.Errorf("build storage options: %w", err)
	}
	putOpts.UserID = req.UserID

	// 4. 读取文件头用于 MIME 类型检测
	tempFile.Seek(0, 0)
	headBuf, err := readHead(tempFile, sniffBufferSize)
	if err != nil {
		return nil, err
	}

	mimeType := detectMimeType(headBuf, normalizedExt, ext)

	// 5. 重置文件指针，直接传递给存储层
	tempFile.Seek(0, 0)
	// 直接传递 tempFile，存储层只需要完整的文件数据
	if err := s.storageManager.Put(ctx, storageKey, tempFile, actualSize, putOpts); err != nil {
		return nil, fmt.Errorf("upload to storage: %w", err)
	}

	localPoolUUID := ""
	if putOpts != nil {
		localPoolUUID = putOpts.PoolID
	}

	media := s.newMediaModel(req, hash, storageKey, mimeType, localPoolUUID)
	if err := s.repo.Create(ctx, media); err != nil {
		// ⚠️ 不再删除已上传的文件！这是一个危险操作，可能导致数据丢失。
		// 如果数据库插入失败，保留文件并记录详细错误信息。
		// 文件可以通过后续的清理任务或手动修复来处理。
		s.log.Error("failed to create media record after file upload",
			logger.Error(err),
			logger.String("storage_key", storageKey),
			logger.String("hash", hash),
			logger.Uint("user_id", req.UserID),
			logger.String("filename", req.Filename),
			logger.String("note", "file remains in storage and may need manual cleanup"),
		)
		return nil, fmt.Errorf("create media record: %w (file uploaded but record creation failed, file may need manual cleanup)", err)
	}

	s.enqueueMediaProcessingTask(ctx, req, storageKey)

	s.log.Info("media uploaded successfully",
		logger.String("uuid", req.CloudUUID),
		logger.String("hash", hash),
		logger.Uint("user_id", req.UserID),
		logger.Int64("file_size", actualSize),
	)

	return media, nil
}

const sniffBufferSize = 8192

func resolveExtensions(itemType, filename string) (string, string) {
	ext := filepath.Ext(filename)
	normalizedExt := strings.TrimPrefix(strings.ToLower(ext), ".")
	if ext == "" {
		if itemType == "video" {
			ext = ".mp4"
		} else {
			ext = ".jpg"
		}
	}
	return ext, normalizedExt
}

func readHead(data io.Reader, size int) ([]byte, error) {
	if size <= 0 {
		return nil, nil
	}

	buf := make([]byte, size)
	n, err := io.ReadFull(data, buf)
	switch {
	case err == io.ErrUnexpectedEOF || err == io.EOF:
		return buf[:n], nil
	case err != nil:
		return nil, fmt.Errorf("read file head: %w", err)
	default:
		return buf[:n], nil
	}
}

func detectMimeType(head []byte, normalizedExt, ext string) string {
	if len(head) > 0 {
		if mime := mimetype.Detect(head); mime != nil {
			return mime.String()
		}
	}
	if mimeType := lookupMimeType(normalizedExt); mimeType != "" {
		return mimeType
	}
	if mimeType := lookupMimeType(ext); mimeType != "" {
		return mimeType
	}
	return ""
}

func lookupMimeType(value string) string {
	if value == "" {
		return ""
	}
	if mime := mimetype.Lookup(value); mime != nil {
		return mime.String()
	}
	return ""
}

func (s *service) newMediaModel(req *UploadMediaRequest, hash, storageKey, mimeType string, localPoolUUID string) *models.Media {
	return &models.Media{
		UUID:               req.CloudUUID,
		UserID:             req.UserID,
		Hash:               hash,
		ItemType:           strings.ToLower(req.ItemType),
		OriginalFilename:   req.OriginalFilename,
		Filename:           req.Filename,
		FileSize:           req.FileSize,
		MimeType:           mimeType,
		MediaTakenAt:       req.MediaTakenAt,
		ProcessingStatus:   "PROCESSING",
		Deleted:            false,
		LocalPath:          storageKey,
		LocalPoolUUID:      localPoolUUID,
		BackupStatus:       "pending",
		LivePhotoVideoUUID: req.LivePhotoVideoUUID,
	}
}

func (s *service) enqueueMediaProcessingTask(ctx context.Context, req *UploadMediaRequest, storageKey string) {
	taskPayload := map[string]interface{}{
		"media_uuid": req.CloudUUID,
		"file_path":  storageKey,
		"user_id":    req.UserID,
	}

	payloadBytes, err := json.Marshal(taskPayload)
	if err != nil {
		s.log.Error("failed to marshal task payload",
			logger.Error(err),
			logger.String("media_uuid", req.CloudUUID),
		)
		return
	}

	taskType := "media:process:image"
	if req.ItemType == "video" {
		taskType = "media:process:video"
	}

	if err := s.taskQueue.Enqueue(ctx,
		gq.NewTask(taskType, payloadBytes),
		gq.Queue("default"),
		gq.Priority(5),
	); err != nil {
		s.log.Error("failed to enqueue media process task",
			logger.Error(err),
			logger.String("media_uuid", req.CloudUUID),
		)
		return
	}

	s.log.Info("media process task enqueued",
		logger.String("media_uuid", req.CloudUUID),
		logger.String("task_type", taskType),
	)
}

// RegenerateThumbnail 重新生成缩略图文件。
func (s *service) RegenerateThumbnail(ctx context.Context, mediaUUID string, specName string) error {
	media, err := s.repo.FindByUUID(ctx, mediaUUID)
	if err != nil {
		return fmt.Errorf("find media %s: %w", mediaUUID, err)
	}

	if !strings.EqualFold(media.ItemType, "image") {
		return fmt.Errorf("media %s is not an image", mediaUUID)
	}

	spec, err := s.imageSpecByName(specName)
	if err != nil {
		return err
	}

	if !spec.Crop {
		spec.Crop = true
	}

	path, err := s.resolveLocalPath(ctx, media.LocalPath)
	if err != nil {
		return err
	}

	if _, err := s.processor.GenerateThumbnail(ctx, path, spec); err != nil {
		return fmt.Errorf("generate thumbnail: %w", err)
	}

	return s.repo.Update(ctx, mediaUUID, map[string]interface{}{
		"processing_status": "COMPLETED",
	})
}

// RegeneratePreview 重新生成预览图。
func (s *service) RegeneratePreview(ctx context.Context, mediaUUID string, specName string) error {
	media, err := s.repo.FindByUUID(ctx, mediaUUID)
	if err != nil {
		return fmt.Errorf("find media %s: %w", mediaUUID, err)
	}

	if !strings.EqualFold(media.ItemType, "image") {
		return fmt.Errorf("media %s is not an image", mediaUUID)
	}

	spec, err := s.imageSpecByName(specName)
	if err != nil {
		return err
	}

	spec.Crop = false

	path, err := s.resolveLocalPath(ctx, media.LocalPath)
	if err != nil {
		return err
	}

	if _, err := s.processor.GeneratePreview(ctx, path, spec); err != nil {
		return fmt.Errorf("generate preview: %w", err)
	}

	return s.repo.Update(ctx, mediaUUID, map[string]interface{}{
		"processing_status": "COMPLETED",
	})
}

func (s *service) resolveLocalPath(ctx context.Context, key string) (string, error) {
	if key == "" {
		return "", fmt.Errorf("media local path empty")
	}
	path, err := s.storageManager.GetSignedURL(ctx, key, 5*time.Minute)
	if err != nil {
		return "", fmt.Errorf("resolve local path: %w", err)
	}
	return path, nil
}

func (s *service) imageSpecByName(name string) (mediaprocessor.ImageSpec, error) {
	if s.processorCfg == nil {
		return mediaprocessor.ImageSpec{}, fmt.Errorf("image specs not configured")
	}
	for _, spec := range s.processorCfg.DefaultImageSpecs {
		if strings.EqualFold(spec.Name, name) {
			return spec, nil
		}
	}
	return mediaprocessor.ImageSpec{}, fmt.Errorf("image spec %s not found", name)
}

// GetAuthorizedMedia 获取授权的媒体（支持私有访问和公开分享）
// userID为nil时，表示通过签名URL访问（已通过FlexibleAuthMiddleware验证）
func (s *service) GetAuthorizedMedia(ctx context.Context, mediaUUID string, userID *uint) (*models.Media, error) {
	media, err := s.repo.FindByUUID(ctx, mediaUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, gorm.ErrRecordNotFound
		}
		return nil, fmt.Errorf("find media: %w", err)
	}

	// 如果提供了userID，检查所有权
	if userID != nil {
		if media.UserID != *userID {
			return nil, gorm.ErrRecordNotFound // 返回NotFound以隐藏权限错误
		}
	}
	// 如果没有提供userID，说明是通过签名URL访问，FlexibleAuthMiddleware已经验证过

	return media, nil
}

// GetFileReader 获取文件读取器
func (s *service) GetFileReader(ctx context.Context, storageKey string) (io.ReadCloser, error) {
	if storageKey == "" {
		return nil, fmt.Errorf("storage key is empty")
	}
	return s.storageManager.Get(ctx, storageKey)
}

// BuildThumbnailKey 构建缩略图存储key
func (s *service) BuildThumbnailKey(media *models.Media) (string, error) {
	// 从原始文件的LocalPath提取hash和扩展名
	hash, ext, _, err := s.storageAdapter.ParseStorageKey(media.LocalPath)
	if err != nil {
		return "", fmt.Errorf("parse storage key: %w", err)
	}
	return s.storageAdapter.GetThumbnailKey(hash, media.ItemType, ext)
}

// BuildDynamicThumbnailKey 构建动态尺寸缩略图存储key
func (s *service) BuildDynamicThumbnailKey(media *models.Media, width, height int) (string, error) {
	// 从原始文件的LocalPath提取hash和扩展名
	hash, ext, _, err := s.storageAdapter.ParseStorageKey(media.LocalPath)
	if err != nil {
		return "", fmt.Errorf("parse storage key: %w", err)
	}
	return s.storageAdapter.BuildDynamicThumbnailKey(hash, media.ItemType, ext, width, height)
}

// GetOrGenerateThumbnail 获取或生成缩略图（按需生成，支持异步生成和降级方案）
func (s *service) GetOrGenerateThumbnail(ctx context.Context, media *models.Media, sizeParam string) (io.ReadCloser, error) {
	result, err := s.GetOrGenerateThumbnailWithInfo(ctx, media, sizeParam)
	if err != nil {
		return nil, err
	}
	return result.Reader, nil
}

// GetOrGenerateThumbnailWithInfo 获取或生成缩略图（返回详细信息，包括是否是占位符）
func (s *service) GetOrGenerateThumbnailWithInfo(ctx context.Context, media *models.Media, sizeParam string) (*ThumbnailResult, error) {
	startTime := time.Now()
	defer func() {
		monitoring.RecordThumbnailRequest()
	}()

	s.log.Debug("thumbnail request received",
		logger.String("media_uuid", media.UUID),
		logger.String("size_param", sizeParam),
		logger.String("item_type", media.ItemType),
	)

	// 解析尺寸参数
	size, err := ParseThumbnailSize(sizeParam)
	if err != nil {
		s.log.Warn("failed to parse thumbnail size parameter",
			logger.String("size_param", sizeParam),
			logger.String("media_uuid", media.UUID),
			logger.Error(err),
		)
		return nil, fmt.Errorf("parse size: %w", err)
	}

	// 构建缓存 key（用于 CacheManager）
	var cacheKey string
	if sizeParam == "thumbnail" {
		key, _ := s.BuildThumbnailKey(media)
		cacheKey = key
	} else if sizeParam == "preview" {
		key, _ := s.BuildPreviewKey(media)
		cacheKey = key
	} else {
		key, _ := s.BuildDynamicThumbnailKey(media, size.Width, size.Height)
		cacheKey = key
	}

	// 1. 检查 CacheManager（L1: 内存缓存，L2: 磁盘缓存）
	if s.cacheManager != nil && cacheKey != "" {
		cacheStartTime := time.Now()
		cached, err := s.cacheManager.Get(cacheKey)
		cacheLatency := time.Since(cacheStartTime)
		if err == nil && cached != nil {
			// 缓存命中，直接返回
			s.log.Debug("thumbnail cache hit",
				logger.String("cache_key", cacheKey),
				logger.String("media_uuid", media.UUID),
				logger.String("size_param", sizeParam),
				logger.Duration("cache_latency_ms", cacheLatency),
			)
			monitoring.RecordThumbnailCacheHit(time.Since(startTime))
			return &ThumbnailResult{
				Reader:        cached,
				IsPlaceholder: false,
			}, nil
		}
		if err != nil {
			s.log.Debug("cache lookup error (non-fatal, continuing to storage)",
				logger.String("cache_key", cacheKey),
				logger.String("media_uuid", media.UUID),
				logger.Duration("cache_latency_ms", cacheLatency),
				logger.Error(err),
			)
		}
	}

	// 2. 检查是否是预设尺寸（thumbnail 或 preview）
	if sizeParam == "thumbnail" {
		// 使用预生成的缩略图
		key, err := s.BuildThumbnailKey(media)
		if err != nil {
			return nil, fmt.Errorf("build thumbnail key: %w", err)
		}
		// 检查是否存在
		exists, err := s.storageManager.Exists(ctx, key)
		if err != nil {
			return nil, fmt.Errorf("check thumbnail exists: %w", err)
		}
		if exists {
			storageStartTime := time.Now()
			reader, err := s.storageManager.Get(ctx, key)
			storageLatency := time.Since(storageStartTime)
			if err == nil {
				s.log.Info("thumbnail served from storage",
					logger.String("storage_key", key),
					logger.String("media_uuid", media.UUID),
					logger.String("size_param", sizeParam),
					logger.Duration("storage_latency_ms", storageLatency),
					logger.Duration("total_latency_ms", time.Since(startTime)),
				)
				if s.cacheManager != nil {
					// 写入缓存（异步）
					go s.cacheThumbnail(key, reader)
				}
			} else {
				s.log.Warn("failed to read thumbnail from storage",
					logger.String("storage_key", key),
					logger.String("media_uuid", media.UUID),
					logger.Duration("storage_latency_ms", storageLatency),
					logger.Error(err),
				)
			}
			monitoring.RecordThumbnailStorageHit(time.Since(startTime))
			return &ThumbnailResult{
				Reader:        reader,
				IsPlaceholder: false,
			}, err
		}
		s.log.Debug("pre-generated thumbnail not found, falling back to dynamic generation",
			logger.String("storage_key", key),
			logger.String("media_uuid", media.UUID),
		)
		// 如果不存在，降级到动态生成
	}

	if sizeParam == "preview" {
		// 使用预生成的预览图
		key, err := s.BuildPreviewKey(media)
		if err != nil {
			return nil, fmt.Errorf("build preview key: %w", err)
		}
		// 检查是否存在
		exists, err := s.storageManager.Exists(ctx, key)
		if err != nil {
			return nil, fmt.Errorf("check preview exists: %w", err)
		}
		if exists {
			storageStartTime := time.Now()
			reader, err := s.storageManager.Get(ctx, key)
			storageLatency := time.Since(storageStartTime)
			if err == nil {
				s.log.Info("pre-generated preview served from storage",
					logger.String("storage_key", key),
					logger.String("media_uuid", media.UUID),
					logger.Duration("storage_latency_ms", storageLatency),
					logger.Duration("total_latency_ms", time.Since(startTime)),
				)
				if s.cacheManager != nil {
					// 写入缓存（异步）
					go s.cacheThumbnail(key, reader)
				}
			} else {
				s.log.Warn("failed to read pre-generated preview from storage",
					logger.String("storage_key", key),
					logger.String("media_uuid", media.UUID),
					logger.Duration("storage_latency_ms", storageLatency),
					logger.Error(err),
				)
			}
			monitoring.RecordThumbnailStorageHit(time.Since(startTime))
			return &ThumbnailResult{
				Reader:        reader,
				IsPlaceholder: false,
			}, err
		}
		s.log.Debug("pre-generated preview not found, falling back to dynamic generation",
			logger.String("storage_key", key),
			logger.String("media_uuid", media.UUID),
		)
		// 如果不存在，降级到动态生成（使用 1280x0）
		size = &ThumbnailSize{Width: 1280, Height: 0}
	}

	// 3. 构建动态缩略图 key
	dynamicKey, err := s.BuildDynamicThumbnailKey(media, size.Width, size.Height)
	if err != nil {
		return nil, fmt.Errorf("build dynamic thumbnail key: %w", err)
	}

	// 4. 检查动态缩略图是否已存在（L3: 主存储）
	exists, err := s.storageManager.Exists(ctx, dynamicKey)
	if err != nil {
		return nil, fmt.Errorf("check dynamic thumbnail exists: %w", err)
	}

	if exists {
		// 记录访问（用于清理策略）
		s.cleanupService.RecordAccess(dynamicKey)
		// 从主存储读取
		storageStartTime := time.Now()
		reader, err := s.storageManager.Get(ctx, dynamicKey)
		storageLatency := time.Since(storageStartTime)
		if err == nil {
			s.log.Info("dynamic thumbnail served from storage",
				logger.String("storage_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
				logger.Duration("storage_latency_ms", storageLatency),
				logger.Duration("total_latency_ms", time.Since(startTime)),
			)
			if s.cacheManager != nil {
				// 写入缓存（异步）
				go s.cacheThumbnail(dynamicKey, reader)
			}
		} else {
			s.log.Warn("failed to read dynamic thumbnail from storage",
				logger.String("storage_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.Duration("storage_latency_ms", storageLatency),
				logger.Error(err),
			)
		}
		monitoring.RecordThumbnailStorageHit(time.Since(startTime))
		return &ThumbnailResult{
			Reader:        reader,
			IsPlaceholder: false,
		}, err
	}

	// 需要按需生成，使用队列机制避免重复生成
	task := &ThumbnailGenerationTask{
		MediaUUID: media.UUID,
		SizeParam: sizeParam,
		Key:       dynamicKey,
		CreatedAt: time.Now(),
	}

	// 尝试获取生成权限
	acquired, waitCh := s.thumbnailQueue.TryAcquire(dynamicKey, task)
	if !acquired {
		// 已有其他请求正在生成，等待完成或返回降级方案
		s.log.Info("thumbnail generation already in progress, waiting or returning fallback",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
		)

		// 如果有 ThumbHash，返回降级方案
		if media.ThumbHash != "" {
			s.log.Debug("returning thumbhash placeholder while generation in progress",
				logger.String("storage_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
			)
			monitoring.RecordThumbnailPlaceholder(time.Since(startTime))
			reader, err := s.getThumbHashFallback(media.ThumbHash, size.Width, size.Height)
			return &ThumbnailResult{
				Reader:        reader,
				IsPlaceholder: true,
			}, err
		}

		// 等待生成完成（最多等待5秒）
		select {
		case err := <-waitCh:
			if err != nil {
				// 生成失败，返回降级方案
				s.log.Warn("thumbnail generation failed after waiting",
					logger.String("storage_key", dynamicKey),
					logger.String("media_uuid", media.UUID),
					logger.Duration("wait_time_ms", time.Since(startTime)),
					logger.Error(err),
				)
				if media.ThumbHash != "" {
					s.log.Debug("returning thumbhash placeholder after generation failure",
						logger.String("storage_key", dynamicKey),
						logger.String("media_uuid", media.UUID),
					)
					monitoring.RecordThumbnailPlaceholder(time.Since(startTime))
					reader, err := s.getThumbHashFallback(media.ThumbHash, size.Width, size.Height)
					return &ThumbnailResult{
						Reader:        reader,
						IsPlaceholder: true,
					}, err
				}
				return nil, fmt.Errorf("thumbnail generation failed: %w", err)
			}
			// 生成成功，记录访问并重新获取
			s.log.Info("thumbnail generation completed, serving from storage",
				logger.String("storage_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.Duration("wait_time_ms", time.Since(startTime)),
			)
			s.cleanupService.RecordAccess(dynamicKey)
			reader, err := s.storageManager.Get(ctx, dynamicKey)
			if err == nil && s.cacheManager != nil {
				// 需要先读取数据用于缓存，然后创建新的reader返回
				data, readErr := io.ReadAll(reader)
				reader.Close()
				if readErr == nil {
					// 异步写入缓存
					go func() {
						if err := s.cacheManager.Put(dynamicKey, data); err != nil {
							s.log.Debug("failed to cache thumbnail after generation",
								logger.String("cache_key", dynamicKey),
								logger.String("media_uuid", media.UUID),
								logger.Error(err),
							)
						}
					}()
					// 返回新的reader
					reader = io.NopCloser(bytes.NewReader(data))
				}
			}
			monitoring.RecordThumbnailStorageHit(time.Since(startTime))
			return &ThumbnailResult{
				Reader:        reader,
				IsPlaceholder: false,
			}, err
		case <-time.After(5 * time.Second):
			// 超时，返回降级方案
			s.log.Warn("thumbnail generation wait timeout, returning fallback",
				logger.String("storage_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.Duration("wait_timeout_ms", 5*time.Second),
			)
			if media.ThumbHash != "" {
				s.log.Debug("returning thumbhash placeholder after wait timeout",
					logger.String("storage_key", dynamicKey),
					logger.String("media_uuid", media.UUID),
				)
				monitoring.RecordThumbnailPlaceholder(time.Since(startTime))
				reader, err := s.getThumbHashFallback(media.ThumbHash, size.Width, size.Height)
				return &ThumbnailResult{
					Reader:        reader,
					IsPlaceholder: true,
				}, err
			}
			return nil, fmt.Errorf("thumbnail generation timeout")
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	// 获得了生成权限，异步生成
	s.log.Info("acquired thumbnail generation permission, starting async generation",
		logger.String("storage_key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
	)
	go s.generateThumbnailAsync(ctx, media, size, dynamicKey, task)

	// 立即返回降级方案（ThumbHash 或预生成缩略图）
	if media.ThumbHash != "" {
		s.log.Debug("returning thumbhash placeholder while generation starts",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
		)
		monitoring.RecordThumbnailPlaceholder(time.Since(startTime))
		reader, err := s.getThumbHashFallback(media.ThumbHash, size.Width, size.Height)
		return &ThumbnailResult{
			Reader:        reader,
			IsPlaceholder: true,
		}, err
	}

	// 如果没有 ThumbHash，尝试返回预生成的缩略图作为降级方案
	fallbackKey, _ := s.BuildThumbnailKey(media)
	if exists, _ := s.storageManager.Exists(ctx, fallbackKey); exists {
		s.log.Debug("using fallback thumbnail (pre-generated) while generation in progress",
			logger.String("storage_key", dynamicKey),
			logger.String("fallback_key", fallbackKey),
			logger.String("media_uuid", media.UUID),
		)
		reader, err := s.storageManager.Get(ctx, fallbackKey)
		if err == nil && s.cacheManager != nil {
			// 需要先读取数据用于缓存，然后创建新的reader返回
			data, readErr := io.ReadAll(reader)
			reader.Close()
			if readErr == nil {
				// 异步写入缓存
				go func() {
					if err := s.cacheManager.Put(fallbackKey, data); err != nil {
						s.log.Debug("failed to cache fallback thumbnail",
							logger.String("cache_key", fallbackKey),
							logger.String("media_uuid", media.UUID),
							logger.Error(err),
						)
					}
				}()
				// 返回新的reader
				reader = io.NopCloser(bytes.NewReader(data))
			}
		}
		monitoring.RecordThumbnailStorageHit(time.Since(startTime))
		return &ThumbnailResult{
			Reader:        reader,
			IsPlaceholder: false,
		}, err
	}

	// 没有降级方案，返回错误
	s.log.Warn("no thumbnail available and no fallback options, generation in progress",
		logger.String("storage_key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
		logger.Bool("has_thumbhash", media.ThumbHash != ""),
	)
	return nil, fmt.Errorf("thumbnail not available and generation in progress")
}

// cacheThumbnail 将缩略图写入缓存（辅助方法）
// 注意：此方法会读取并关闭reader，调用者需要确保reader可以安全关闭
func (s *service) cacheThumbnail(key string, reader io.ReadCloser) {
	if s.cacheManager == nil {
		reader.Close()
		return
	}

	cacheStartTime := time.Now()
	// 读取数据（这会消耗reader）
	data, err := io.ReadAll(reader)
	reader.Close() // 读取完成后关闭
	if err != nil {
		s.log.Warn("failed to read thumbnail data for caching",
			logger.String("cache_key", key),
			logger.Error(err),
		)
		return
	}

	if err := s.cacheManager.Put(key, data); err != nil {
		s.log.Warn("failed to write thumbnail to cache",
			logger.String("cache_key", key),
			logger.Int("data_size_bytes", len(data)),
			logger.Duration("cache_write_latency_ms", time.Since(cacheStartTime)),
			logger.Error(err),
		)
	} else {
		s.log.Debug("thumbnail cached successfully",
			logger.String("cache_key", key),
			logger.Int("data_size_bytes", len(data)),
			logger.Duration("cache_write_latency_ms", time.Since(cacheStartTime)),
		)
	}
}

// generateThumbnailAsync 异步生成缩略图
func (s *service) generateThumbnailAsync(ctx context.Context, media *models.Media, size *ThumbnailSize, dynamicKey string, task *ThumbnailGenerationTask) {
	startTime := time.Now()
	monitoring.RecordThumbnailGenerationStart()

	s.log.Info("starting async thumbnail generation",
		logger.String("storage_key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
		logger.String("item_type", media.ItemType),
	)

	// 1. 获取原始文件路径
	originalPath, err := s.storageManager.GetSignedURL(ctx, media.LocalPath, 10*time.Minute)
	if err != nil {
		s.log.Error("failed to get original file path for thumbnail generation",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("original_path", media.LocalPath),
			logger.Error(err),
		)
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("get original file path: %w", err))
		monitoring.RecordThumbnailGenerationFailure()
		return
	}

	// 2. 生成缩略图
	// 构建 ImageSpec（使用 MaxWidth 和 MaxHeight）
	// 生成动态规格名称（用于验证和构建输出路径）
	specName := fmt.Sprintf("thumbnail_%dx%d", size.Width, size.Height)
	spec := mediaprocessor.ImageSpec{
		Name:      specName,
		MaxWidth:  size.Width,
		MaxHeight: size.Height,
		Format:    "jpg",
		Quality:   85,
		Crop:      size.Height > 0, // 如果指定了高度，则允许裁剪
	}

	var thumbnailPath string
	generateStartTime := time.Now()
	if strings.EqualFold(media.ItemType, "image") {
		s.log.Debug("generating thumbnail from image",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("original_path", originalPath),
		)
		thumbnailPath, err = s.processor.GenerateThumbnail(ctx, originalPath, spec)
	} else if strings.EqualFold(media.ItemType, "video") {
		// 对于视频，使用预生成的缩略图作为源来生成动态尺寸
		thumbnailKey, _ := s.BuildThumbnailKey(media)
		sourcePath := originalPath

		// 尝试使用预生成的缩略图作为源
		if exists, _ := s.storageManager.Exists(ctx, thumbnailKey); exists {
			sourcePath, _ = s.storageManager.GetSignedURL(ctx, thumbnailKey, 10*time.Minute)
			s.log.Debug("using pre-generated thumbnail as source for video",
				logger.String("storage_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.String("source_key", thumbnailKey),
			)
		}

		// 从源图片生成动态尺寸缩略图
		s.log.Debug("generating thumbnail from video source",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("source_path", sourcePath),
		)
		thumbnailPath, err = s.processor.GenerateThumbnail(ctx, sourcePath, spec)
	} else {
		s.log.Error("unsupported item type for thumbnail generation",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("item_type", media.ItemType),
		)
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("unsupported item type: %s", media.ItemType))
		monitoring.RecordThumbnailGenerationFailure()
		return
	}

	generateLatency := time.Since(generateStartTime)
	if err != nil {
		s.log.Error("thumbnail generation failed",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("item_type", media.ItemType),
			logger.Duration("generation_latency_ms", generateLatency),
			logger.Error(err),
		)
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("generate thumbnail: %w", err))
		monitoring.RecordThumbnailGenerationFailure()
		return
	}

	s.log.Debug("thumbnail generated successfully",
		logger.String("storage_key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.String("thumbnail_path", thumbnailPath),
		logger.Duration("generation_latency_ms", generateLatency),
	)

	// 3. 读取生成的缩略图文件
	readStartTime := time.Now()
	thumbnailFile, err := os.Open(thumbnailPath)
	if err != nil {
		s.log.Error("failed to open generated thumbnail file",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("thumbnail_path", thumbnailPath),
			logger.Error(err),
		)
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("open generated thumbnail file: %w", err))
		monitoring.RecordThumbnailGenerationFailure()
		return
	}
	defer thumbnailFile.Close()

	// 4. 读取文件数据
	thumbnailData, err := io.ReadAll(thumbnailFile)
	readLatency := time.Since(readStartTime)
	if err != nil {
		s.log.Error("failed to read thumbnail file data",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.String("thumbnail_path", thumbnailPath),
			logger.Duration("read_latency_ms", readLatency),
			logger.Error(err),
		)
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("read thumbnail data: %w", err))
		monitoring.RecordThumbnailGenerationFailure()
		return
	}

	s.log.Debug("thumbnail file read successfully",
		logger.String("storage_key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.Int("file_size_bytes", len(thumbnailData)),
		logger.Duration("read_latency_ms", readLatency),
	)

	// 5. 存储到动态 key
	storeStartTime := time.Now()
	if err := s.storageManager.Put(ctx, dynamicKey, bytes.NewReader(thumbnailData), int64(len(thumbnailData)), nil); err != nil {
		s.log.Error("failed to store dynamic thumbnail to storage",
			logger.String("storage_key", dynamicKey),
			logger.String("media_uuid", media.UUID),
			logger.Int("data_size_bytes", len(thumbnailData)),
			logger.Duration("store_latency_ms", time.Since(storeStartTime)),
			logger.Error(err),
		)
		s.thumbnailQueue.Complete(dynamicKey, err)
		monitoring.RecordThumbnailGenerationFailure()
		return
	}
	storeLatency := time.Since(storeStartTime)

	// 6. 写入缓存（如果启用）
	if s.cacheManager != nil {
		cacheStartTime := time.Now()
		if err := s.cacheManager.Put(dynamicKey, thumbnailData); err != nil {
			s.log.Warn("failed to cache generated thumbnail",
				logger.String("cache_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.Int("data_size_bytes", len(thumbnailData)),
				logger.Duration("cache_write_latency_ms", time.Since(cacheStartTime)),
				logger.Error(err),
			)
		} else {
			s.log.Debug("generated thumbnail cached successfully",
				logger.String("cache_key", dynamicKey),
				logger.String("media_uuid", media.UUID),
				logger.Int("data_size_bytes", len(thumbnailData)),
				logger.Duration("cache_write_latency_ms", time.Since(cacheStartTime)),
			)
		}
	}

	// 记录访问（新生成的缩略图）
	s.cleanupService.RecordAccess(dynamicKey)
	totalLatency := time.Since(startTime)
	monitoring.RecordThumbnailGenerationSuccess(totalLatency)
	s.thumbnailQueue.Complete(dynamicKey, nil)

	s.log.Info("dynamic thumbnail generated and stored successfully",
		logger.String("storage_key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
		logger.Int("thumbnail_size_bytes", len(thumbnailData)),
		logger.Duration("generation_latency_ms", generateLatency),
		logger.Duration("read_latency_ms", readLatency),
		logger.Duration("store_latency_ms", storeLatency),
		logger.Duration("total_latency_ms", totalLatency),
	)
}

// getThumbHashFallback 返回 ThumbHash 占位符（作为降级方案）
// 从 ThumbHash 解码生成实际的占位图（JPEG 格式，使用请求的实际尺寸）
func (s *service) getThumbHashFallback(thumbHash string, width, height int) (io.ReadCloser, error) {
	decodeStartTime := time.Now()
	// 如果未指定尺寸，使用默认值
	if width <= 0 {
		width = 200
	}
	if height <= 0 {
		height = 200
	}

	// 从 ThumbHash 解码生成占位图（使用请求的实际尺寸）
	placeholderData, err := thumbhash.DecodeToImage(thumbHash, width, height)
	decodeLatency := time.Since(decodeStartTime)
	if err != nil {
		s.log.Warn("failed to decode thumbhash for placeholder fallback",
			logger.Int("width", width),
			logger.Int("height", height),
			logger.Duration("decode_latency_ms", decodeLatency),
			logger.Error(err),
		)
		// 如果解码失败，返回一个最小的占位符
		placeholderPNG := []byte{
			0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
			0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
			0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
			0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
			0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
			0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,
			0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND
			0xAE, 0x42, 0x60, 0x82,
		}
		return io.NopCloser(bytes.NewReader(placeholderPNG)), nil
	}

	s.log.Debug("thumbhash placeholder decoded successfully",
		logger.Int("width", width),
		logger.Int("height", height),
		logger.Int("placeholder_size_bytes", len(placeholderData)),
		logger.Duration("decode_latency_ms", decodeLatency),
	)

	return io.NopCloser(bytes.NewReader(placeholderData)), nil
}

// BuildPreviewKey 构建预览图存储key
func (s *service) BuildPreviewKey(media *models.Media) (string, error) {
	// 从原始文件的LocalPath提取hash和扩展名
	hash, ext, _, err := s.storageAdapter.ParseStorageKey(media.LocalPath)
	if err != nil {
		return "", fmt.Errorf("parse storage key: %w", err)
	}
	return s.storageAdapter.GetPreviewKey(hash, media.ItemType, ext)
}

// GetOriginalMimeType 获取原始文件的MIME类型
func (s *service) GetOriginalMimeType(media *models.Media) string {
	if media.MimeType != "" {
		return media.MimeType
	}
	// 如果数据库中没有MIME类型，根据ItemType返回默认值
	if strings.ToLower(media.ItemType) == "video" {
		return "video/mp4"
	}
	return "image/jpeg"
}

// GetPreviewMimeType 获取预览文件的MIME类型
func (s *service) GetPreviewMimeType(media *models.Media) string {
	// 图片预览统一使用jpg格式
	if strings.ToLower(media.ItemType) == "image" {
		return "image/jpeg"
	}
	// 视频预览使用mp4格式
	if strings.ToLower(media.ItemType) == "video" {
		return "video/mp4"
	}
	// 默认返回image/jpeg
	return "image/jpeg"
}

// GetThumbnailMimeType 获取缩略图的MIME类型
func (s *service) GetThumbnailMimeType(media *models.Media) string {
	// 缩略图统一使用jpg格式
	return "image/jpeg"
}

// GetMedias 获取媒体列表
func (s *service) GetMedias(ctx context.Context, req *GetMediasRequest) (*GetMediasResult, error) {
	// 设置默认值
	page := req.Page
	if page < 1 {
		page = 1
	}
	pageSize := req.PageSize
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}

	offset := (page - 1) * pageSize

	// 查询媒体列表
	medias, err := s.repo.FindByUserIDWithFilter(ctx, req.UserID, req.ItemType, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("find medias: %w", err)
	}

	// 统计总数
	total, err := s.repo.CountByUserID(ctx, req.UserID, req.ItemType)
	if err != nil {
		return nil, fmt.Errorf("count medias: %w", err)
	}

	return &GetMediasResult{
		Medias:   medias,
		Total:    int(total),
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// CheckHashes 检查哈希列表，返回已存在和缺失的哈希
func (s *service) CheckHashes(ctx context.Context, userID uint, hashes []string) (*CheckHashesResult, error) {
	if len(hashes) == 0 {
		return &CheckHashesResult{
			ExistingHashes: []string{},
			MissingHashes:  []string{},
		}, nil
	}

	// 查询已存在的哈希
	existingHashes, err := s.repo.FindHashesByUserID(ctx, userID, hashes)
	if err != nil {
		return nil, fmt.Errorf("find existing hashes: %w", err)
	}

	// 构建已存在哈希的map，用于快速查找
	existingMap := make(map[string]bool)
	for _, hash := range existingHashes {
		existingMap[hash] = true
	}

	// 找出缺失的哈希
	missingHashes := make([]string, 0)
	for _, hash := range hashes {
		if !existingMap[hash] {
			missingHashes = append(missingHashes, hash)
		}
	}

	return &CheckHashesResult{
		ExistingHashes: existingHashes,
		MissingHashes:  missingHashes,
	}, nil
}

// GetChanges 获取媒体变更（增量同步）
func (s *service) GetChanges(ctx context.Context, req *GetChangesRequest) ([]*MediaChange, error) {
	// 查询变更
	medias, err := s.repo.FindChangesSince(ctx, req.UserID, req.Since)
	if err != nil {
		return nil, fmt.Errorf("find changes: %w", err)
	}

	// 转换为MediaChange
	changes := make([]*MediaChange, 0, len(medias))
	for _, media := range medias {
		action := "created"
		if media.Deleted {
			action = "deleted"
		} else if media.UpdatedAt.After(media.CreatedAt) {
			action = "updated"
		}

		changes = append(changes, &MediaChange{
			UUID:      media.UUID,
			Hash:      media.Hash,
			ItemType:  media.ItemType,
			Action:    action,
			UpdatedAt: media.UpdatedAt,
		})
	}

	return changes, nil
}

// DeleteMedia 删除媒体（软删除，移到回收站）
func (s *service) DeleteMedia(ctx context.Context, userID uint, mediaUUID string) error {
	// 1. 查找活跃的媒体记录（验证存在性和权限）
	_, err := s.repo.FindActiveByUUIDAndUser(ctx, mediaUUID, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return fmt.Errorf("media not found or permission denied")
		}
		return fmt.Errorf("find media: %w", err)
	}

	// 2. 软删除（设置deleted=true）
	if err := s.repo.Update(ctx, mediaUUID, map[string]interface{}{
		"deleted": true,
	}); err != nil {
		return fmt.Errorf("update media: %w", err)
	}

	s.log.Info("media deleted (moved to bin)",
		logger.String("uuid", mediaUUID),
		logger.Uint("user_id", userID),
	)

	return nil
}

// RestoreMedia 恢复媒体（从回收站恢复）
func (s *service) RestoreMedia(ctx context.Context, userID uint, mediaUUID string) error {
	// 1. 查找回收站中的媒体记录（验证存在性和权限）
	_, err := s.repo.FindInBinByUUIDAndUser(ctx, mediaUUID, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return fmt.Errorf("media not found in bin or permission denied")
		}
		return fmt.Errorf("find media: %w", err)
	}

	// 2. 恢复（设置deleted=false）
	if err := s.repo.Update(ctx, mediaUUID, map[string]interface{}{
		"deleted": false,
	}); err != nil {
		return fmt.Errorf("update media: %w", err)
	}

	s.log.Info("media restored",
		logger.String("uuid", mediaUUID),
		logger.Uint("user_id", userID),
	)

	return nil
}

// PurgeMedia 永久删除媒体（硬删除，删除数据库记录和存储文件）
func (s *service) PurgeMedia(ctx context.Context, userID uint, mediaUUID string) error {
	// 1. 查找回收站中的媒体记录（只能永久删除回收站中的媒体）
	media, err := s.repo.FindInBinByUUIDAndUser(ctx, mediaUUID, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return fmt.Errorf("media not found in bin or permission denied")
		}
		return fmt.Errorf("find media: %w", err)
	}

	// 2. 检查资产是否已被软删除
	// 如果未被软删除（deleted = false），理论上应该先发送删除事件通知其他设备
	// 但由于 PurgeMedia 没有 writer，无法直接发送事件
	// 如果资产之前已被软删除（deleted = true），其他设备应该已经收到删除事件
	if !media.Deleted {
		// 资产未被软删除，直接永久删除
		// 注意：这种情况下其他设备可能无法及时知道资产已被删除
		// 但会在下次全量同步时发现资产不存在，从而清理本地记录
		s.log.Warn("purging media that was not soft-deleted, other devices may not be notified immediately",
			logger.String("uuid", mediaUUID),
			logger.Uint("user_id", userID),
		)
	}

	// 3. 删除存储中的文件
	if err := s.cleanupMediaFiles(ctx, media); err != nil {
		s.log.Warn("failed to cleanup media files",
			logger.Error(err),
			logger.String("uuid", mediaUUID),
		)
		// 继续删除数据库记录，即使文件删除失败
	}

	// 4. 永久删除数据库记录
	if err := s.repo.Purge(ctx, mediaUUID); err != nil {
		return fmt.Errorf("purge media: %w", err)
	}

	s.log.Info("media purged permanently",
		logger.String("uuid", mediaUUID),
		logger.Uint("user_id", userID),
	)

	return nil
}

// GetThumbnailQueueStats 获取缩略图队列统计信息
func (s *service) GetThumbnailQueueStats() map[string]interface{} {
	return s.thumbnailQueue.GetStats()
}

// GetCleanupStats 获取清理服务统计信息
func (s *service) GetCleanupStats() map[string]interface{} {
	return s.cleanupService.GetStats()
}

// cleanupMediaFiles 删除媒体相关的所有存储文件
func (s *service) cleanupMediaFiles(ctx context.Context, media *models.Media) error {
	// 删除原始文件
	if media.LocalPath != "" {
		if err := s.storageManager.Delete(ctx, media.LocalPath); err != nil {
			s.log.Warn("failed to delete original file",
				logger.Error(err),
				logger.String("storage_key", media.LocalPath),
			)
		}
	}

	// 删除缩略图
	thumbnailKey, err := s.BuildThumbnailKey(media)
	if err == nil && thumbnailKey != "" {
		if err := s.storageManager.Delete(ctx, thumbnailKey); err != nil {
			s.log.Warn("failed to delete thumbnail",
				logger.Error(err),
				logger.String("storage_key", thumbnailKey),
			)
		}
	}

	// 删除预览图
	previewKey, err := s.BuildPreviewKey(media)
	if err == nil && previewKey != "" {
		if err := s.storageManager.Delete(ctx, previewKey); err != nil {
			s.log.Warn("failed to delete preview",
				logger.Error(err),
				logger.String("storage_key", previewKey),
			)
		}
	}

	return nil
}
