package config

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"time"

	"github.com/album/backend/internal/config/types"
	"github.com/album/backend/internal/database"
	"github.com/album/backend/internal/server"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
	"github.com/goccy/go-yaml"
	"github.com/spf13/pflag"
	"github.com/spf13/viper"
)

// Loader 配置加载器
type Loader struct {
	v          *viper.Viper
	configPath string
}

// NewLoader 创建配置加载器
func NewLoader(configPath string) *Loader {
	v := viper.New()

	// 设置环境变量前缀和替换规则
	v.SetEnvPrefix("ALBUM")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv() // 自动读取环境变量

	// 如果没有提供配置文件路径，使用当前目录下的 config.yaml
	if configPath == "" {
		configPath = "config.yaml"
	}

	v.SetConfigFile(configPath)

	return &Loader{
		v:          v,
		configPath: configPath,
	}
}

// BindPFlags 绑定命令行参数到 Viper
func (l *Loader) BindPFlags(flags *pflag.FlagSet) {
	_ = l.v.BindPFlags(flags)
}

// Load 加载配置
// 优先级：命令行参数 > 环境变量 > 配置文件 > 默认值
// 如果配置文件不存在，会自动生成一份默认配置文件
func (l *Loader) Load() (*Config, error) {
	// 1. 先创建完整默认配置
	cfg := l.defaultConfig()

	// 2. 尝试读取配置文件
	if err := l.v.ReadInConfig(); err != nil {
		// 检查是否是文件不存在的错误
		if !l.isFileNotFoundError(err) {
			return nil, fmt.Errorf("read config file: %w", err)
		}

		// 配置文件不存在，生成默认配置文件
		if err := l.Save(cfg); err != nil {
			return nil, fmt.Errorf("generate default config file: %w", err)
		}

		// 重新读取生成的配置文件
		if err := l.v.ReadInConfig(); err != nil {
			return nil, fmt.Errorf("read generated config file: %w", err)
		}
	}

	// 3. 使用 Viper 的 Unmarshal 自动覆盖存在的字段
	// Viper 只会覆盖配置文件中存在的字段，不存在的字段保持默认值
	if err := l.v.Unmarshal(cfg); err != nil {
		return nil, fmt.Errorf("unmarshal config: %w", err)
	}

	// 4. 处理自定义类型（Duration 和 Size）
	// 因为 Viper 可能无法直接处理这些自定义类型，需要手动转换
	if err := l.bindCustomTypes(cfg); err != nil {
		return nil, fmt.Errorf("bind custom types: %w", err)
	}

	// 不再验证，让运行时错误自然暴露
	return cfg, nil
}

// isFileNotFoundError 检查错误是否是文件不存在的错误
func (l *Loader) isFileNotFoundError(err error) bool {
	var configFileNotFoundErr viper.ConfigFileNotFoundError
	var pathErr *os.PathError

	return errors.As(err, &configFileNotFoundErr) ||
		(errors.As(err, &pathErr) && os.IsNotExist(pathErr.Err))
}

// bindCustomTypes 处理自定义类型（Duration 和 Size）
// 从 Viper 读取字符串值，然后转换为自定义类型
func (l *Loader) bindCustomTypes(cfg *Config) error {
	// 使用反射遍历配置结构体，处理 Duration 和 Size 字段
	return l.bindCustomTypesRecursive(cfg, "")
}

// bindCustomTypesRecursive 递归处理自定义类型
func (l *Loader) bindCustomTypesRecursive(v interface{}, prefix string) error {
	val := reflect.ValueOf(v)
	if val.Kind() == reflect.Ptr {
		if val.IsNil() {
			return nil
		}
		val = val.Elem()
	}

	if val.Kind() != reflect.Struct {
		return nil
	}

	typ := val.Type()
	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)

		// 跳过不可设置的字段
		if !field.CanSet() {
			continue
		}

		// 获取字段的 YAML 标签
		yamlTag := fieldType.Tag.Get("yaml")
		if yamlTag == "" || yamlTag == "-" {
			continue
		}

		// 构建配置路径
		fieldPath := yamlTag
		if prefix != "" {
			fieldPath = prefix + "." + yamlTag
		}

		// 处理指针字段
		if field.Kind() == reflect.Ptr {
			if field.IsNil() {
				continue
			}
			field = field.Elem()
		}

		// 处理 Duration 类型
		if field.Type() == reflect.TypeOf(types.Duration(0)) {
			if str := l.v.GetString(fieldPath); str != "" {
				if d, err := time.ParseDuration(str); err == nil {
					field.Set(reflect.ValueOf(types.Duration(d)))
				}
			}
			continue
		}

		// 处理 Size 类型
		if field.Type() == reflect.TypeOf(types.Size(0)) {
			if str := l.v.GetString(fieldPath); str != "" {
				if size, err := parseSizeString(str); err == nil {
					field.Set(reflect.ValueOf(types.Size(size)))
				}
			}
			continue
		}

		// 递归处理嵌套结构
		if field.Kind() == reflect.Struct {
			if err := l.bindCustomTypesRecursive(field.Addr().Interface(), fieldPath); err != nil {
				return err
			}
		}
	}

	return nil
}

