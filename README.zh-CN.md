# Prismbox

**Prismbox** 是一套可自托管的照片与视频管理平台。本仓库包含面向生产的 **Go 后端**（REST API、认证、媒体与相册、分享等）以及 **Flutter 移动端**。

[English README](README.md)

## 项目概览

- **后端（`backend/`）**：Go（Gin + GORM）、PostgreSQL、以 Nginx 为反向代理的容器化方案；可选使用仓库内的 **GQ（Go-Gorm-Queue）** 任务队列能力。
- **移动端（`mobile/`）**：Flutter 客户端（连接你自托管的 API）。

更多后端能力、架构与模块说明见 [`backend/README.md`](backend/README.md) 与 [`backend/doc/INDEX.md`](backend/doc/INDEX.md)。

## 仓库结构

| 路径        | 说明                                   |
| ----------- | -------------------------------------- |
| `backend/`  | API 服务、Docker/Compose 部署与运维脚本 |
| `mobile/`   | Flutter 客户端                         |
| `openspec/` | OpenSpec 与项目规格（如适用）          |

## 将后端部署到私有云 / 内网

适用于自有 VPC、机房或私有镜像仓库；栈为 **Docker + Compose**，不绑定特定云厂商。

### 环境要求

- Docker **20.10+** 与 Docker Compose **v2**（`docker compose`）
- 建议小型环境至少 **2 GB** 内存、**10 GB** 磁盘（媒体存储需按业务量单独规划）

### 方式一：远程一键安装（无需先克隆仓库）

在已安装 Docker 的机器上，在期望的安装根目录执行：

```bash
curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh
```

非交互、指定目录、启用 HTTPS Compose profile（证书与域名仍需按部署文档准备）：

```bash
curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh -s -- --dir /opt/prismbox-backend --yes --https
```

**私有 Git / 内网镜像：** 执行前可设置 `PRISMBOX_GIT_HOST`、`PRISMBOX_REPO` 等变量，从非 GitHub 源拉取 compose 与脚本（详见 `backend/scripts/install.sh` 头部注释）。生产环境建议用 `PRISMBOX_REF` 固定 tag，保证可复现部署。

### 方式二：克隆仓库后部署

```bash
git clone https://github.com/skyline93/prismbox.git
cd prismbox/backend
./deploy.sh
```

也可使用 `make deploy` 等命令，完整说明见 **[部署文档](backend/doc/DEPLOYMENT/README.md)**。

### 延伸阅读

- 运维、HTTPS、环境变量、升级与排错：**[backend/doc/DEPLOYMENT/README.md](backend/doc/DEPLOYMENT/README.md)**
- 架构：**[backend/doc/ARCHITECTURE/README.md](backend/doc/ARCHITECTURE/README.md)**

## 移动端

将应用配置为访问你后端的公网或 VPN 地址。开发入门见 [`mobile/README.md`](mobile/README.md)。

## 参与贡献

欢迎 Issue 与 PR。较大变更请先查看 `openspec/` 与 [`AGENTS.md`](AGENTS.md) 的约定。

## 许可证

[MIT 许可证](LICENSE)
