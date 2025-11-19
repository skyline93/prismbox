package database

// Config 数据库配置
type Config struct {
	Type string `yaml:"type"` // "sqlite", "postgres"
	DSN  string `yaml:"dsn"`  // 数据库连接字符串
}