// parseSizeString 解析大小字符串（如 "1GB", "500MB"）
func parseSizeString(s string) (int64, error) {
	s = strings.TrimSpace(s)
	s = strings.ToUpper(s)
	s = strings.ReplaceAll(s, " ", "")

	units := []string{"TB", "GB", "MB", "KB", "B"}
	var unit string
	var valueStr string

	for _, u := range units {
		if strings.HasSuffix(s, u) {
			unit = u
			valueStr = strings.TrimSuffix(s, u)
			break
		}
	}

	if unit == "" {
		// 没有单位，尝试直接解析为字节
		var result int64
		if _, err := fmt.Sscanf(s, "%d", &result); err != nil {
			return 0, fmt.Errorf("invalid size format: %s", s)
		}
		return result, nil
	}

	var value float64
	if _, err := fmt.Sscanf(valueStr, "%f", &value); err != nil {
		return 0, fmt.Errorf("invalid size value: %s", valueStr)
	}

	var multiplier int64
	switch unit {
	case "TB":
		multiplier = 1024 * 1024 * 1024 * 1024
	case "GB":
		multiplier = 1024 * 1024 * 1024
	case "MB":
		multiplier = 1024 * 1024
	case "KB":
		multiplier = 1024
	case "B":
		multiplier = 1
	default:
		return 0, fmt.Errorf("unknown size unit: %s", unit)
	}

	return int64(value * float64(multiplier)), nil
}

// defaultConfig 返回完整默认配置
func (l *Loader) defaultConfig() *Config {
	return &Config{
		Server: &server.Config{
			Host:          "0.0.0.0",
			Port:          8080,
			PublicBaseURL: "http://10.168.1.161:8080",
			ReadTimeout:   types.Duration(1 * time.Hour),
			WriteTimeout:  types.Duration(1 * time.Hour),
			IdleTimeout:   types.Duration(2 * time.Minute),
		},
		Database: &database.Config{
			Type: "postgres",
			DSN:  "host=127.0.0.1 user=album password=album@2025 dbname=album port=15432 sslmode=disable TimeZone=Asia/Shanghai",
		},
		Storage: &storage.Config{
			Primary: &storage.PrimaryStorageConfig{
				Type: "local",
				Local: &storage.LocalStorageConfig{
					BasePath: "./base",
					PoolManager: &storage.PoolManagerConfig{
						DeltaChannelSize:     1024,
						DeltaBatchSize:       128,
						FlushInterval:        types.Duration(2 * time.Second),
						CacheRefreshInterval: types.Duration(5 * time.Minute),
						ReconcileInterval:    types.Duration(0),
					},
					Temp: &storage.TempFileConfig{
						BasePath:        "./data/temp",
						MaxAge:          types.Duration(24 * time.Hour),
						MaxSize:         types.Size(10 * 1024 * 1024 * 1024), // 10GB
						CleanupInterval: types.Duration(1 * time.Hour),
					},
					Processing: &storage.ProcessingConfig{
						EnableCompression: false,
						CompressionLevel:  6,
						EnableEncryption:  false,
						EncryptionKeyPath: "",
					},
					Performance: &storage.PerformanceConfig{
						CacheEnabled:    false,
						CacheSize:       types.Size(100 * 1024 * 1024), // 100MB
						CacheTTL:        types.Duration(24 * time.Hour),
						ReadBufferSize:  types.Size(64 * 1024), // 64KB
						WriteBufferSize: types.Size(64 * 1024), // 64KB
					},
				},
			},
		},
		Auth: &auth.Config{
			JWTSecret:             "change-me",
			AccessTokenExpiresIn:  types.Duration(30 * time.Minute),
			RefreshTokenExpiresIn: types.Duration(24 * time.Hour * 30),
			AppleAppBundleID:      "",
			AvatarSavePath:        "./public/avatars",
			MaxAvatarSize:         types.Size(5 * 1024 * 1024),
			URLSignerSecret:       "change-me-too",
			SignedURLLoadTTL:      types.Duration(30 * time.Minute),
		},
		API: &APIConfig{
			MaxFileSize: types.Size(10 * 1024 * 1024 * 1024), // 10GB
		},
		Logger: &logger.Config{
			Level:  "debug",
			Format: "console",
			Output: "stdout",
		},
		Queue: gq.DefaultServerConfig(),
		Media: mediaprocessor.DefaultConfig(),
	}
}

// Save 保存配置到YAML文件
func (l *Loader) Save(cfg *Config) error {
	// 确保目录存在
	dir := filepath.Dir(l.configPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("create config directory: %w", err)
	}

	data, err := yaml.Marshal(cfg)
	if err != nil {
		return fmt.Errorf("marshal yaml: %w", err)
	}

	if err := os.WriteFile(l.configPath, data, 0644); err != nil {
		return fmt.Errorf("write config file: %w", err)
	}

	return nil
}
