package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/album/backend/internal/config/modules"
	"github.com/goccy/go-yaml"
)

// Loader 配置加载器
type Loader struct {
	configPath string
}

// NewLoader 创建配置加载器
func NewLoader(configPath string) *Loader {
	return &Loader{
		configPath: configPath,
	}
}

// Load 加载配置（YAML + 环境变量）
func (l *Loader) Load() (*Config, error) {
	// 1. 加载YAML文件
	cfg, err := l.loadYAML()
	if err != nil {
		return nil, fmt.Errorf("load yaml: %w", err)
	}

	// 2. 覆盖环境变量
	l.overrideWithEnv(cfg)

	// 3. 验证配置
	if err := cfg.Validate(); err != nil {
		return nil, fmt.Errorf("validate config: %w", err)
	}

	return cfg, nil
}

// loadYAML 加载YAML文件
func (l *Loader) loadYAML() (*Config, error) {
	// 如果配置文件不存在，返回默认配置
	if _, err := os.Stat(l.configPath); os.IsNotExist(err) {
		return l.defaultConfig(), nil
	}

	data, err := os.ReadFile(l.configPath)
	if err != nil {
		return nil, fmt.Errorf("read config file: %w", err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("parse yaml: %w", err)
	}

	return &cfg, nil
}

// overrideWithEnv 使用环境变量覆盖配置（所有环境变量使用 ALBUM_ 前缀）
func (l *Loader) overrideWithEnv(cfg *Config) {
	// 存储配置
	if cfg.Storage != nil {
		if cfg.Storage.Primary != nil && cfg.Storage.Primary.Local != nil {
			if basePath := os.Getenv("ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH"); basePath != "" {
				cfg.Storage.Primary.Local.BasePath = basePath
			}
		}
	}

	// 服务器配置
	if cfg.Server != nil {
		if host := os.Getenv("ALBUM_SERVER_HOST"); host != "" {
			cfg.Server.Host = host
		}
		if port := os.Getenv("ALBUM_SERVER_PORT"); port != "" {
			var p int
			if _, err := fmt.Sscanf(port, "%d", &p); err == nil {
				cfg.Server.Port = p
			}
		}
		if publicBaseURL := os.Getenv("ALBUM_SERVER_PUBLIC_BASE_URL"); publicBaseURL != "" {
			cfg.Server.PublicBaseURL = publicBaseURL
		}
	}

	// 数据库配置
	if cfg.Database != nil {
		if dbType := os.Getenv("ALBUM_DATABASE_TYPE"); dbType != "" {
			cfg.Database.Type = dbType
		}
		if dsn := os.Getenv("ALBUM_DATABASE_DSN"); dsn != "" {
			cfg.Database.DSN = dsn
		}
	}

	// 认证配置
	if cfg.Auth != nil {
		if secret := os.Getenv("ALBUM_AUTH_JWT_SECRET"); secret != "" {
			cfg.Auth.JWTSecret = secret
		}
		if accessTTL := os.Getenv("ALBUM_AUTH_ACCESS_TOKEN_EXPIRES_IN"); accessTTL != "" {
			if duration, err := time.ParseDuration(accessTTL); err == nil {
				cfg.Auth.AccessTokenExpiresIn = modules.Duration(duration)
			}
		}
		if refreshTTL := os.Getenv("ALBUM_AUTH_REFRESH_TOKEN_EXPIRES_IN"); refreshTTL != "" {
			if duration, err := time.ParseDuration(refreshTTL); err == nil {
				cfg.Auth.RefreshTokenExpiresIn = modules.Duration(duration)
			}
		}
		if bundleID := os.Getenv("ALBUM_AUTH_APPLE_APP_BUNDLE_ID"); bundleID != "" {
			cfg.Auth.AppleAppBundleID = bundleID
		}
		if avatarPath := os.Getenv("ALBUM_AUTH_AVATAR_SAVE_PATH"); avatarPath != "" {
			cfg.Auth.AvatarSavePath = avatarPath
		}
		if maxAvatar := os.Getenv("ALBUM_AUTH_MAX_AVATAR_SIZE"); maxAvatar != "" {
			if size, err := parseSize(maxAvatar); err == nil {
				cfg.Auth.MaxAvatarSize = modules.Size(size)
			}
		}
		if signerSecret := os.Getenv("ALBUM_AUTH_URL_SIGNER_SECRET"); signerSecret != "" {
			cfg.Auth.URLSignerSecret = signerSecret
		}
		if signedTTL := os.Getenv("ALBUM_AUTH_SIGNED_URL_LOAD_TTL"); signedTTL != "" {
			if duration, err := time.ParseDuration(signedTTL); err == nil {
				cfg.Auth.SignedURLLoadTTL = modules.Duration(duration)
			}
		}
	}

	// 媒体配置
	if cfg.Media != nil {
		if maxSize := os.Getenv("ALBUM_MEDIA_MAX_FILE_SIZE"); maxSize != "" {
			if size, err := parseSize(maxSize); err == nil {
				cfg.Media.MaxFileSize = modules.Size(size)
			}
		}
		if cfg.Media.Processor != nil {
			// Imagick配置
			if cfg.Media.Processor.Imagick != nil {
				if poolSize := os.Getenv("ALBUM_MEDIA_PROCESSOR_IMAGICK_POOL_SIZE"); poolSize != "" {
					if ps, err := strconv.Atoi(poolSize); err == nil {
						cfg.Media.Processor.Imagick.PoolSize = ps
					}
				}
				if memLimit := os.Getenv("ALBUM_MEDIA_PROCESSOR_IMAGICK_MEMORY_LIMIT"); memLimit != "" {
					cfg.Media.Processor.Imagick.MemoryLimit = memLimit
				}
				if diskLimit := os.Getenv("ALBUM_MEDIA_PROCESSOR_IMAGICK_DISK_LIMIT"); diskLimit != "" {
					cfg.Media.Processor.Imagick.DiskLimit = diskLimit
				}
			}
			// FFmpeg配置
			if cfg.Media.Processor.FFmpeg != nil {
				if binPath := os.Getenv("ALBUM_MEDIA_PROCESSOR_FFMPEG_BINARY_PATH"); binPath != "" {
					cfg.Media.Processor.FFmpeg.BinaryPath = binPath
				}
				if probePath := os.Getenv("ALBUM_MEDIA_PROCESSOR_FFMPEG_PROBE_PATH"); probePath != "" {
					cfg.Media.Processor.FFmpeg.ProbePath = probePath
				}
				if maxConcurrency := os.Getenv("ALBUM_MEDIA_PROCESSOR_FFMPEG_MAX_CONCURRENCY"); maxConcurrency != "" {
					if mc, err := strconv.Atoi(maxConcurrency); err == nil {
						cfg.Media.Processor.FFmpeg.MaxConcurrency = mc
					}
				}
			}
			// 并发配置
			if concurrency := os.Getenv("ALBUM_MEDIA_PROCESSOR_CONCURRENCY"); concurrency != "" {
				if c, err := strconv.Atoi(concurrency); err == nil {
					cfg.Media.Processor.Concurrency = c
				}
			}
		}
	}

	// 日志配置
	if cfg.Logger != nil {
		if level := os.Getenv("ALBUM_LOGGER_LEVEL"); level != "" {
			cfg.Logger.Level = level
		}
		if format := os.Getenv("ALBUM_LOGGER_FORMAT"); format != "" {
			cfg.Logger.Format = format
		}
		if output := os.Getenv("ALBUM_LOGGER_OUTPUT"); output != "" {
			cfg.Logger.Output = output
		}
	}

	// 变更日志配置
	if cfg.Changelog != nil {
		if enabled := os.Getenv("ALBUM_CHANGELOG_ENABLED"); enabled != "" {
			cfg.Changelog.Enabled = enabled == "true" || enabled == "1"
		}
		if cleanupInterval := os.Getenv("ALBUM_CHANGELOG_CLEANUP_INTERVAL"); cleanupInterval != "" {
			if duration, err := time.ParseDuration(cleanupInterval); err == nil {
				cfg.Changelog.CleanupInterval = duration
			}
		}
		if pageLimit := os.Getenv("ALBUM_CHANGELOG_DEFAULT_PAGE_LIMIT"); pageLimit != "" {
			if pl, err := strconv.Atoi(pageLimit); err == nil {
				cfg.Changelog.DefaultChangelogPageLimit = pl
			}
		}
	}
}

// defaultConfig 返回默认配置
func (l *Loader) defaultConfig() *Config {
	return &Config{
		Server: &modules.ServerConfig{
			Host:          "0.0.0.0",
			Port:          8080,
			PublicBaseURL: "http://localhost:8080",
		},
		Database: &modules.DatabaseConfig{
			Type: "sqlite",
			DSN:  "data.db",
		},
		Storage: &modules.StorageConfig{
			Primary: &modules.PrimaryStorageConfig{
				Type: "local",
				Local: &modules.LocalStorageConfig{
					BasePath: "./uploads",
					PoolManager: &modules.PoolManagerConfig{
						DeltaChannelSize:     1024,
						DeltaBatchSize:       128,
						FlushInterval:        modules.Duration(2 * time.Second),
						CacheRefreshInterval: modules.Duration(5 * time.Minute),
						ReconcileInterval:    modules.Duration(0),
					},
				},
			},
		},
		Auth: &modules.AuthConfig{
			JWTSecret:             "change-me",
			AccessTokenExpiresIn:  modules.Duration(30 * time.Minute),
			RefreshTokenExpiresIn: modules.Duration(24 * time.Hour * 30),
			AppleAppBundleID:      "",
			AvatarSavePath:        "./public/avatars",
			MaxAvatarSize:         modules.Size(5 * 1024 * 1024),
			URLSignerSecret:       "change-me-too",
			SignedURLLoadTTL:      modules.Duration(30 * time.Minute),
		},
		Logger: &modules.LoggerConfig{
			Level:  "info",
			Format: "json",
			Output: "stdout",
		},
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

// GetEnvKey 获取环境变量键名（将配置路径转换为环境变量名）
func GetEnvKey(path string) string {
	// 将 "storage.primary.local.base_path" 转换为 "STORAGE_PRIMARY_LOCAL_BASE_PATH"
	parts := strings.Split(path, ".")
	var result []string
	for _, part := range parts {
		result = append(result, strings.ToUpper(part))
	}
	return strings.Join(result, "_")
}
