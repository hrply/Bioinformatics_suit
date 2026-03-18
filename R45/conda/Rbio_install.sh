#!/bin/bash
# R-bio 顺序执行所有 Stage 的包装脚本 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate bio5
#   ./Rbio_install.sh --china
#   ./Rbio_install.sh --stage 3 --china
#   ./Rbio_install.sh --proxy http://192.168.3.147:7890 --china
#

set -e

#========================================
# 配置变量
#========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_stage() { echo -e "${CYAN}========================================\n$1\n========================================${NC}"; }

#========================================
# 显示帮助
#========================================
show_help() {
    cat << EOF
R-bio 顺序执行所有 Stage 的包装脚本 (R 4.5.2 + Bioconductor 3.22)

用法：$0 [选项]

选项:
  --china         使用国内镜像源（清华源）
  --proxy URL     设置代理地址（用于访问 GitHub）
  --password P    提供 sudo 密码
  --stage N       从指定阶段开始安装 (1-4, python)
  --help          显示此帮助信息

安装阶段:
  Stage 1:  系统依赖 + Python + 核心 R 包
  Stage 2:  Bioconductor + 单细胞 Python 包
  Stage 3:  Seurat + Signac + 分析工具
  Stage 4:  Giotto + 轨迹分析 + 可选包
  python:   Python 包和GPU支持（Stage 4 后自动执行）

示例:
  $0 --china                                    # 国内镜像
  $0 --proxy http://192.168.3.147:7890 --china  # 指定代理
  $0 --stage 3 --china                          # 从 Stage 3 开始
  $0 --stage python --china                     # 只执行 Python stage

单独执行某个 stage:
  ./Rbio_3.sh --china

前提条件:
  conda create -n bio5 r-base=4.5.2 python=3.12
  conda activate bio5
EOF
}

#========================================
# 执行单个 stage
#========================================
run_stage() {
    local stage_script="$1"
    shift
    local args="$@"

    if [ ! -f "$stage_script" ]; then
        log_error "脚本不存在：$stage_script"
        exit 1
    fi

    log_stage "执行：$stage_script"
    bash "$stage_script" $args
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Stage 执行失败：$stage_script (exit code: $exit_code)"
        exit $exit_code
    fi

    log_info "Stage 完成：$stage_script"
}

#========================================
# 主程序
#========================================
main() {
    # 默认值
    local USE_CHINA_MIRROR=false
    local START_STAGE=""
    local SUDO_PASSWORD=""
    local PROXY_URL=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --china)
                USE_CHINA_MIRROR=true
                shift
                ;;
            --proxy)
                PROXY_URL="$2"
                shift 2
                ;;
            --password)
                SUDO_PASSWORD="$2"
                shift 2
                ;;
            --stage)
                START_STAGE="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项：$1"
                show_help
                exit 1
                ;;
        esac
    done

    # 检查是否在 Conda 环境中
    if [ -z "$CONDA_PREFIX" ]; then
        log_error "此脚本必须在已激活的 Conda 环境中运行！"
        log_error "请先激活 Conda 环境：conda activate <env_name>"
        exit 1
    fi

    # 设置代理环境变量
    if [ -n "$PROXY_URL" ]; then
        export GITHUB_PROXY="$PROXY_URL"
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
    fi

    # 构建通用参数
    local COMMON_ARGS=""
    if [ "$USE_CHINA_MIRROR" = true ]; then
        COMMON_ARGS="$COMMON_ARGS --china"
    fi
    if [ -n "$SUDO_PASSWORD" ]; then
        COMMON_ARGS="$COMMON_ARGS --password $SUDO_PASSWORD"
    fi

    log_info "Conda 环境：$CONDA_DEFAULT_ENV"
    log_info "国内镜像：$USE_CHINA_MIRROR"
    log_info "代理地址：${PROXY_URL:-未设置}"
    log_info "起始阶段：${START_STAGE:-从头开始}"

    # 执行安装
    if [ "$START_STAGE" = "python" ]; then
        # 只安装 Python 部分
        run_stage "${SCRIPT_DIR}/Rbio_python.sh" $COMMON_ARGS
    else
        # 从指定 stage 开始顺序执行
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 1 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_1.sh" $COMMON_ARGS
        fi
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 2 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_2.sh" $COMMON_ARGS
        fi
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 3 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_3.sh" $COMMON_ARGS
        fi
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 4 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_4.sh" $COMMON_ARGS
        fi

        # Python 支持自动执行（Rbio_4 后自动运行）
        run_stage "${SCRIPT_DIR}/Rbio_python.sh" $COMMON_ARGS
    fi

    log_stage "所有安装完成!"
    log_info "验证安装：Rscript Rbio_verify.R|python Rbio_verify.py"
}

main "$@"