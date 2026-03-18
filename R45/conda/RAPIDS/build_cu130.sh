#!/bin/bash
# =============================================================================
# Rbio RAPIDS Docker 构建脚本
# Usage: bash docker_build.sh [options]
# =============================================================================

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="rbio-gpu"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${SCRIPT_DIR}/.test/logs/docker_build"

# 确保目录存在
mkdir -p "${LOG_DIR}"

# =============================================================================
# GitHub Token 设置（避免API限速）
# =============================================================================
setup_github_token() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 设置 GitHub Token..."

    # 优先级：环境变量 GITHUB_TOKEN > 环境变量 GITHUB_PAT > .github_token 文件
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "从环境变量 GITHUB_TOKEN 读取"
    elif [ -n "$GITHUB_PAT" ]; then
        GITHUB_TOKEN="$GITHUB_PAT"
        echo "从环境变量 GITHUB_PAT 读取"
    elif [ -f "${SCRIPT_DIR}/../.github_token" ]; then
        GITHUB_TOKEN=$(cat "${SCRIPT_DIR}/../.github_token" | tr -d '\n')
        echo "从文件 ${SCRIPT_DIR}/../.github_token 读取"
    else
        echo "警告: 未检测到 GitHub Token，将使用匿名访问（可能受限）"
        echo "请通过以下方式配置："
        echo "  方式1: export GITHUB_TOKEN=your_token"
        echo "  方式2: echo 'your_token' > .github_token"
        GITHUB_TOKEN=""
    fi

    export GITHUB_TOKEN
    export GITHUB_PAT="$GITHUB_TOKEN"

    if [ -n "$GITHUB_TOKEN" ]; then
        echo "GitHub Token 已设置，长度: ${#GITHUB_TOKEN}"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] GitHub Token 设置完成"
}

# 调用设置
cd "${SCRIPT_DIR}"
setup_github_token

# 默认参数
MIRROR="default"
HTTP_PROXY=""
HTTPS_PROXY=""
GITHUB_PROXY=""
NO_INTERACTIVE=false
SHM_SIZE="16g"
DATA_PATH="/home/$USER/data"
TEMP_PATH="/tmp/rapids"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --mirror)
            MIRROR="$2"
            shift 2
            ;;
        --http-proxy)
            HTTP_PROXY="$2"
            shift 2
            ;;
        --https-proxy)
            HTTPS_PROXY="$2"
            shift 2
            ;;
        --github-proxy)
            GITHUB_PROXY="$2"
            shift 2
            ;;
        --shm)
            SHM_SIZE="$2"
            shift 2
            ;;
        --data-path)
            DATA_PATH="$2"
            shift 2
            ;;
        --tmp-path)
            TEMP_PATH="$2"
            shift 2
            ;;
        -y|--no-interactive)
            NO_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: bash docker_build_rapids.sh [options]"
            echo ""
            echo "Options:"
            echo "  --mirror        镜像源 (china/default)"
            echo "  --http-proxy    HTTP 代理地址"
            echo "  --https-proxy   HTTPS 代理地址"
            echo "  --github-proxy  GitHub 代理地址"
            echo "  --shm           共享内存大小 (默认: 16g)"
            echo "  --data-path     数据目录路径 (默认: /home/\$USER/data)"
            echo "  --tmp-path      临时目录路径 (默认: /tmp/rapids)"
            echo "  -y, --no-interactive  跳过交互提示"
            echo ""
            echo "示例:"
            echo "  bash docker_build_rapids.sh --mirror china --shm 32g"
            echo "  bash docker_build_rapids.sh --data-path /data --tmp-path /tmp/rapids -y"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# =============================================================================
# 交互式配置
# =============================================================================

# 镜像源选择
if [[ "${NO_INTERACTIVE}" == "false" && "${MIRROR}" == "default" ]]; then
    echo ""
    echo "========================================"
    echo "  选择镜像源"
    echo "========================================"
    echo "1) 官方镜像 (默认)"
    echo "2) 国内镜像 (清华源)"
    read -p "请选择 [1/2] (默认: 1): " mirror_choice
    case "${mirror_choice}" in
        2)
            MIRROR="china"
            echo "已选择: 国内镜像"
            ;;
        *)
            MIRROR="default"
            echo "已选择: 官方镜像"
            ;;
    esac
fi

