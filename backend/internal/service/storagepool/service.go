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
)

// Service 存储池管理服务
type Service interface {
	List(ctx context.Context, filter repository.StoragePoolFilter) ([]*models.StoragePool, error)
	Get(ctx context.Context, uuid string) (*models.StoragePool, error)
	Create(ctx context.Context, input *CreateInput) (*models.StoragePool, error)
	Update(ctx context.Context, uuid string, input *UpdateInput) (*models.StoragePool, error)
	SetEnabled(ctx context.Context, uuid string, enabled bool) error
	Refresh(ctx context.Context) (*interfaces.PoolOperationResult, error)
	Reconcile(ctx context.Context, req *interfaces.PoolReconcileRequest) (*interfaces.PoolOperationResult, error)
	Usage(ctx context.Context, poolUUID string) ([]repository.StoragePoolUsageRow, error)
}

// CreateInput 创建存储池参数
type CreateInput struct {
	Name                 string
	StorageType          string
	LocalPath            string
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
	LocalPath            *string
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
}

// NewService 创建存储池服务
func NewService(repo repository.StoragePoolRepository, storage storage.PrimaryStorage) Service {
	return &service{
		repo:    repo,
		storage: storage,
	}
}

func (s *service) List(ctx context.Context, filter repository.StoragePoolFilter) ([]*models.StoragePool, error) {
	return s.repo.List(ctx, filter)
}

func (s *service) Get(ctx context.Context, id string) (*models.StoragePool, error) {
	return s.repo.FindByUUID(ctx, id)
}

func (s *service) Create(ctx context.Context, input *CreateInput) (*models.StoragePool, error) {
	if input == nil {
		return nil, fmt.Errorf("input is required")
	}
	if strings.TrimSpace(input.Name) == "" {
		return nil, fmt.Errorf("name is required")
	}
	storageType := strings.ToLower(strings.TrimSpace(input.StorageType))
	if storageType == "" {
		return nil, fmt.Errorf("storage_type is required")
	}
	if !isSupportedStorageType(storageType) {
		return nil, fmt.Errorf("unsupported storage type: %s", storageType)
	}
	if storageType == "local" && strings.TrimSpace(input.LocalPath) == "" {
		return nil, fmt.Errorf("local_path is required for local storage type")
	}
	if input.MaxSize <= 0 {
		return nil, fmt.Errorf("max_size must be greater than 0")
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
		LocalPath:            input.LocalPath,
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
	return pool, nil
}

func (s *service) Update(ctx context.Context, id string, input *UpdateInput) (*models.StoragePool, error) {
	if input == nil {
		return nil, fmt.Errorf("input is required")
	}
	updates := make(map[string]interface{})
	if input.Name != nil {
		updates["name"] = strings.TrimSpace(*input.Name)
	}
	if input.LocalPath != nil {
		updates["local_path"] = strings.TrimSpace(*input.LocalPath)
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
	return s.repo.FindByUUID(ctx, id)
}

func (s *service) SetEnabled(ctx context.Context, uuid string, enabled bool) error {
	return s.repo.SetEnabled(ctx, uuid, enabled)
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
