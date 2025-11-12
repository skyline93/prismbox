package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"time"

	"github.com/urfave/cli/v2"

	"github.com/album/backend/internal/cli/remote"
)

func newMediaCommand() *cli.Command {
	return &cli.Command{
		Name:  "media",
		Usage: "媒体运维命令（列表、查询、下载等）",
		Subcommands: []*cli.Command{
			newMediaListCommand(),
			newMediaInfoCommand(),
			newMediaDownloadCommand(),
		},
	}
}

func newMediaListCommand() *cli.Command {
	profile := commandProfile{
		requiresRemote: true,
	}

	return &cli.Command{
		Name:  "list",
		Usage: "列出媒体资源（开发中）",
		Action: enforceProfile(profile, func(c *cli.Context) error {
			return cli.Exit("媒体列表功能尚未实现，敬请期待。", 1)
		}),
	}
}

func newMediaInfoCommand() *cli.Command {
	profile := commandProfile{
		requiresRemote: true,
	}

	return &cli.Command{
		Name:  "info",
		Usage: "查看媒体详情（开发中）",
		Action: enforceProfile(profile, func(c *cli.Context) error {
			return cli.Exit("媒体详情功能尚未实现，敬请期待。", 1)
		}),
	}
}

func newMediaDownloadCommand() *cli.Command {
	profile := commandProfile{
		requiresRemote: true,
	}

	flags := []cli.Flag{
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
		&cli.StringFlag{
			Name:  "output",
			Usage: "输出文件路径",
		},
		&cli.BoolFlag{
			Name:  "stdout",
			Usage: "输出到标准输出",
		},
		&cli.BoolFlag{
			Name:  "json",
			Usage: "以 JSON 格式输出结果",
		},
		&cli.DurationFlag{
			Name:  "timeout",
			Usage: "接口超时时间",
			Value: 5 * time.Minute,
		},
	}

	return &cli.Command{
		Name:  "download",
		Usage: "下载媒体文件（原图、预览图、缩略图）",
		Subcommands: []*cli.Command{
			{
				Name:      "original",
				Usage:     "下载原始文件",
				Flags:     flags,
				ArgsUsage: "<uuid>",
				Action: enforceProfile(profile, func(c *cli.Context) error {
					return runDownload(c, "original")
				}),
			},
			{
				Name:      "preview",
				Usage:     "下载预览文件",
				Flags:     flags,
				ArgsUsage: "<uuid>",
				Action: enforceProfile(profile, func(c *cli.Context) error {
					return runDownload(c, "preview")
				}),
			},
			{
				Name:      "thumbnail",
				Usage:     "下载缩略图",
				Flags:     flags,
				ArgsUsage: "<uuid>",
				Action: enforceProfile(profile, func(c *cli.Context) error {
					return runDownload(c, "thumbnail")
				}),
			},
		},
	}
}

func runDownload(c *cli.Context, downloadType string) error {
	uuid := c.Args().First()
	if uuid == "" {
		return fmt.Errorf("请提供媒体 UUID")
	}

	// 创建远程客户端
	client, err := remote.NewClient(remote.Config{
		BaseURL:    c.String("base-url"),
		SocketPath: c.String("socket-path"),
		Timeout:    c.Duration("timeout"),
	})
	if err != nil {
		return fmt.Errorf("创建远程客户端失败: %w", err)
	}

	// 登录认证
	ctx := c.Context
	if err := client.LoginWithPassword(ctx, c.String("email"), c.String("password")); err != nil {
		return fmt.Errorf("登录失败: %w", err)
	}

	// 确定输出目标
	var output io.Writer
	outputPath := c.String("output")
	stdout := c.Bool("stdout")

	if outputPath != "" && stdout {
		return fmt.Errorf("--output 和 --stdout 不能同时指定")
	}
	if outputPath == "" && !stdout {
		return fmt.Errorf("请指定 --output 或 --stdout 之一")
	}

	if outputPath != "" {
		file, err := os.Create(outputPath)
		if err != nil {
			return fmt.Errorf("创建输出文件失败: %w", err)
		}
		defer file.Close()
		output = file
	} else {
		output = os.Stdout
	}

	// 执行下载
	var downloadErr error
	switch downloadType {
	case "original":
		downloadErr = client.DownloadOriginal(ctx, uuid, output)
	case "preview":
		downloadErr = client.DownloadPreview(ctx, uuid, output)
	case "thumbnail":
		downloadErr = client.DownloadThumbnail(ctx, uuid, output)
	default:
		return fmt.Errorf("未知的下载类型: %s", downloadType)
	}

	if downloadErr != nil {
		return downloadErr
	}

	// 如果指定了 JSON 输出且输出到文件，输出元数据
	if c.Bool("json") && outputPath != "" {
		result := map[string]interface{}{
			"uuid":        uuid,
			"type":        downloadType,
			"output_path": outputPath,
			"status":      "success",
		}
		data, err := json.Marshal(result)
		if err != nil {
			return fmt.Errorf("序列化结果失败: %w", err)
		}
		fmt.Fprintln(os.Stderr, string(data))
	} else if c.Bool("json") {
		// 如果输出到标准输出，JSON 输出会与文件内容混合，所以只在 stderr 输出
		result := map[string]interface{}{
			"uuid":   uuid,
			"type":   downloadType,
			"status": "success",
		}
		data, err := json.Marshal(result)
		if err != nil {
			return fmt.Errorf("序列化结果失败: %w", err)
		}
		fmt.Fprintln(os.Stderr, string(data))
	}

	return nil
}
