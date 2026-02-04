package main

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/urfave/cli/v2"
	"gorm.io/gorm"

	"github.com/album/backend/internal/config"
	"github.com/album/backend/internal/database"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/service/storagepool"
)

func newInitCommand() *cli.Command {
	return &cli.Command{
		Name:  "init",
		Usage: "首次部署初始化工具（存储池等基础资源）",
		Subcommands: []*cli.Command{
			newInitConfigCommand(),
			newInitMigrateCommand(),
			newInitStorageCommand(),
			newInitAdminCommand(),
		},
	}
}

func newInitConfigCommand() *cli.Command {
	profile := commandProfile{requiresLocal: true}

	return &cli.Command{
		Name:  "config",
		Usage: "根据默认模板生成配置文件（本地模式）",
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:  "force",
				Usage: "若配置已存在则覆盖",
			},
			&cli.StringFlag{
				Name:  "db-type",
				Usage: "数据库类型（sqlite/postgres）",
			},
			&cli.StringFlag{
				Name:  "database-dsn",
				Usage: "数据库 DSN",
			},
			&cli.StringFlag{
				Name:  "server-host",
				Usage: "Server 监听地址",
			},
			&cli.IntFlag{
				Name:  "server-port",
				Usage: "Server 监听端口",
			},
			&cli.StringFlag{
				Name:  "public-base-url",
				Usage: "对外访问地址",
			},
			&cli.StringFlag{
				Name:  "storage-path",
				Usage: "主存储路径（local.base_path）",
			},
			&cli.StringFlag{
				Name:  "temp-path",
				Usage: "临时文件路径（storage.primary.local.temp.base_path）",
			},
			&cli.StringFlag{
				Name:  "jwt-secret",
				Usage: "JWT 密钥（未提供则自动生成）",
			},
			&cli.StringFlag{
				Name:  "url-signer-secret",
				Usage: "URL 签名密钥（未提供则自动生成）",
			},
			&cli.BoolFlag{
				Name:  "json",
				Usage: "JSON 格式输出结果",
			},
		},
		Action: enforceProfile(profile, func(c *cli.Context) error {
			cfgPath := c.String("config")
			if _, err := os.Stat(cfgPath); err == nil && !c.Bool("force") {
				return fmt.Errorf("检测到配置文件已存在：%s，如需覆盖请使用 --force", cfgPath)
			}

			loader := config.NewLoader(cfgPath)
			cfg, err := loader.Load(nil)
			if err != nil {
				return fmt.Errorf("加载默认配置失败: %w", err)
			}

			if err := applyInitConfigOverrides(cfg, c); err != nil {
				return err
			}
			if err := ensureConfigSecrets(cfg); err != nil {
				return err
			}

			if err := loader.Save(cfg); err != nil {
				return fmt.Errorf("写入配置失败: %w", err)
			}

			if c.Bool("json") {
				return printJSON(map[string]interface{}{
					"path": cfgPath,
				})
			}

			fmt.Printf("配置文件已写入：%s\n", cfgPath)
			return nil
		}),
	}
}

