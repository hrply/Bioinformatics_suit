#!/bin/bash
# =============================================================================
# Rbio_common.sh - 公共函数库
# =============================================================================
# 用途：为其他 Rbio 脚本传递环境变量和通用函数
# 注意：不修改任何系统配置文件
# =============================================================================

#========================================
# 配置变量
#========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../.test/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ENV_NAME="${CONDA_DEFAULT_ENV:-bio5}"
CONDA_ENV_NAME="${CONDA_DEFAULT_ENV:-bio5}"
LOG_FILE="${LOG_DIR}/${ENV_NAME}_stage_${TIMESTAMP}.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 安装选项
USE_CHINA_MIRROR=false
SUDO_PASSWORD=""
SUDO=""

# 镜像源配置
CRAN_MIRROR=""
BIOCONDUCTOR_MIRROR=""
PIP_INDEX_URL=""
PIP_TRUSTED_HOST=""
GITHUB_PROXY=""

# R 和 Bioconductor 版本
R_VERSION="4.5.2"
BIOC_VERSION="3.22"

#========================================
# 日志函数
#========================================
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "$1"
    echo "[$timestamp] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() { log "${GREEN}[INFO]${NC} $1"; }
log_warn() { log "${YELLOW}[WARN]${NC} $1"; }
log_error() { log "${RED}[ERROR]${NC} $1"; }
log_stage() { log "${CYAN}========================================\n$1\n========================================${NC}"; }
log_stage_complete() {
    log "${GREEN}========================================${NC}"
    log "${GREEN}[STAGE COMPLETE] $1${NC}"
    log "${GREEN}========================================${NC}"
}

#========================================
# 权限检查
#========================================
setup_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if [ -n "$SUDO_PASSWORD" ]; then
            echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null || {
                log_error "sudo 密码验证失败"
                exit 1
            }
            SUDO="sudo"
            log_info "sudo 凭据已验证"
        else
            SUDO="sudo"
        fi
    else
        SUDO=""
    fi
}

#========================================
# 镜像源设置
#========================================
setup_china_mirrors() {
    log_info "配置国内镜像源（清华源）..."

    CRAN_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"
    BIOCONDUCTOR_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/bioconductor"
    PIP_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
    PIP_TRUSTED_HOST="mirrors.tuna.tsinghua.edu.cn"

    # 导出环境变量供 R 脚本使用
    export CRAN_MIRROR
    export BIOCONDUCTOR_MIRROR

    # 设置代理
    GITHUB_PROXY="${GITHUB_PROXY:-${github_proxy:-http://192.168.3.147:7890}}"
    if [ -n "$GITHUB_PROXY" ]; then
        export http_proxy="$GITHUB_PROXY"
        export https_proxy="$GITHUB_PROXY"
        export HTTP_PROXY="$GITHUB_PROXY"
        export HTTPS_PROXY="$GITHUB_PROXY"
        export no_proxy="localhost,127.0.0.1,mirrors.tuna.tsinghua.edu.cn"
        log_info "代理: $GITHUB_PROXY"
    fi

    log_info "镜像源配置完成"
}

setup_default_mirrors() {
    log_info "使用默认镜像源..."

    CRAN_MIRROR="https://cloud.r-project.org"
    BIOCONDUCTOR_MIRROR="https://bioconductor.org"
    PIP_INDEX_URL=""
    PIP_TRUSTED_HOST=""

    export CRAN_MIRROR
    export BIOCONDUCTOR_MIRROR
}

#========================================
# 环境检查
#========================================
check_conda_env() {
    if [ -z "$CONDA_PREFIX" ]; then
        log_error "未检测到 Conda 环境！"
        log_error "请先激活 Conda 环境：conda activate bio5"
        exit 1
    fi
    log_info "Conda 环境: $CONDA_DEFAULT_ENV"
    log_info "Conda 路径: $CONDA_PREFIX"
}

check_r() {
    if ! command -v R &> /dev/null; then
        log_error "未找到 R，请在 Conda 环境中安装：mamba install -c conda-forge r-base"
        exit 1
    fi

    local r_ver=$(R --version | head -1 | awk '{print $3}')
    log_info "R 版本: $r_ver"
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "未找到 Python3"
        exit 1
    fi

    local py_ver=$(python3 --version | awk '{print $2}')
    log_info "Python 版本: $py_ver"
}

#========================================
# GitHub Token
#========================================
setup_github_token() {
    local token_file="${SCRIPT_DIR}/.github_token"
    if [ -f "$token_file" ]; then
        GITHUB_TOKEN=$(cat "$token_file" | tr -d '\n')
    else
        GITHUB_TOKEN="${GITHUB_TOKEN:-${GITHUB_PAT:-}}"
    fi

    if [ -n "$GITHUB_TOKEN" ]; then
        export GITHUB_TOKEN
        export GITHUB_PAT="$GITHUB_TOKEN"
        log_info "GitHub Token 已设置"
    fi
}

#========================================
# pip 安装函数
#========================================
pip_install() {
    local packages="$1"
    local extra_args="${2:-}"

    if [ -n "$PIP_INDEX_URL" ]; then
        python3 -m pip install --no-cache-dir -i "$PIP_INDEX_URL" --trusted-host "$PIP_TRUSTED_HOST" $packages $extra_args
    else
        python3 -m pip install --no-cache-dir $packages $extra_args
    fi
}

#========================================
# 清理锁定文件
#========================================
cleanup_locks() {
    local r_lib="${CONDA_PREFIX}/lib/R/library"
    if [ -d "$r_lib" ]; then
        local lock_count=$(find "$r_lib" -maxdepth 1 -name "00LOCK-*" -type d 2>/dev/null | wc -l)
        if [ "$lock_count" -gt 0 ]; then
            log_info "清理 $lock_count 个遗留锁定文件..."
            rm -rf "$r_lib"/00LOCK-* 2>/dev/null || true
        fi
    fi
}

#========================================
# 初始化函数
#========================================
rbio_init() {
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --china)
                USE_CHINA_MIRROR=true
                shift
                ;;
            --password)
                SUDO_PASSWORD="$2"
                shift 2
                ;;
            --help)
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done

    # 配置镜像源
    if [ "$USE_CHINA_MIRROR" = true ]; then
        setup_china_mirrors
    else
        setup_default_mirrors
    fi

    # 设置 sudo
    setup_sudo

    # 检查环境
    check_conda_env
    check_r
    check_python

    # 设置 GitHub Token
    setup_github_token

    # 清理锁定文件
    cleanup_locks

    log_info "日志文件: $LOG_FILE"
}