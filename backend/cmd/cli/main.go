package main

import (
	"errors"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/urfave/cli/v2"

	"github.com/album/backend/internal/version"
)

const (
	modeAuto   = "auto"
	modeLocal  = "local"
	modeRemote = "remote"
)

// commandProfile 描述命令对运行模式的要求。
type commandProfile struct {
	requiresLocal  bool
	requiresRemote bool
}

func main() {
	app := &cli.App{
		Name:            "album",
		Usage:           "Album Backend 命令行工具",
		HideVersion:     true,
		HideHelpCommand: true,
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:    "config",
				Aliases: []string{"c"},
				Value:   "configs/config.yaml",
				Usage:   "配置文件路径",
			},
			&cli.StringFlag{
				Name:  "env-prefix",
				Value: "ALBUM_",
				Usage: "配置环境变量前缀",
			},
			&cli.StringFlag{
				Name:  "mode",
				Value: modeAuto,
				Usage: "运行模式，可选值: auto|local|remote",
			},
			&cli.StringFlag{
				Name:  "socket-path",
				Usage: "远程模式下的 Unix Socket 路径",
			},
			&cli.StringFlag{
				Name:  "base-url",
				Usage: "远程模式下的 HTTP BaseURL",
			},
		},
		Before: func(c *cli.Context) error {
			mode := normalizeMode(c.String("mode"))
			if mode == "" {
				return fmt.Errorf("无效的运行模式: %s", c.String("mode"))
			}
			// 将处理后的模式写回，保证后续访问一致。
			if err := c.Set("mode", mode); err != nil {
				return err
			}
			return nil
		},
		Commands: []*cli.Command{
			newVersionCommand(),
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatalf("album cli: %v", err)
	}
}

func newVersionCommand() *cli.Command {
	profile := commandProfile{
		requiresLocal: true,
	}

	return &cli.Command{
		Name:  "version",
		Usage: "输出版本信息（本地读取 internal/version 包）",
		Flags: []cli.Flag{
			&cli.BoolFlag{
				Name:  "json",
				Usage: "以 JSON 格式输出",
			},
		},
		Action: enforceProfile(profile, func(c *cli.Context) error {
			info := version.Get()
			if c.Bool("json") {
				data, err := version.MarshalJSON()
				if err != nil {
					return fmt.Errorf("序列化版本信息失败: %w", err)
				}
				fmt.Println(string(data))
				return nil
			}

			fmt.Printf("Version:   %s\n", info.Version)
			fmt.Printf("BuildTime: %s\n", info.BuildTime)
			fmt.Printf("GitCommit: %s\n", info.GitCommit)
			fmt.Printf("GitBranch: %s\n", info.GitBranch)
			fmt.Printf("GoVersion: %s\n", info.GoVersion)
			fmt.Printf("Platform:  %s\n", info.Platform)
			return nil
		}),
	}
}

func enforceProfile(profile commandProfile, action cli.ActionFunc) cli.ActionFunc {
	return func(c *cli.Context) error {
		mode := c.String("mode")

		if profile.requiresLocal && mode == modeRemote {
			return errors.New("当前命令仅支持本地模式，请使用 --mode=local 或 --mode=auto")
		}

		if profile.requiresRemote && mode == modeLocal {
			return errors.New("当前命令仅支持远程模式，请使用 --mode=remote 或 --mode=auto")
		}

		return action(c)
	}
}

func normalizeMode(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case modeAuto:
		return modeAuto
	case modeLocal:
		return modeLocal
	case modeRemote:
		return modeRemote
	default:
		return ""
	}
}