func newInitStorageCommand() *cli.Command {
	profile := commandProfile{requiresLocal: true}

	flags := []cli.Flag{
		&cli.BoolFlag{
			Name:  "json",
			Usage: "JSON 格式输出",
		},
		&cli.StringFlag{
			Name:  "name",
			Usage: "存储池名称",
			Value: "default-local",
		},
		&cli.StringFlag{
			Name:  "type",
			Usage: "存储类型（默认 local）",
			Value: "local",
		},
		&cli.StringFlag{
			Name:  "local-path",
			Usage: "本地路径（type=local 时必填）",
			Value: "./uploads",
		},
		&cli.StringFlag{
			Name:  "max-size",
			Usage: "最大容量（如 500GB、1TB）",
			Value: "1TB",
		},
		&cli.IntFlag{
			Name:  "priority",
			Usage: "优先级（越小越优先）",
			Value: 1,
		},
		&cli.Float64Flag{
			Name:  "auto-disable-threshold",
			Usage: "自动禁用阈值（0-1）",
			Value: 0.9,
		},
		&cli.StringFlag{
			Name:  "description",
			Usage: "描述信息",
			Value: "initial storage pool",
		},
		&cli.BoolFlag{
			Name:  "force",
			Usage: "即使已有存储池也继续执行",
		},
	}

	return &cli.Command{
		Name:  "storage",
		Usage: "初始化主存储（首次部署，无需服务运行）",
		Flags: flags,
		Action: enforceProfile(profile, func(c *cli.Context) error {
			ctx := c.Context

			cfg, err := loadConfigFromContext(c)
			if err != nil {
				return fmt.Errorf("加载配置失败: %w", err)
			}

			db, err := database.NewConnection(cfg.Database)
			if err != nil {
				return fmt.Errorf("连接数据库失败: %w", err)
			}

			repo := repository.NewStoragePoolRepository(db)
			existing, err := repo.List(ctx, repository.StoragePoolFilter{})
			if err != nil {
				return fmt.Errorf("查询存储池失败: %w", err)
			}
			if len(existing) > 0 && !c.Bool("force") {
				return fmt.Errorf("检测到已有 %d 个存储池，若仍需初始化请使用 --force", len(existing))
			}

			size, err := parseSizeString(c.String("max-size"))
			if err != nil {
				return err
			}

			input := &storagepool.CreateInput{
				Name:                 c.String("name"),
				StorageType:          c.String("type"),
				LocalPath:            c.String("local-path"),
				MaxSize:              size,
				Priority:             c.Int("priority"),
				Enabled:              true,
				AutoDisableThreshold: c.Float64("auto-disable-threshold"),
				Description:          c.String("description"),
			}
			service := storagepool.NewService(repo, nil)
			result, err := service.Create(ctx, input)
			if err != nil {
				return fmt.Errorf("创建存储池失败: %w", err)
			}

			if c.Bool("json") {
				return printJSON(result)
			}

			fmt.Printf("存储池已创建：%s (%s)\n", result.Pool.Name, result.Pool.UUID)

			// Display refresh status
			if result.RefreshInfo != nil {
				if result.RefreshInfo.Success {
					fmt.Printf("✓ 存储池缓存已自动刷新：%s\n", result.RefreshInfo.Message)
					if result.RefreshInfo.TaskID != "" {
						fmt.Printf("  任务 ID: %s\n", result.RefreshInfo.TaskID)
					}
				} else {
					fmt.Printf("⚠ 自动刷新失败：%s\n", result.RefreshInfo.Error)
					fmt.Println("  如服务尚未运行，可直接启动；如已运行，可执行 `album storage pool refresh` 让实例立即加载新配置。")
				}
			} else {
				fmt.Println("如服务尚未运行，可直接启动；如已运行，可执行 `album storage pool refresh` 让实例立即加载新配置。")
			}

			return nil
		}),
	}
}

func newInitAdminCommand() *cli.Command {
	profile := commandProfile{requiresLocal: true}

	flags := []cli.Flag{
		&cli.StringFlag{
			Name:     "email",
			Usage:    "管理员邮箱",
			EnvVars:  []string{"ALBUM_INIT_ADMIN_EMAIL"},
			Required: true,
		},
		&cli.StringFlag{
			Name:     "password",
			Usage:    "管理员密码（建议通过环境变量 ALBUM_INIT_ADMIN_PASSWORD 提供）",
			EnvVars:  []string{"ALBUM_INIT_ADMIN_PASSWORD"},
			Required: true,
		},
		&cli.StringFlag{
			Name:  "username",
			Usage: "管理员用户名（默认取邮箱前缀）",
		},
		&cli.BoolFlag{
			Name:  "reset-password",
			Usage: "当用户已存在时，仅重置密码并保持其他字段",
		},
		&cli.BoolFlag{
			Name:  "json",
			Usage: "JSON 格式输出",
		},
	}

	return &cli.Command{
		Name:  "admin",
		Usage: "创建或更新管理员账户（本地模式，直接访问数据库）",
		Flags: flags,
		Action: enforceProfile(profile, func(c *cli.Context) error {
			ctx := c.Context
			cfg, err := loadConfigFromContext(c)
			if err != nil {
				return fmt.Errorf("加载配置失败: %w", err)
			}

			db, err := database.NewConnection(cfg.Database)
			if err != nil {
				return fmt.Errorf("连接数据库失败: %w", err)
			}

			email := strings.ToLower(strings.TrimSpace(c.String("email")))
			if email == "" {
				return fmt.Errorf("邮箱不能为空")
			}
			username := strings.TrimSpace(c.String("username"))
			if username == "" {
				username = inferUsernameFromEmail(email)
			}

			password := c.String("password")
			if len(password) < 8 {
				return fmt.Errorf("密码长度至少 8 位")
			}

			userRepo := repository.NewUserRepository(db)
			user, err := userRepo.FindByEmail(ctx, email)
			if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
				return fmt.Errorf("查询用户失败: %w", err)
			}

			hashedPassword, err := auth.HashPassword(password)
			if err != nil {
				return fmt.Errorf("密码加密失败: %w", err)
			}

			var result *models.User
			if user != nil {
				if !c.Bool("reset-password") {
					return fmt.Errorf("检测到用户 %s 已存在，如需重置密码请加上 --reset-password", email)
				}
				if err := userRepo.UpdatePassword(ctx, user.ID, hashedPassword); err != nil {
					return fmt.Errorf("重置密码失败: %w", err)
				}
				if username != "" && username != user.Username {
					if err := db.WithContext(ctx).
						Model(&models.User{}).
						Where("id = ?", user.ID).
						Update("username", username).Error; err != nil {
						return fmt.Errorf("更新用户名失败: %w", err)
					}
					user.Username = username
				}
				user.Password = ""
				result = user
			} else {
				newUser := &models.User{
					Email:    email,
					Username: username,
					Password: hashedPassword,
				}
				if err := userRepo.Create(ctx, newUser); err != nil {
					return fmt.Errorf("创建用户失败: %w", err)
				}
				newUser.Password = ""
				result = newUser
			}

			if c.Bool("json") {
				return printJSON(result)
			}

			fmt.Printf("管理员账户已就绪：%s\n", result.Email)
			return nil
		}),
	}
}