# 代理设置
if [[ -z "${HTTP_PROXY}" && "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    echo "========================================"
    echo "  代理设置 (留空表示不使用代理)"
    echo "========================================"
    read -p "HTTP 代理地址 (例如: http://127.0.0.1:7890): " HTTP_PROXY
    if [[ -n "${HTTP_PROXY}" ]]; then
        HTTPS_PROXY="${HTTP_PROXY}"
    fi
fi

# SHM_SIZE 设置
if [[ "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    echo "========================================"
    echo "  共享内存配置"
    echo "========================================"
    echo "当前 SHM_SIZE: ${SHM_SIZE}"
    read -p "修改共享内存大小 (直接回车保持默认): " input_shm
    if [[ -n "${input_shm}" ]]; then
        SHM_SIZE="${input_shm}"
    fi
fi

# 数据路径设置
if [[ "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    echo "========================================"
    echo "  数据目录配置"
    echo "========================================"
    echo "当前 DATA_PATH: ${DATA_PATH}"
    read -p "修改数据目录路径 (直接回车保持默认): " input_data
    if [[ -n "${input_data}" ]]; then
        DATA_PATH="${input_data}"
    fi
fi

# 临时路径设置
if [[ "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    echo "========================================"
    echo "  临时目录配置"
    echo "========================================"
    echo "当前 TEMP_PATH: ${TEMP_PATH}"
    read -p "修改临时目录路径 (直接回车保持默认): " input_tmp
    if [[ -n "${input_tmp}" ]]; then
        TEMP_PATH="${input_tmp}"
    fi
fi

# 显示配置摘要
echo ""
echo "========================================"
echo "  构建配置摘要"
echo "========================================"
echo "镜像源: ${MIRROR}"
echo "HTTP 代理: ${HTTP_PROXY:-无}"
echo "GitHub 代理: ${GITHUB_PROXY:-无}"
echo "共享内存: ${SHM_SIZE}"
echo "数据目录: ${DATA_PATH}"
echo "临时目录: ${TEMP_PATH}"
echo "日志目录: ${LOG_DIR}"
echo "========================================"

# 确认构建
if [[ "${NO_INTERACTIVE}" == "false" ]]; then
    read -p "确认开始构建? [Y/n]: " confirm
    if [[ "${confirm}" =~ ^[Nn]$ ]]; then
        echo "构建已取消"
        exit 0
    fi
fi

# =============================================================================
# 构建函数
# =============================================================================

# 根据 Rbio_RAPIDS.dockerfile 的实际 ARG 生成构建参数
generate_build_args() {
    local args=""

    # ARG mirror
    args="--build-arg mirror=${MIRROR}"

    # ARG APT_MIRROR (国内镜像时设置)
    if [[ "${MIRROR}" == "china" ]]; then
        args="${args} --build-arg APT_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu"
    fi

    # ARG GITHUB_TOKEN
    if [[ -n "${GITHUB_TOKEN}" ]]; then
        args="${args} --build-arg GITHUB_TOKEN=${GITHUB_TOKEN}"
    fi

    # ARG http_proxy, ARG https_proxy
    if [[ -n "${HTTP_PROXY}" ]]; then
        args="${args} --build-arg http_proxy=${HTTP_PROXY}"
        args="${args} --build-arg https_proxy=${HTTPS_PROXY:-${HTTP_PROXY}}"
    fi

    # ARG github_proxy
    if [[ -n "${GITHUB_PROXY}" ]]; then
        args="${args} --build-arg github_proxy=${GITHUB_PROXY}"
    fi

    echo "${args}"
}

build_image() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 r-bio:rapids"
    local logfile="${LOG_DIR}/Rbio_RAPIDS_${TIMESTAMP}.log"
    local build_args=$(generate_build_args)

    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"

    if ! docker build -f "${SCRIPT_DIR}/Rbio_RAPIDS_cu130.dockerfile" \
        -t rbio-gpu:cu130 \
        ${build_args} \
        "${SCRIPT_DIR}" 2>&1 | tee "${logfile}"; then
        echo "ERROR: 构建失败"
        return 1
        exit 1
    fi

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] rbio-gpu 构建成功"
    return 0
}

# =============================================================================
# 主流程
# =============================================================================

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 构建任务启动"

# 构建
if ! build_image; then
    exit 1
fi

echo ""
echo "========================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 构建任务完成"
echo "========================================"
echo ""
echo "可用镜像:"
docker images | grep "r-bio" || true
echo ""
echo "运行示例:"
echo "  docker run --gpus all --shm-size=${SHM_SIZE} \\"
echo "    -v ${DATA_PATH}:/data \\"
echo "    -v ${TEMP_PATH}:/tmp \\"
echo "    -d -p 8888:8888 rbio-gpu:cu130"
echo ""

exit 0