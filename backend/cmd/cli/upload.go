package main

import (
	"fmt"
	"time"

	"github.com/urfave/cli/v2"

	climedia "github.com/album/backend/internal/cli/media"
)

func newUploadCommand() *cli.Command {
	profile := commandProfile{
		requiresRemote: true,
	}

	flags := []cli.Flag{
		&cli.StringFlag{
			Name:  "file",
			Usage: "上传单个媒体文件路径",
		},
		&cli.StringFlag{
			Name:  "dir",
			Usage: "批量上传目录，递归扫描媒体文件",
		},
		&cli.StringFlag{
			Name:  "manifest",
			Usage: "批量上传清单（JSON/YAML），与 --dir 互斥",
		},
		&cli.IntFlag{
			Name:  "concurrency",
			Usage: "批量上传并发数（仅在 --dir 或 --manifest 时生效）",
			Value: 4,
		},
		&cli.StringFlag{
			Name:  "on-error",
			Usage: "批量上传遇到错误时的处理：skip（默认）或 stop",
			Value: "skip",
		},
		&cli.BoolFlag{
			Name:  "json",
			Usage: "以 JSON 输出上传结果",
		},
		&cli.BoolFlag{
			Name:  "quiet",
			Usage: "安静模式，不展示进度条",
		},
		&cli.BoolFlag{
			Name:  "dry-run",
			Usage: "仅校验任务，不实际上传",
		},
		&cli.StringFlag{
			Name:     "email",
			Usage:    "登录邮箱",
			EnvVars:  []string{"ALBUM_CLI_EMAIL"},
			Required: true,
		},
		&cli.StringFlag{
			Name:     "password",
			Usage:    "登录密码（建议通过环境变量 ALBUM_CLI_PASSWORD 提供）",
			EnvVars:  []string{"ALBUM_CLI_PASSWORD"},
			Required: true,
		},
		&cli.DurationFlag{
			Name:  "timeout",
			Usage: "接口超时时间",
			Value: 2 * time.Minute,
		},
	}

	return &cli.Command{
		Name:  "upload",
		Usage: "上传媒体文件（支持单个文件或批量模式）",
		Flags: flags,
		Action: enforceProfile(profile, func(c *cli.Context) error {
			file := c.String("file")
			dir := c.String("dir")
			manifest := c.String("manifest")

			pathsProvided := 0
			if file != "" {
				pathsProvided++
			}
			if dir != "" {
				pathsProvided++
			}
			if manifest != "" {
				pathsProvided++
			}

			if pathsProvided == 0 {
				return fmt.Errorf("请使用 --file、--dir 或 --manifest 指定上传源")
			}
			if pathsProvided > 1 {
				return fmt.Errorf("--file、--dir、--manifest 互斥，请仅指定其中一个")
			}

			common := climedia.CommonOptions{
				BaseURL:    c.String("base-url"),
				SocketPath: c.String("socket-path"),
				Email:      c.String("email"),
				Password:   c.String("password"),
				Timeout:    c.Duration("timeout"),
				JSONOutput: c.Bool("json"),
				Quiet:      c.Bool("quiet"),
				DryRun:     c.Bool("dry-run"),
			}

			if file != "" {
				opts := climedia.FileUploadOptions{
					CommonOptions: common,
					FilePath:      file,
				}
				return climedia.RunFileUpload(c.Context, opts)
			}

			onError := c.String("on-error")
			if onError != "skip" && onError != "stop" {
				return fmt.Errorf("--on-error 仅支持 skip 或 stop")
			}

			concurrency := c.Int("concurrency")
			if concurrency <= 0 {
				return fmt.Errorf("--concurrency 必须大于 0")
			}

			opts := climedia.BatchUploadOptions{
				CommonOptions: common,
				Dir:           dir,
				ManifestPath:  manifest,
				Concurrency:   concurrency,
				OnError:       onError,
			}
			return climedia.RunBatchUpload(c.Context, opts)
		}),
	}
}