func newInitMigrateCommand() *cli.Command {
	profile := commandProfile{requiresLocal: true}

	return &cli.Command{
		Name:  "migrate",
		Usage: "执行数据库自动迁移（本地模式）",
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:  "json",
				Usage: "JSON 格式输出",
			},
		},
		Action: enforceProfile(profile, func(c *cli.Context) error {
			cfg, err := loadConfigFromContext(c)
			if err != nil {
				return fmt.Errorf("加载配置失败: %w", err)
			}

			db, err := database.NewConnection(cfg.Database)
			if err != nil {
				return fmt.Errorf("连接数据库失败: %w", err)
			}

			if err := database.RunAutoMigrations(db); err != nil {
				return fmt.Errorf("数据库迁移失败: %w", err)
			}

			if c.Bool("json") {
				return printJSON(map[string]string{"status": "migrated"})
			}

			fmt.Println("数据库迁移完成。")
			return nil
		}),
	}
}

func loadConfigFromContext(c *cli.Context) (*config.Config, error) {
	cfgPath := c.String("config")
	loader := config.NewLoader(cfgPath)
	return loader.Load(nil)
}

func applyInitConfigOverrides(cfg *config.Config, c *cli.Context) error {
	if cfg.Database != nil {
		if dbType := strings.TrimSpace(c.String("db-type")); dbType != "" {
			cfg.Database.Type = dbType
		}
		if dsn := strings.TrimSpace(c.String("database-dsn")); dsn != "" {
			cfg.Database.DSN = dsn
		}
	}

	if cfg.Server != nil {
		if host := strings.TrimSpace(c.String("server-host")); host != "" {
			cfg.Server.Host = host
		}
		if c.IsSet("server-port") {
			cfg.Server.Port = c.Int("server-port")
		}
		if url := strings.TrimSpace(c.String("public-base-url")); url != "" {
			cfg.Server.PublicBaseURL = url
		}
	}

	if cfg.Storage != nil && cfg.Storage.Primary != nil && cfg.Storage.Primary.Local != nil {
		if path := strings.TrimSpace(c.String("storage-path")); path != "" {
			cfg.Storage.Primary.Local.BasePath = path
		}
		if cfg.Storage.Primary.Local.Temp != nil {
			if temp := strings.TrimSpace(c.String("temp-path")); temp != "" {
				cfg.Storage.Primary.Local.Temp.BasePath = temp
			}
		}
	}

	if cfg.Auth != nil {
		if secret := strings.TrimSpace(c.String("jwt-secret")); secret != "" {
			cfg.Auth.JWTSecret = secret
		}
		if signer := strings.TrimSpace(c.String("url-signer-secret")); signer != "" {
			cfg.Auth.URLSignerSecret = signer
		}
	}

	return nil
}

func ensureConfigSecrets(cfg *config.Config) error {
	if cfg.Auth == nil {
		return nil
	}

	if cfg.Auth.JWTSecret == "" || cfg.Auth.JWTSecret == "change-me" {
		secret, err := generateRandomSecret()
		if err != nil {
			return err
		}
		cfg.Auth.JWTSecret = secret
	}

	if cfg.Auth.URLSignerSecret == "" || cfg.Auth.URLSignerSecret == "change-me-too" {
		secret, err := generateRandomSecret()
		if err != nil {
			return err
		}
		cfg.Auth.URLSignerSecret = secret
	}

	return nil
}

func generateRandomSecret() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("生成随机密钥失败: %w", err)
	}
	return hex.EncodeToString(buf), nil
}

func inferUsernameFromEmail(email string) string {
	beforeAt := email
	if idx := strings.Index(email, "@"); idx > 0 {
		beforeAt = email[:idx]
	}
	beforeAt = strings.TrimSpace(beforeAt)
	if beforeAt == "" {
		return "admin"
	}
	return beforeAt
}
