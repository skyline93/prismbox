package logger

// Config 日志配置结构
type Config struct {
	// 基础配置
	Level  string // "debug", "info", "warn", "error"
	Format string // "json", "console"
	Output string // "stdout", "stderr", "/path/to/file.log"

	// 功能开关
	EnableCaller bool // 是否包含调用位置（文件名:行号）
	EnableStack  bool // 是否包含堆栈信息（Error 级别）

	// 性能配置
	Async      bool // 是否异步写入
	BufferSize int  // 异步缓冲大小（默认 1000）

	// 文件输出配置（Output 为文件路径时生效）
	FileConfig *FileConfig
}

// FileConfig 文件输出配置
type FileConfig struct {
	Path       string // 日志文件路径
	MaxSize    int64  // 单个文件最大大小（字节）
	MaxAge     int    // 保留天数
	MaxBackups int    // 保留文件数量
	Compress   bool   // 是否压缩旧文件
}
