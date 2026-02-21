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
	"github.com/go-viper/mapstructure/v2"
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

// Load 加载配置。
// 优先级：命令行参数（仅当显式传入）> 环境变量 > 配置文件 > 默认值。
// 未显式设置的命令行 flag 不会以其默认值覆盖配置文件或环境变量（即仅当用户传入如 --server.public_base_url 时命令行才覆盖）；传入 flags 为 nil 时仍会从配置文件或环境变量补全。
// 自定义类型（types.Duration、types.Size）在 Unmarshal 阶段通过 DecodeHook 统一解析，所有需合并字段均带 mapstructure tag，仅此一条解析路径，无 bindCustomTypes 等第二套逻辑。
// 如果配置文件不存在，会自动生成一份默认配置文件。
func (l *Loader) Load(flags *pflag.FlagSet) (*Config, error) {
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

	// 3. 使用 Viper 的 Unmarshal 覆盖存在的字段；自定义类型（Duration、Size）在 Unmarshal 阶段通过 DecodeHook 统一解析，所有需合并字段均带 mapstructure tag，仅此一条解析路径。
	if err := l.v.Unmarshal(cfg, viper.DecodeHook(mapstructure.ComposeDecodeHookFunc(
		mapstructure.StringToTimeDurationHookFunc(),
		mapstructure.StringToSliceHookFunc(","),
		decodeHookDurationAndSize(),
	))); err != nil {
		return nil, fmt.Errorf("unmarshal config: %w", err)
	}

	// 4. 未显式设置的 flag 不覆盖 config/env：仅当用户显式传入该参数时才用 flag 值；否则从配置文件或环境变量补全（保证「仅 env」或「仅文件」均生效）
	if cfg.Server != nil {
		useFlag := flags != nil && flags.Changed("server.public_base_url")
		if !useFlag {
			if v := l.getFromConfigOrEnv("server.public_base_url"); v != "" {
				cfg.Server.PublicBaseURL = v
			}
		}
	}

	// 5. 显式用环境变量覆盖 storage 路径（Viper Unmarshal 对嵌套 key 不会应用 AutomaticEnv，故在此补全）
	if cfg.Storage != nil && cfg.Storage.Primary != nil && cfg.Storage.Primary.Local != nil {
		if v := l.getFromConfigOrEnv("storage.primary.local.data_dir"); v != "" {
			cfg.Storage.Primary.Local.DataDir = v
		}
		if cfg.Storage.Primary.Local.Temp != nil {
			if v := l.getFromConfigOrEnv("storage.primary.local.temp.base_path"); v != "" {
				cfg.Storage.Primary.Local.Temp.BasePath = v
			}
		}
		if cfg.Storage.Primary.Local.Performance != nil {
			if v := l.getFromConfigOrEnv("storage.primary.local.performance.cache_path"); v != "" {
				cfg.Storage.Primary.Local.Performance.CachePath = v
			}
		}
	}

	return cfg, nil
}

// decodeHookDurationAndSize 将配置中的字符串解码为 types.Duration 与 types.Size，供 Viper Unmarshal 使用，使自定义类型与其它字段在同一阶段完成合并。
func decodeHookDurationAndSize() mapstructure.DecodeHookFunc {
	return func(f, t reflect.Type, data interface{}) (interface{}, error) {
		if f != nil && f.Kind() != reflect.String {
			return data, nil
		}
		s, _ := data.(string)
		if t == reflect.TypeOf(types.Duration(0)) {
			d, err := time.ParseDuration(s)
			if err != nil {
				return nil, err
			}
			return types.Duration(d), nil
		}
		if t == reflect.TypeOf(types.Size(0)) {
			n, err := parseSizeString(s)
			if err != nil {
				return nil, err
			}
			return types.Size(n), nil
		}
		return data, nil
	}
}

// getFromConfigOrEnv 从仅包含配置文件与环境变量的 Viper 中读取 key（不包含已绑定的 flag），用于「未显式设置的 flag 不覆盖」时的还原。
func (l *Loader) getFromConfigOrEnv(key string) string {
	v := viper.New()
	v.SetEnvPrefix("ALBUM")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()
	v.SetConfigFile(l.configPath)
	_ = v.ReadInConfig() // 忽略错误，无文件时仅依赖 env
	return v.GetString(key)
}

// isFileNotFoundError 检查错误是否是文件不存在的错误
func (l *Loader) isFileNotFoundError(err error) bool {
	var configFileNotFoundErr viper.ConfigFileNotFoundError
	var pathErr *os.PathError

	return errors.As(err, &configFileNotFoundErr) ||
		(errors.As(err, &pathErr) && os.IsNotExist(pathErr.Err))
}

// parseSizeString 解析大小字符串（如 "1GB", "500MB"），供 DecodeHook 与 YAML 序列化复用。
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
			PublicBaseURL: "http://10.168.1.161",
			ReadTimeout:   types.Duration(1 * time.Hour),
			WriteTimeout:  types.Duration(1 * time.Hour),
			IdleTimeout:   types.Duration(2 * time.Minute),
		},
		Database: &database.Config{
			Type: "postgres",
			DSN:  "host=127.0.0.1 user=album password=album@2025 dbname=album port=15432 sslmode=disable TimeZone=Asia/Shanghai",
		},
		// Storage: 池根由 DB（storage_pools 表）location 管理；DataDir 仅用于 temp、staging、cache 工作根，不参与池内文件路径。
		Storage: &storage.Config{
			Primary: &storage.PrimaryStorageConfig{
				Type: "local",
				Local: &storage.LocalStorageConfig{
					DataDir: "./data",
					PoolManager: &storage.PoolManagerConfig{
						DeltaChannelSize:     1024,
						DeltaBatchSize:       128,
						FlushInterval:        types.Duration(2 * time.Second),
						CacheRefreshInterval: types.Duration(5 * time.Minute),
						ReconcileInterval:    types.Duration(0),
					},
					Temp: &storage.TempFileConfig{
						BasePath:        "", // 空时由 factory 设为 data_dir/temp
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
						CachePath:       "", // 空时由 factory 设为 data_dir/cache
						CacheSize:       types.Size(100 * 1024 * 1024), // 100MB
						CacheTTL:        types.Duration(24 * time.Hour),
						ReadBufferSize:  types.Size(64 * 1024),         // 64KB
						WriteBufferSize: types.Size(64 * 1024),         // 64KB
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
