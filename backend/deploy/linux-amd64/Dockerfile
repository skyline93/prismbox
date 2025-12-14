FROM registry.cn-shenzhen.aliyuncs.com/greene/album-base:linux-amd64-latest AS builder

WORKDIR /app

# 构建参数（版本信息）
ARG VERSION=dev
ARG BUILD_TIME
ARG GIT_COMMIT
ARG GIT_BRANCH

# 设置 ImageMagick 环境变量用于 CGO 编译
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV CGO_CFLAGS="-I/usr/local/include/ImageMagick-7"
ENV CGO_LDFLAGS="-L/usr/local/lib -lMagickWand-7.Q16HDRI -lMagickCore-7.Q16HDRI"

# 复制源代码
COPY ./internal ./internal
COPY ./pkg ./pkg
COPY ./cmd ./cmd
COPY ./docs ./docs
COPY ./go.mod ./go.sum ./

# 构建应用（server 和 cli）并注入版本信息
RUN BUILD_TIME_VAL=$([ -z "$BUILD_TIME" ] && date -u +"%Y-%m-%dT%H:%M:%SZ" || echo "$BUILD_TIME") && \
    GIT_COMMIT_VAL=$([ -z "$GIT_COMMIT" ] && echo "unknown" || echo "$GIT_COMMIT") && \
    GIT_BRANCH_VAL=$([ -z "$GIT_BRANCH" ] && echo "unknown" || echo "$GIT_BRANCH") && \
    VERSION_VAL=${VERSION:-dev} && \
    LDFLAGS="-X 'github.com/album/backend/internal/version.Version=${VERSION_VAL}' \
             -X 'github.com/album/backend/internal/version.BuildTime=${BUILD_TIME_VAL}' \
             -X 'github.com/album/backend/internal/version.GitCommit=${GIT_COMMIT_VAL}' \
             -X 'github.com/album/backend/internal/version.GitBranch=${GIT_BRANCH_VAL}' \
             -s -w" && \
    echo "Building with version: ${VERSION_VAL}, commit: ${GIT_COMMIT_VAL}, branch: ${GIT_BRANCH_VAL}" && \
    go mod download && \
    CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -ldflags="${LDFLAGS}" -buildvcs=false -o album-server ./cmd/server && \
    CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -ldflags="${LDFLAGS}" -buildvcs=false -o album-cli ./cmd/cli

# 运行阶段
FROM registry.cn-shenzhen.aliyuncs.com/greene/album-base:linux-amd64-latest

USER root
WORKDIR /app

# 复制二进制文件（server 和 cli）
COPY --from=builder /app/album-server .
COPY --from=builder /app/album-cli .

# 复制初始化脚本
COPY ./scripts/init-container.sh /app/init-container.sh

# 创建必要的目录
RUN mkdir -p /app/data /app/configs /app/public && \
    chmod +x /app/album-server /app/album-cli /app/init-container.sh && \
    chown -R app:app /app

USER app

EXPOSE 8080

# 使用启动脚本（会先执行初始化，再启动服务）
COPY ./deploy/docker-entrypoint-backend.sh /app/docker-entrypoint-backend.sh
USER root
RUN chmod +x /app/docker-entrypoint-backend.sh
USER app

ENTRYPOINT ["/app/docker-entrypoint-backend.sh"]
CMD ["./album-server"]
