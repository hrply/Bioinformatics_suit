#!/bin/bash
# GPU Stage: GPU Python 包安装 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate r45
#   ./Rbio_stage_gpu.sh [--china]
#
# 注意: GPU 包与 R 版本无关，此脚本与原版相同

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# GPU Stage: GPU Python 包
#========================================
install_gpu_packages() {
    log_stage "[GPU Stage] 安装 GPU Python 包"
    
    log_info "Installing RAPIDS cuML (GPU加速机器学习)"
    pip_install "cuml-cu12 cuml-cu11" \
        || log_warn "cuML 安装失败，尝试替代版本..."
    
    log_info "Installing cupy (GPU数组计算)"
    pip_install "cupy-cuda12x" \
        || pip_install "cupy-cuda11x" \
        || log_warn "cupy 安装失败"
    
    log_info "Installing GPU-enabled scanpy dependencies"
    pip_install "cudf-cu12 cudf-cu11" \
        || log_warn "cudf 安装失败（可选）"
    
    log_info "Installing RAPIDS cuGraph (GPU图算法)"
    pip_install "cugraph-cu12 cugraph-cu11" \
        || log_warn "cuGraph 安装失败（可选）"
    
    # 验证 GPU 包
    log_info "Verifying GPU packages..."
    python3 -c "
try:
    import cupy
    print(f'  [OK] cupy {cupy.__version__}')
except ImportError:
    print('  [MISSING] cupy')

try:
    import cuml
    print(f'  [OK] cuml {cuml.__version__}')
except ImportError:
    print('  [MISSING] cuml')
" 2>/dev/null || log_warn "GPU包验证失败"
    
    log_stage_complete "GPU Stage: GPU Python 包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "GPU Stage: GPU Python 包安装"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        echo "需要 CUDA 12.x 或 11.x 环境"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_gpu_packages
    log_info "GPU Stage 完成！"
}

main "$@"

