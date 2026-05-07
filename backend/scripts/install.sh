#!/bin/sh
#
# Prismbox / Album Backend — 远程一键安装（POSIX sh，可配合 curl | sh）
#
# 用法示例:
#   curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh
#
# 可选环境变量（需在管道前导出，例如: PRISMBOX_REF=v1.0.0 curl ... | sh）:
#   PRISMBOX_GIT_HOST   默认 github.com（设 gitee.com 等可改用其他托管 raw 地址）
#   PRISMBOX_REPO       默认 skyline93/prismbox（OWNER/REPO）
#   PRISMBOX_REF        默认 main（分支或 tag）
#   PRISMBOX_INSTALL_DIR 安装目录，默认 $HOME/prismbox-backend
#
# 参数:
#   -d, --dir PATH      安装目录（同 PRISMBOX_INSTALL_DIR）
#   -r, --ref REF       Git 引用（同 PRISMBOX_REF）
#       --https         将 .env 中 ALBUM_ENABLE_HTTPS 设为 true（需自行准备证书或按文档配 certbot）
#   -y, --yes           非交互：不写弱口令提示，自动生成密钥；管理员账号沿用 .env 模板默认
#   -h, --help          帮助
#
set -e

USAGE() {
	echo "用法: curl -fsSL <install.sh-url> | sh -s -- [选项]"
	echo "选项: --dir PATH  --ref REF  --https  --yes  --help"
}

GIT_HOST="${PRISMBOX_GIT_HOST:-github.com}"
REPO_SLUG="${PRISMBOX_REPO:-skyline93/prismbox}"
GIT_REF="${PRISMBOX_REF:-main}"
INSTALL_DIR="${PRISMBOX_INSTALL_DIR:-$HOME/prismbox-backend}"
USE_HTTPS=0
NONINTERACTIVE=0

while [ "$#" -gt 0 ]; do
	case "$1" in
	-d | --dir)
		INSTALL_DIR="$2"
		shift 2
		;;
	-r | --ref)
		GIT_REF="$2"
		shift 2
		;;
	--https)
		USE_HTTPS=1
		shift
		;;
	-y | --yes)
		NONINTERACTIVE=1
		shift
		;;
	-h | --help)
		USAGE
		exit 0
		;;
	*)
		echo "未知参数: $1" >&2
		USAGE >&2
		exit 1
		;;
	esac
done

PREFIX="backend"

raw_url() {
	_path="$1"
	case "$GIT_HOST" in
	github.com)
		echo "https://raw.githubusercontent.com/${REPO_SLUG}/${GIT_REF}/${_path}"
		;;
	*)
		echo "https://${GIT_HOST}/${REPO_SLUG}/raw/${GIT_REF}/${_path}"
		;;
	esac
}

fetch() {
	_url="$1"
	_out="$2"
	echo ">> 下载 $(basename "$_out")"
	curl -fsSL "$_url" -o "$_out"
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "未找到命令: $1" >&2
		exit 1
	}
}

need_cmd curl
need_cmd docker

if docker compose version >/dev/null 2>&1; then
	DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
	DOCKER_COMPOSE="docker-compose"
else
	echo "需要 Docker Compose（docker compose 或 docker-compose）" >&2
	exit 1
fi

case "$(uname -m)" in
x86_64 | amd64)
	ALBUM_ARCH=amd64
	;;
aarch64 | arm64)
	ALBUM_ARCH=arm64
	;;
*)
	echo "不支持的架构: $(uname -m)" >&2
	exit 1
	;;
esac

echo "=========================================="
echo "Prismbox Backend 容器部署"
echo "=========================================="
echo "仓库: $GIT_HOST:$REPO_SLUG @ $GIT_REF"
echo "目录: $INSTALL_DIR"
echo "架构: $ALBUM_ARCH"
echo ""

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

fetch "$(raw_url "${PREFIX}/docker-compose.yaml")" "./docker-compose.yaml"
mkdir -p deploy
fetch "$(raw_url "${PREFIX}/deploy/init.sh")" "./deploy/init.sh"
chmod +x deploy/init.sh 2>/dev/null || true

