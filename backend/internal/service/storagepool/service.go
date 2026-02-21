package storagepool

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/datatypes"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/internal/storage/pooluri"
	"github.com/album/backend/pkg/logger"
)

// Service 存储池管理服务
type Service interface {
	List(ctx context.Context, filter repository.StoragePoolFilter) ([]*models.StoragePool, error)
	Get(ctx context.Context, uuid string) (*models.StoragePool, error)
	Create(ctx context.Context, input *CreateInput) (*CreateResult, error)
	Update(ctx context.Context, uuid string, input *UpdateInput) (*models.StoragePool, error)
	SetEnabled(ctx context.Context, uuid string, enabled bool) error
	Refresh(ctx context.Context) (*interfaces.PoolOperationResult, error)
	Reconcile(ctx context.Context, req *interfaces.PoolReconcileRequest) (*interfaces.PoolOperationResult, error)
	Usage(ctx context.Context, poolUUID string) ([]repository.StoragePoolUsageRow, error)
}

// CreateResult 创建存储池的结果
type CreateResult struct {
	Pool        *models.StoragePool
	RefreshInfo *RefreshInfo
}

// RefreshInfo 刷新操作信息
type RefreshInfo struct {
	Success bool   `json:"success"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
	TaskID  string `json:"task_id,omitempty"`
}

// CreateInput 创建存储池参数；仅使用 Location（URI）表示位置，存储类型由 location 的 scheme 派生。
type CreateInput struct {
	Name                 string
	Location             string // 存储池位置 URI，必填，如 local:///absolute/path；scheme 即存储类型
	CloudConfig          map[string]interface{}
	MaxSize              int64
	Priority             int
	Enabled              bool
	AutoDisableThreshold float64
	Description          string
}

// UpdateInput 更新存储池参数
type UpdateInput struct {
	Name                 *string
	Location             *string // 存储池位置 URI
	CloudConfig          map[string]interface{}
	MaxSize              *int64
	Priority             *int
	Enabled              *bool
	AutoDisableThreshold *float64
	Description          *string
}

type service struct {
	repo    repository.StoragePoolRepository
	storage storage.PrimaryStorage
	logger  logger.Logger
}

// NewService 创建存储池服务
func NewService(repo repository.StoragePoolRepository, storage storage.PrimaryStorage) Service {
	return &service{
		repo:    repo,
		storage: storage,
		logger:  logger.New("service.storagepool"),
	}
}

func (s *service) List(ctx context.Context, filter repository.StoragePoolFilter) ([]*models.StoragePool, error) {
	return s.repo.List(ctx, filter)
}

func (s *service) Get(ctx context.Context, id string) (*models.StoragePool, error) {
	return s.repo.FindByUUID(ctx, id)
}

func (s *service) Create(ctx context.Context, input *CreateInput) (*CreateResult, error) {
	if input == nil {
		return nil, fmt.Errorf("input is required")
	}
	if strings.TrimSpace(input.Name) == "" {
		return nil, fmt.Errorf("name is required")
	}
	location := strings.TrimSpace(input.Location)
	if location == "" {
		return nil, fmt.Errorf("location is required (e.g. local:///absolute/path)")
	}
	if input.MaxSize <= 0 {
		return nil, fmt.Errorf("max_size must be greater than 0")
	}

	scheme, path, err := pooluri.Parse(location)
	if err != nil {
		return nil, fmt.Errorf("invalid location: %w", err)
	}
	storageType := strings.ToLower(scheme)
	if !isSupportedStorageType(storageType) {
		return nil, fmt.Errorf("unsupported storage type in location scheme: %s", storageType)
	}
	if storageType == "local" {
		if err := pooluri.ValidateLocalPath(path); err != nil {
			return nil, fmt.Errorf("location path invalid: %w", err)
		}
	}
	location, err = normalizeLocationByScheme(storageType, location, path)
	if err != nil {
		return nil, fmt.Errorf("location: %w", err)
	}

	autoThreshold := input.AutoDisableThreshold
	if autoThreshold <= 0 || autoThreshold > 1 {
		autoThreshold = 0.9
	}

	cloudJSON, err := marshalCloudConfig(input.CloudConfig)
	if err != nil {
		return nil, err
	}

	pool := &models.StoragePool{
		UUID:                 uuid.NewString(),
		Name:                 input.Name,
		Description:          input.Description,
		StorageType:          storageType,
		Location:             location,
		CloudConfig:          cloudJSON,
		MaxSize:              input.MaxSize,
		CurrentSize:          0,
		Priority:             input.Priority,
		Enabled:              input.Enabled,
		AutoDisableThreshold: autoThreshold,
		Status:               "active",
	}
	if err := s.repo.Create(ctx, pool); err != nil {
		return nil, err
	}

	// Automatically refresh storage pool cache after creation
	refreshInfo := &RefreshInfo{
		Success: false,
	}

	if result, err := s.Refresh(ctx); err != nil {
		refreshInfo.Error = err.Error()
		refreshInfo.Message = "Auto refresh failed, please manually refresh the storage pool"
		s.logger.Warn(
			"auto refresh after pool creation failed",
			logger.String("pool_uuid", pool.UUID),
			logger.Error(err),
		)
	} else {
		refreshInfo.Success = true
		refreshInfo.Message = result.Message
		refreshInfo.TaskID = result.TaskID
		s.logger.Info(
			"auto refresh after pool creation succeeded",
			logger.String("pool_uuid", pool.UUID),
			logger.String("message", result.Message),
		)
	}

	return &CreateResult{
		Pool:        pool,
		RefreshInfo: refreshInfo,
	}, nil
}

func (s *service) Update(ctx context.Context, id string, input *UpdateInput) (*models.StoragePool, error) {
	if input == nil {
		return nil, fmt.Errorf("input is required")
	}
	updates := make(map[string]interface{})
	if input.Name != nil {
		updates["name"] = strings.TrimSpace(*input.Name)
	}
	if input.Location != nil {
		loc := strings.TrimSpace(*input.Location)
		if loc != "" {
			scheme, path, err := pooluri.Parse(loc)
			if err != nil {
				return nil, fmt.Errorf("invalid location: %w", err)
			}
			storageType := strings.ToLower(scheme)
			if !isSupportedStorageType(storageType) {
				return nil, fmt.Errorf("unsupported storage type in location scheme: %s", storageType)
			}
			if storageType == "local" {
				if err := pooluri.ValidateLocalPath(path); err != nil {
					return nil, fmt.Errorf("location path invalid: %w", err)
				}
			}
			loc, err = normalizeLocationByScheme(storageType, loc, path)
			if err != nil {
				return nil, err
			}
			updates["location"] = loc
			updates["storage_type"] = storageType
		}
	}
	if input.Description != nil {
		updates["description"] = strings.TrimSpace(*input.Description)
	}
	if input.MaxSize != nil {
		if *input.MaxSize <= 0 {
			return nil, fmt.Errorf("max_size must be greater than 0")
		}
		updates["max_size"] = *input.MaxSize
	}
	if input.Priority != nil {
		updates["priority"] = *input.Priority
	}
	if input.Enabled != nil {
		updates["enabled"] = *input.Enabled
	}
	if input.AutoDisableThreshold != nil {
		val := *input.AutoDisableThreshold
		if val <= 0 || val > 1 {
			return nil, fmt.Errorf("auto_disable_threshold must be within (0,1]")
		}
		updates["auto_disable_threshold"] = val
	}
	if input.CloudConfig != nil {
		cloudJSON, err := marshalCloudConfig(input.CloudConfig)
		if err != nil {
			return nil, err
		}
		updates["cloud_config"] = cloudJSON
	}

	if err := s.repo.UpdateByUUID(ctx, id, updates); err != nil {
		return nil, err
	}
	pool, err := s.repo.FindByUUID(ctx, id)
	if err != nil {
		return nil, err
	}
	// 与创建存储池一致：写库成功后立即刷新存储池缓存
	if result, err := s.Refresh(ctx); err != nil {
		s.logger.Warn("auto refresh after pool update failed", logger.String("pool_uuid", id), logger.Error(err))
	} else {
		s.logger.Info("auto refresh after pool update succeeded", logger.String("pool_uuid", id), logger.String("message", result.Message))
	}
	return pool, nil
}

func (s *service) SetEnabled(ctx context.Context, uuid string, enabled bool) error {
	if err := s.repo.SetEnabled(ctx, uuid, enabled); err != nil {
		return err
	}
	// 与创建存储池一致：写库成功后立即刷新存储池缓存（启用/禁用会影响缓存中的池列表）
	if result, err := s.Refresh(ctx); err != nil {
		s.logger.Warn("auto refresh after pool set-enabled failed", logger.String("pool_uuid", uuid), logger.Bool("enabled", enabled), logger.Error(err))
	} else {
		s.logger.Info("auto refresh after pool set-enabled succeeded", logger.String("pool_uuid", uuid), logger.Bool("enabled", enabled), logger.String("message", result.Message))
	}
	return nil
}

func (s *service) Refresh(ctx context.Context) (*interfaces.PoolOperationResult, error) {
	maintenance, ok := s.storage.(interfaces.PoolMaintenance)
	if !ok {
		return nil, fmt.Errorf("primary storage does not support pool refresh")
	}
	return maintenance.RefreshPools(ctx, &interfaces.PoolRefreshRequest{})
}

func (s *service) Reconcile(ctx context.Context, req *interfaces.PoolReconcileRequest) (*interfaces.PoolOperationResult, error) {
	maintenance, ok := s.storage.(interfaces.PoolMaintenance)
	if !ok {
		return nil, fmt.Errorf("primary storage does not support pool reconcile")
	}
	return maintenance.ReconcilePools(ctx, req)
}

func (s *service) Usage(ctx context.Context, poolUUID string) ([]repository.StoragePoolUsageRow, error) {
	return s.repo.FindUsage(ctx, poolUUID)
}

func marshalCloudConfig(config map[string]interface{}) (datatypes.JSON, error) {
	if len(config) == 0 {
		return nil, nil
	}
	data, err := json.Marshal(config)
	if err != nil {
		return nil, fmt.Errorf("marshal cloud_config: %w", err)
	}
	return datatypes.JSON(data), nil
}

func isSupportedStorageType(t string) bool {
	switch strings.ToLower(t) {
	case "local", "openlist", "s3", "oss", "cos":
		return true
	default:
		return false
	}
}

// normalizeLocationByScheme 按 scheme 规范化 location 后返回（如 local 转为绝对路径 URI）；非 local 返回原 location。
func normalizeLocationByScheme(scheme, location, path string) (string, error) {
	switch strings.ToLower(scheme) {
	case "local":
		return pooluri.BuildLocal(path)
	default:
		return location, nil
	}
}
