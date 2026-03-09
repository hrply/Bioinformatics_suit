#!/bin/bash
# R-bio 顺序执行所有 Stage 的包装脚本 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate r45
#   ./Rbio_install.sh --cpu [--china]
#   ./Rbio_install.sh --gpu [--china]
#   ./Rbio_install.sh --stage 5 [--china]  # 从 Stage 5 开始
#
# 注意: 此版本跳过 Stage 6 (ArchR)，因为 ArchR 不适配 R 4.5

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

用法: $0 [选项]

选项:
  --cpu           安装 CPU 版本（默认）
  --gpu           安装 GPU 版本（包含 GPU Python包）
  --china         使用国内镜像源（清华源）
  --password P    提供 sudo 密码
  --stage N       从指定阶段开始安装 (1-8, gpu，跳过6)
  --help          显示此帮助信息

安装阶段:
  Stage 1: Conda 编译依赖
  Stage 2: 预编译 R 包 (conda-forge)
  Stage 3: Python 包 (含可视化)
  Stage 4: R 包 (CRAN + Bioconductor)
  Stage 5: Seurat + Signac + Azimuth
  (跳过 Stage 6: ArchR - 不适配 R 4.5)
  Stage 7: Giotto
  Stage 8: 额外工具包 (scanpy, SingleR)
  GPU:      GPU Python 包, CUDA 13（--gpu时安装）

示例:
  $0 --cpu                      # CPU 版本
  $0 --gpu --china              # GPU + 国内镜像
  $0 --stage 5 --china          # 从 Stage 5 开始
  $0 --stage gpu --china        # 只执行 GPU stage

单独执行某个 stage:
  ./Rbio_5.sh --china

前提条件:
  conda create -n r45 r-base=4.5.2 python=3.12
  conda activate r45
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
        log_error "脚本不存在: $stage_script"
        exit 1
    fi
    
    log_stage "执行: $stage_script"
    bash "$stage_script" $args
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log_error "Stage 执行失败: $stage_script (exit code: $exit_code)"
        exit $exit_code
    fi
    
    log_info "Stage 完成: $stage_script"
}

#========================================
# 主程序
#========================================
main() {
    # 默认值
    local USE_GPU=false
    local USE_CHINA_MIRROR=false
    local START_STAGE=""
    local SUDO_PASSWORD=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cpu)
                USE_GPU=false
                shift
                ;;
            --gpu)
                USE_GPU=true
                shift
                ;;
            --china)
                USE_CHINA_MIRROR=true
                shift
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
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查是否在 Conda 环境中
    if [ -z "$CONDA_PREFIX" ]; then
        log_error "此脚本必须在已激活的 Conda 环境中运行！"
        log_error "请先激活 Conda 环境: conda activate <env_name>"
        exit 1
    fi
    
    # 构建通用参数
    local COMMON_ARGS=""
    if [ "$USE_CHINA_MIRROR" = true ]; then
        COMMON_ARGS="$COMMON_ARGS --china"
    fi
    if [ -n "$SUDO_PASSWORD" ]; then
        COMMON_ARGS="$COMMON_ARGS --password $SUDO_PASSWORD"
    fi
    
    log_info "Conda 环境: $CONDA_DEFAULT_ENV"
    log_info "GPU 支持: $USE_GPU"
    log_info "国内镜像: $USE_CHINA_MIRROR"
    log_info "起始阶段: ${START_STAGE:-从头开始}"
    log_warn "注意: Stage 6 (ArchR) 已跳过，因为 ArchR 不适配 R 4.5"
    
    # 执行安装
    if [ "$START_STAGE" = "gpu" ]; then
        # 只安装 GPU 部分
        run_stage "${SCRIPT_DIR}/Rbio_stage_gpu.sh" $COMMON_ARGS
    else
        # 从指定 stage 开始顺序执行（跳过 Stage 6）
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
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 5 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_5.sh" $COMMON_ARGS
        fi
        # Stage 6 (ArchR) 跳过
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 7 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_7.sh" $COMMON_ARGS
        fi
        if [ -z "$START_STAGE" ] || [ "$START_STAGE" -le 8 ] 2>/dev/null; then
            run_stage "${SCRIPT_DIR}/Rbio_8.sh" $COMMON_ARGS
        fi
        
        # GPU 支持
        if [ "$USE_GPU" = true ]; then
            run_stage "${SCRIPT_DIR}/Rbio_sgpu.sh" $COMMON_ARGS
        fi
    fi
    
    log_stage "所有安装完成!"
    log_info "可以使用以下命令验证安装:"
    echo "  Rscript -e \"library(Seurat); library(Signac); library(Giotto)\""
}

main "$@"
