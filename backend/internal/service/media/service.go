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
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
	"github.com/gabriel-vasile/mimetype"
	"gorm.io/gorm"
)

// UploadMediaRequest 上传媒体请求
type UploadMediaRequest struct {
	UserID           uint
	Hash             string
	ItemType         string
	OriginalFilename string
	CloudUUID        string
	MediaTakenAt     *time.Time
	Filename         string
	FileSize         int64
	Data             io.Reader
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
	thumbnailQueue *ThumbnailQueue // 缩略图生成队列
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

	return &service{
		log:            logger.New("service.media"),
		repo:           repo,
		storageManager: storageManager,
		taskQueue:      taskQueue,
		processor:      processor,
		processorCfg:   processorCfg,
		storageAdapter: NewStorageAdapter(),
		thumbnailQueue: thumbnailQueue,
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

// UploadMedia 上传媒体文件（流式处理，使用客户端传入的Hash）
// 注意：秒传检查已在Handler层完成，这里直接进行上传
func (s *service) UploadMedia(ctx context.Context, req *UploadMediaRequest) (*models.Media, error) {
	if err := validateHash(req.Hash); err != nil {
		return nil, err
	}

	ext, normalizedExt := resolveExtensions(req.ItemType, req.Filename)

	// 使用存储适配器构建存储key和选项
	storageKey, err := s.storageAdapter.BuildStorageKey(req.Hash, req.ItemType, MediaFileTypeOriginal, normalizedExt)
	if err != nil {
		return nil, fmt.Errorf("build storage key: %w", err)
	}

	putOpts, err := s.storageAdapter.ToStorageOptions(req.ItemType, MediaFileTypeOriginal, normalizedExt)
	if err != nil {
		return nil, fmt.Errorf("build storage options: %w", err)
	}
	putOpts.UserID = req.UserID

	headBuf, err := readHead(req.Data, sniffBufferSize)
	if err != nil {
		return nil, err
	}

	mimeType := detectMimeType(headBuf, normalizedExt, ext)
	dataReader := wrapDataReader(req.Data, headBuf)

	if err := s.storageManager.Put(ctx, storageKey, dataReader, req.FileSize, putOpts); err != nil {
		return nil, fmt.Errorf("upload to storage: %w", err)
	}

	localPoolUUID := ""
	if putOpts != nil {
		localPoolUUID = putOpts.PoolID
	}

	media := s.newMediaModel(req, storageKey, mimeType, localPoolUUID)
	if err := s.repo.Create(ctx, media); err != nil {
		s.storageManager.Delete(ctx, storageKey)
		return nil, fmt.Errorf("create media record: %w", err)
	}

	s.enqueueMediaProcessingTask(ctx, req, storageKey)

	s.log.Info("media uploaded successfully",
		logger.String("uuid", req.CloudUUID),
		logger.String("hash", req.Hash),
		logger.Uint("user_id", req.UserID),
		logger.Int64("file_size", req.FileSize),
	)

	return media, nil
}

const sniffBufferSize = 8192

func validateHash(hash string) error {
	if len(hash) < 4 {
		return fmt.Errorf("invalid hash length: must be at least 4 characters")
	}
	return nil
}

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

func wrapDataReader(data io.Reader, head []byte) io.Reader {
	if len(head) == 0 {
		return data
	}
	return io.MultiReader(bytes.NewReader(head), data)
}

func (s *service) newMediaModel(req *UploadMediaRequest, storageKey, mimeType string, localPoolUUID string) *models.Media {
	return &models.Media{
		UUID:             req.CloudUUID,
		UserID:           req.UserID,
		Hash:             req.Hash,
		ItemType:         strings.ToLower(req.ItemType),
		OriginalFilename: req.OriginalFilename,
		Filename:         req.Filename,
		FileSize:         req.FileSize,
		MimeType:         mimeType,
		MediaTakenAt:     req.MediaTakenAt,
		ProcessingStatus: "PROCESSING",
		Deleted:          false,
		LocalPath:        storageKey,
		LocalPoolUUID:    localPoolUUID,
		BackupStatus:     "pending",
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
	// 解析尺寸参数
	size, err := ParseThumbnailSize(sizeParam)
	if err != nil {
		return nil, fmt.Errorf("parse size: %w", err)
	}

	// 检查是否是预设尺寸（thumbnail 或 preview）
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
			return s.storageManager.Get(ctx, key)
		}
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
			return s.storageManager.Get(ctx, key)
		}
		// 如果不存在，降级到动态生成（使用 1280x0）
		size = &ThumbnailSize{Width: 1280, Height: 0}
	}

	// 构建动态缩略图 key
	dynamicKey, err := s.BuildDynamicThumbnailKey(media, size.Width, size.Height)
	if err != nil {
		return nil, fmt.Errorf("build dynamic thumbnail key: %w", err)
	}

	// 检查动态缩略图是否已存在
	exists, err := s.storageManager.Exists(ctx, dynamicKey)
	if err != nil {
		return nil, fmt.Errorf("check dynamic thumbnail exists: %w", err)
	}

	if exists {
		// 直接返回
		return s.storageManager.Get(ctx, dynamicKey)
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
		s.log.Debug("thumbnail generation in progress, waiting or returning fallback",
			logger.String("key", dynamicKey),
			logger.String("media_uuid", media.UUID),
		)

		// 如果有 ThumbHash，返回降级方案
		if media.ThumbHash != "" {
			return s.getThumbHashFallback(media.ThumbHash)
		}

		// 等待生成完成（最多等待5秒）
		select {
		case err := <-waitCh:
			if err != nil {
				// 生成失败，返回降级方案
				if media.ThumbHash != "" {
					return s.getThumbHashFallback(media.ThumbHash)
				}
				return nil, fmt.Errorf("thumbnail generation failed: %w", err)
			}
			// 生成成功，重新获取
			return s.storageManager.Get(ctx, dynamicKey)
		case <-time.After(5 * time.Second):
			// 超时，返回降级方案
			if media.ThumbHash != "" {
				return s.getThumbHashFallback(media.ThumbHash)
			}
			return nil, fmt.Errorf("thumbnail generation timeout")
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	// 获得了生成权限，异步生成
	go s.generateThumbnailAsync(ctx, media, size, dynamicKey, task)

	// 立即返回降级方案（ThumbHash 或预生成缩略图）
	if media.ThumbHash != "" {
		return s.getThumbHashFallback(media.ThumbHash)
	}

	// 如果没有 ThumbHash，尝试返回预生成的缩略图作为降级方案
	fallbackKey, _ := s.BuildThumbnailKey(media)
	if exists, _ := s.storageManager.Exists(ctx, fallbackKey); exists {
		return s.storageManager.Get(ctx, fallbackKey)
	}

	// 没有降级方案，返回错误
	return nil, fmt.Errorf("thumbnail not available and generation in progress")
}

// generateThumbnailAsync 异步生成缩略图
func (s *service) generateThumbnailAsync(ctx context.Context, media *models.Media, size *ThumbnailSize, dynamicKey string, task *ThumbnailGenerationTask) {
	defer s.thumbnailQueue.Complete(dynamicKey, nil)

	// 1. 获取原始文件路径
	originalPath, err := s.storageManager.GetSignedURL(ctx, media.LocalPath, 10*time.Minute)
	if err != nil {
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("get original file path: %w", err))
		return
	}

	// 2. 生成缩略图
	// 构建 ImageSpec（使用 MaxWidth 和 MaxHeight）
	spec := mediaprocessor.ImageSpec{
		MaxWidth:  size.Width,
		MaxHeight: size.Height,
		Format:    "jpg",
		Quality:   85,
		Crop:      size.Height > 0, // 如果指定了高度，则允许裁剪
	}

	var thumbnailPath string
	if strings.EqualFold(media.ItemType, "image") {
		thumbnailPath, err = s.processor.GenerateThumbnail(ctx, originalPath, spec)
	} else if strings.EqualFold(media.ItemType, "video") {
		// 对于视频，使用预生成的缩略图作为源来生成动态尺寸
		thumbnailKey, _ := s.BuildThumbnailKey(media)
		sourcePath := originalPath

		// 尝试使用预生成的缩略图作为源
		if exists, _ := s.storageManager.Exists(ctx, thumbnailKey); exists {
			sourcePath, _ = s.storageManager.GetSignedURL(ctx, thumbnailKey, 10*time.Minute)
		}

		// 从源图片生成动态尺寸缩略图
		thumbnailPath, err = s.processor.GenerateThumbnail(ctx, sourcePath, spec)
	} else {
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("unsupported item type: %s", media.ItemType))
		return
	}

	if err != nil {
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("generate thumbnail: %w", err))
		return
	}

	// 3. 读取生成的缩略图文件
	thumbnailFile, err := os.Open(thumbnailPath)
	if err != nil {
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("open generated thumbnail file: %w", err))
		return
	}
	defer thumbnailFile.Close()

	// 4. 读取文件数据
	thumbnailData, err := io.ReadAll(thumbnailFile)
	if err != nil {
		s.thumbnailQueue.Complete(dynamicKey, fmt.Errorf("read thumbnail data: %w", err))
		return
	}

	// 5. 存储到动态 key
	if err := s.storageManager.Put(ctx, dynamicKey, bytes.NewReader(thumbnailData), int64(len(thumbnailData)), nil); err != nil {
		s.log.Warn("failed to store dynamic thumbnail",
			logger.Error(err),
			logger.String("key", dynamicKey),
		)
		s.thumbnailQueue.Complete(dynamicKey, err)
		return
	}

	s.log.Info("dynamic thumbnail generated successfully",
		logger.String("key", dynamicKey),
		logger.String("media_uuid", media.UUID),
		logger.String("size", fmt.Sprintf("%dx%d", size.Width, size.Height)),
	)
}

// getThumbHashFallback 返回 ThumbHash 占位符（作为降级方案）
// 注意：这里返回一个简单的占位符响应，实际应该返回 ThumbHash 编码的图片
// 为了简化，这里返回一个提示信息，前端应该使用 ThumbHash 来渲染占位符
func (s *service) getThumbHashFallback(thumbHash string) (io.ReadCloser, error) {
	// 返回一个简单的占位符图片（1x1 透明 PNG）
	// 实际应用中，前端应该使用 ThumbHash 来渲染占位符
	// 这里返回一个最小的 PNG 图片作为占位符
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

	// 2. 删除存储中的文件
	if err := s.cleanupMediaFiles(ctx, media); err != nil {
		s.log.Warn("failed to cleanup media files",
			logger.Error(err),
			logger.String("uuid", mediaUUID),
		)
		// 继续删除数据库记录，即使文件删除失败
	}

	// 3. 永久删除数据库记录
	if err := s.repo.Purge(ctx, mediaUUID); err != nil {
		return fmt.Errorf("purge media: %w", err)
	}

	s.log.Info("media purged permanently",
		logger.String("uuid", mediaUUID),
		logger.Uint("user_id", userID),
	)

	return nil
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
