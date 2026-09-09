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
  --stage N       运行指定阶段 (1-4, py)
  --R             只运行 R 包部分 (Rbio_R1~R4)
  --python        只运行 Python 部分 (Rbio_python)
  --all           运行全部 (Rbio_R1~R4 + Rbio_python)
  --help          显示此帮助信息

安装阶段:
  Stage 1:  系统依赖 + Python + 核心 R 包
  Stage 2:  Bioconductor + 单细胞 Python 包
  Stage 3:  Seurat + Signac + 分析工具
  Stage 4:  Giotto + 轨迹分析 + 可选包
  py:       Python 包和GPU支持

示例:
  $0 --all --china                             # 运行全部
  $0 --R --china                                # 只运行 R 包
  $0 --python --china                           # 只运行 Python
  $0 --stage 3 --china                          # 只运行 Stage 3
  $0 --stage py --china                         # 只运行 Python
  $0 --proxy http://192.168.3.147:7890 --all --china

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
    local STAGE=""
    local RUN_R=false
    local RUN_PYTHON=false
    local RUN_ALL=false
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
                STAGE="$2"
                shift 2
                ;;
            --R)
                RUN_R=true
                shift
                ;;
            --python)
                RUN_PYTHON=true
                shift
                ;;
            --all)
                RUN_ALL=true
                shift
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

    # 检查参数组合
    if [ -n "$STAGE" ]; then
        # 带 --stage，忽略其他参数
        :
    elif [ "$RUN_R" = true ] && [ "$RUN_PYTHON" = true ]; then
        log_error "不能同时指定 --R 和 --python"
        exit 1
    elif [ "$RUN_R" = false ] && [ "$RUN_PYTHON" = false ] && [ "$RUN_ALL" = false ]; then
        log_error "必须指定 --R, --python 或 --all 之一"
        show_help
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

    # 执行安装
    if [ -n "$STAGE" ]; then
        # --stage N 模式
        log_info "运行阶段：$STAGE"
        case "$STAGE" in
            1)
                run_stage "${SCRIPT_DIR}/Rbio_R1.sh" $COMMON_ARGS
                ;;
            2)
                run_stage "${SCRIPT_DIR}/Rbio_R2.sh" $COMMON_ARGS
                ;;
            3)
                run_stage "${SCRIPT_DIR}/Rbio_R3.sh" $COMMON_ARGS
                ;;
            4)
                run_stage "${SCRIPT_DIR}/Rbio_R4.sh" $COMMON_ARGS
                ;;
            py)
                run_stage "${SCRIPT_DIR}/Rbio_python.sh" $COMMON_ARGS
                ;;
            *)
                log_error "无效的 stage: $STAGE (有效值: 1, 2, 3, 4, py)"
                exit 1
                ;;
        esac
    elif [ "$RUN_R" = true ]; then
        # --R 模式：只运行 Rbio_R1~4
        log_info "运行模式：R (Rbio_R1~4)"
        run_stage "${SCRIPT_DIR}/Rbio_R1.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_R2.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_R3.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_R4.sh" $COMMON_ARGS
    elif [ "$RUN_PYTHON" = true ]; then
        # --python 模式：只运行 Rbio_python
        log_info "运行模式：Python (Rbio_python)"
        run_stage "${SCRIPT_DIR}/Rbio_python.sh" $COMMON_ARGS
    elif [ "$RUN_ALL" = true ]; then
        # --all 模式：运行全部
        log_info "运行模式：全部 (Rbio_R1~4 + Rbio_python)"
        run_stage "${SCRIPT_DIR}/Rbio_R1.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_R2.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_R3.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_R4.sh" $COMMON_ARGS
        run_stage "${SCRIPT_DIR}/Rbio_python.sh" $COMMON_ARGS
    fi

    log_stage "安装完成!"
    log_info "验证安装：Rscript Rbio_verify.R|python Rbio_verify.py"
}

main "$@"