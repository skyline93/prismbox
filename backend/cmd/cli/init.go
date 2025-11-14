package main

import (
	"fmt"

	"github.com/urfave/cli/v2"

	"github.com/album/backend/internal/config"
	"github.com/album/backend/internal/database"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/service/storagepool"
)

func newInitCommand() *cli.Command {
	return &cli.Command{
		Name:  "init",
		Usage: "首次部署初始化工具（存储池等基础资源）",
		Subcommands: []*cli.Command{
			newInitStorageCommand(),
		},
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
			pool, err := service.Create(ctx, input)
			if err != nil {
				return fmt.Errorf("创建存储池失败: %w", err)
			}

			if c.Bool("json") {
				return printJSON(pool)
			}

			fmt.Printf("存储池已创建：%s (%s)\n", pool.Name, pool.UUID)
			fmt.Println("如服务尚未运行，可直接启动；如已运行，可执行 `album storage pool refresh` 让实例立即加载新配置。")
			return nil
		}),
	}
}

func loadConfigFromContext(c *cli.Context) (*config.Config, error) {
	cfgPath := c.String("config")
	loader := config.NewLoader(cfgPath)
	return loader.Load()
}
