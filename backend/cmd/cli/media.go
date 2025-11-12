package main

import (
	"github.com/urfave/cli/v2"
)

func newMediaCommand() *cli.Command {
	return &cli.Command{
		Name:  "media",
		Usage: "媒体运维命令（列表、查询等）",
		Subcommands: []*cli.Command{
			newMediaListCommand(),
			newMediaInfoCommand(),
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
