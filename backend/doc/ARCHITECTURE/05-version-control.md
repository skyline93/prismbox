# 5. 版本控制系统

## 5.1 版本信息结构

版本信息包括：
- **Version**：版本号（如 v1.0.0）
- **BuildTime**：构建时间
- **GitCommit**：Git 提交哈希
- **GitBranch**：Git 分支
- **GoVersion**：Go 版本
- **Platform**：构建平台

## 5.2 版本注入方式

使用 Go 的 `ldflags` 在编译时注入版本信息：

```makefile
LDFLAGS := -X 'github.com/album/backend/internal/version.Version=$(VERSION)' \
           -X 'github.com/album/backend/internal/version.BuildTime=$(BUILD_TIME)' \
           -X 'github.com/album/backend/internal/version.GitCommit=$(GIT_COMMIT)' \
           -X 'github.com/album/backend/internal/version.GitBranch=$(GIT_BRANCH)'

go build -ldflags "$(LDFLAGS)" -o bin/server ./cmd/server
```

## 5.3 版本查询方式

### 5.3.1 命令行工具

```bash
# 查看版本信息
./bin/cli version

# JSON 格式输出
./bin/cli version --json
```

### 5.3.2 API 端点

```bash
# HTTP 请求
curl http://localhost:8080/api/v1/version
```

## 5.4 版本文件

`internal/version/version.go` 定义版本信息结构，通过包级变量存储版本信息（编译时注入）。

