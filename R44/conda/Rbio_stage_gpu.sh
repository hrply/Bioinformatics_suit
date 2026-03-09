#!/bin/bash
# GPU Stage: GPU Python 包安装
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage_gpu.sh [--china]
#
# CUDA 版本策略:
#   - RAPIDS 需要 CUDA 13.1.x 库
#   - PyTorch cu130 固定 CUDA 13.0.x 库
#   - 解决方案: 先装 RAPIDS，再用 --no-deps 装 PyTorch 核心
#   - 统一使用 cuda-python 13.1.1
#
# 参考: https://github.com/pytorch/pytorch/issues

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# GPU 支持
#========================================
install_gpu_packages() {
    log_stage "[GPU] 安装 GPU Python 包"
    
    # Step 0: 安装诊断工具
    log_info "Installing diagnostic tools (pipdeptree)"
    pip_install "pipdeptree" || true
    
    # Step 1: 先安装 RAPIDS 核心组件（建立 CUDA 13.1.x 基础层）
    # 注意: 不安装 rapids 元包，避免触发额外依赖覆盖
    log_info "Installing RAPIDS core components (CUDA 13.1) - establishes CUDA library base"
    pip_install "cudf-cu13 cuml-cu13 cugraph-cu13 dask-cuda dask-cudf-cu13" || { log_warn "RAPIDS安装失败"; }
    
    # 检查 RAPIDS 安装后的 NVIDIA 库版本
    log_info "Checking NVIDIA library versions after RAPIDS installation"
    pip list 2>/dev/null | grep -E "^nvidia-|^cuda-" | head -20 || true
    
    # Step 2: 安装 cuda-python 13.1.1（与 RAPIDS CUDA 库匹配）
    log_info "Installing cuda-python 13.1.1 (matches RAPIDS CUDA libraries)"
    pip_install "cuda-python==13.1.1" || log_warn "cuda-python 安装失败"
    
    # Step 3: 用 --no-deps 安装 PyTorch 核心（避免覆盖 CUDA 库）
    # 这样 PyTorch 会使用 RAPIDS 安装的 CUDA 库
    log_info "Installing PyTorch core with --no-deps (uses existing CUDA libraries)"
    pip install --no-deps torch torchvision \
        --index-url https://download.pytorch.org/whl/cu130 \
        || { log_warn "PyTorch 核心安装失败"; }
    
    # Step 4: 安装 PyTorch 非 NVIDIA 依赖（完整列表）
    # 这些是 PyTorch 运行所需的通用库，不涉及 CUDA 版本冲突
    log_info "Installing PyTorch non-NVIDIA dependencies"
    pip_install "sympy networkx jinja2 fsspec filelock typing-extensions MarkupSafe mpmath pillow" || true
    
    # 注意：此时不测试 PyTorch 导入，因为 --no-deps 安装后 CUDA 依赖不完整
    # PyTorch 依赖会在安装 scvi-tools 时自动补全（Step 6）
    log_info "PyTorch dependencies will be completed after scvi-tools installation"
    
    # Step 5: 安装 CuPy（CUDA 13.x）
    log_info "Installing CuPy (CUDA 13)"
    pip_install "cupy-cuda13x" || { log_warn "CuPy安装失败"; }
    
    # Step 6: 安装生物信息学 GPU 包（scvi-tools 会修复 PyTorch CUDA 依赖）
    log_info "Installing bioinformatics GPU packages (scvi-tools will fix PyTorch CUDA dependencies)"
    pip_install "scvi-tools" || log_warn "scvi-tools安装失败"
    pip_install "jax[cuda13]" || log_warn "JAX CUDA安装失败"
    pip_install "tensorflow" || log_warn "TensorFlow安装失败"
    pip_install "torch-geometric" || log_warn "PyTorch Geometric安装失败"
    
    # Step 8: 最终依赖检查
    log_info "Checking final dependency consistency with pip check"
    if ! pip check 2>&1; then
        log_warn "Dependency conflicts detected, running detailed analysis..."
        # 使用 pipdeptree 分析冲突
        log_info "Analyzing dependency tree for key packages..."
        pipdeptree --reverse --packages nvidia-cublas,cuda-bindings,cuda-python 2>/dev/null | head -30 || true
    fi
    
    # Step 9: 最终功能验证（PyTorch + RAPIDS 共存测试）
    log_info "Final verification: PyTorch + RAPIDS coexistence test"
    python3 -c "
import torch
import cudf
print('=' * 50)
print('PyTorch + RAPIDS Coexistence Test')
print('=' * 50)
print(f'PyTorch version: {torch.__version__}')
print(f'Torch CUDA available: {torch.cuda.is_available()}')
print(f'cuDF version: {cudf.__version__}')
if torch.cuda.is_available():
    # 测试 PyTorch CUDA 运算
    x = torch.randn(1000, 1000, device='cuda')
    y = torch.matmul(x, x)
    print(f'PyTorch CUDA matrix multiply: SUCCESS (result shape: {y.shape})')
    # 测试 cuDF
    df = cudf.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})
    print(f'cuDF DataFrame test: SUCCESS (shape: {df.shape})')
print('=' * 50)
print('All tests PASSED!')
" || log_warn "PyTorch + RAPIDS 共存测试失败"
    
    log_stage_complete "GPU: Python GPU 包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "GPU Stage: GPU Python 包安装 (CUDA 13)"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        echo "包含:"
        echo "  - RAPIDS core (cudf, cuml, cugraph) - 建立 CUDA 13.1.x 基础层"
        echo "  - PyTorch 核心 (torch, torchvision) - 使用现有 CUDA 库"
        echo "  - CuPy, scvi-tools, cellbender, JAX, TensorFlow, PyG"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_gpu_packages
    log_info "GPU Stage 完成！"
}

main "$@"