echo ">> 初始化数据目录与 .env"
sh deploy/init.sh

# 更新或追加 KEY=value（兼容值中含特殊字符，不含换行）
env_set() {
	_key="$1"
	_val="$2"
	tmp="$(mktemp)"
	found=0
	while IFS= read -r line || [ -n "$line" ]; do
		case "$line" in
		"${_key}="*)
			echo "${_key}=${_val}"
			found=1
			;;
		*)
			echo "$line"
			;;
		esac
	done < .env > "$tmp"
	if [ "$found" -eq 0 ]; then
		echo "${_key}=${_val}" >> "$tmp"
	fi
	mv "$tmp" .env
}

# 补丁 .env：HTTPS
if [ "$USE_HTTPS" -eq 1 ]; then
	env_set ALBUM_ENABLE_HTTPS true
fi

# 生成强随机密钥与安全数据库口令（替换模板中的占位/默认）
if command -v openssl >/dev/null 2>&1; then
	JWT_HEX="$(openssl rand -hex 32)"
	SIGN_HEX="$(openssl rand -hex 32)"
	PG_PW="$(openssl rand -hex 24)"
	env_set ALBUM_AUTH_JWT_SECRET "$JWT_HEX"
	env_set ALBUM_AUTH_URL_SIGNER_SECRET "$SIGN_HEX"
	env_set ALBUM_POSTGRES_PASSWORD "$PG_PW"
else
	echo ">> 警告: 未找到 openssl，跳过随机密钥生成，请尽快手动修改 .env 中的密钥与数据库密码"
fi

# 交互：管理员邮箱与密码（非 --yes）
if [ "$NONINTERACTIVE" -ne 1 ]; then
	printf "初始化管理员邮箱 [默认保持 .env 中 ALBUM_INIT_ADMIN_EMAIL]: "
	read -r IN_EMAIL || true
	if [ -n "$IN_EMAIL" ]; then
		env_set ALBUM_INIT_ADMIN_EMAIL "$IN_EMAIL"
	fi
	printf "初始化管理员密码（留空则保持 .env 当前值）: "
	stty_orig="$(stty -g 2>/dev/null)" || stty_orig=""
	if [ -n "$stty_orig" ]; then stty -echo 2>/dev/null || true; fi
	read -r IN_PASS || true
	if [ -n "$stty_orig" ]; then stty "$stty_orig" 2>/dev/null || true; fi
	echo ""
	if [ -n "$IN_PASS" ]; then
		env_set ALBUM_INIT_ADMIN_PASSWORD "$IN_PASS"
	fi
fi

PROFILE_ARGS=""
if grep -qE '^ALBUM_ENABLE_HTTPS=(true|True|TRUE|1)' .env 2>/dev/null; then
	PROFILE_ARGS="--profile https"
	echo ">> 将使用 compose profile: https（certbot）"
fi

export ALBUM_ARCH

echo ">> 拉取镜像..."
# shellcheck disable=SC2086
$DOCKER_COMPOSE $PROFILE_ARGS pull

echo ">> 启动服务..."
# shellcheck disable=SC2086
$DOCKER_COMPOSE $PROFILE_ARGS up -d

echo ""
echo "=========================================="
echo "安装完成"
echo "=========================================="
echo "目录: $INSTALL_DIR"
HTTP_PORT=""
HTTP_PORT="$(grep -E '^ALBUM_HTTP_PORT=' .env | head -1 | cut -d= -f2- || true)"
[ -z "$HTTP_PORT" ] && HTTP_PORT="80"
echo "HTTP 端口: ${HTTP_PORT}"
echo "健康检查示例: curl -s \"http://127.0.0.1:${HTTP_PORT}/api/v1/version\""
echo "查看日志: cd \"$INSTALL_DIR\" && $DOCKER_COMPOSE $PROFILE_ARGS logs -f"
echo "停止服务: cd \"$INSTALL_DIR\" && $DOCKER_COMPOSE $PROFILE_ARGS down"
echo ""
echo "请妥善备份 .env（含数据库密码与 JWT 密钥）。"
