package config

import (
	"github.com/spf13/pflag"
)

// AddFlags 添加命令行参数到 FlagSet
func AddFlags(flags *pflag.FlagSet) {
	// 配置文件路径
	flags.StringP("config", "c", "configs/config.yaml", "配置文件路径")

	// 服务器配置
	flags.String("server.host", "", "服务器主机地址")
	flags.Int("server.port", 0, "服务器端口")
	flags.String("server.public_base_url", "", "服务器公共基础URL")

	// 数据库配置
	flags.String("database.type", "", "数据库类型")
	flags.String("database.dsn", "", "数据库连接字符串")

	// 存储配置（只添加最常用的）
	flags.String("storage.primary.type", "", "主存储类型")
	flags.String("storage.primary.local.base_path", "", "本地存储基础路径")

	// 认证配置
	flags.String("auth.jwt_secret", "", "JWT 密钥")
	flags.String("auth.access_token_expires_in", "", "访问令牌过期时间")
	flags.String("auth.refresh_token_expires_in", "", "刷新令牌过期时间")

	// 日志配置
	flags.String("logger.level", "", "日志级别")
	flags.String("logger.format", "", "日志格式")
	flags.String("logger.output", "", "日志输出")
}

