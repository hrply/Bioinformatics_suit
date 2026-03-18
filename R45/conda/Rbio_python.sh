#!/bin/bash
# =============================================================================
# Rbio_gpu.sh - GPU Stage (Ultimate Clean & Auto-Resolve Version)
# =============================================================================
# Purpose: Install CUDA toolkit and GPU acceleration packages
#          (PyTorch, JAX, TensorFlow, CuPy, etc.)
#
# IMPORTANT: This script requires a system with NVIDIA GPU and appropriate
#            drivers installed (CUDA 13.x compatible).
#
# Very IMPORTANT: RAPIDS and RAPIDS-single should be installed in docker
#                 to avoid numpy and numba version conflicts.
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

# Initialize with command line arguments
rbio_init "$@"

log_stage "[Stage GPU] CUDA + GPU Packages"

log_warn "WARNING: This script installs CUDA toolkit and GPU packages."
log_warn "         Requires NVIDIA GPU and appropriate drivers."

# -----------------------------------------------------------------------------
# Stage 4a: Install CUDA Compiler Toolkit via Conda
# -----------------------------------------------------------------------------
log_info "[Stage 4a] Installing CUDA compiler (nvcc) via mamba..."

# 仅安装编译器和头文件。
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c nvidia \
    -c conda-forge \
    cuda-runtime \
    cudnn \
    cuda-toolkit \
    cuda-cudart-dev \
    || log_info "[INFO] CUDA compiler may already be available via system"

log_info "[Stage 4a] Completed."

# -----------------------------------------------------------------------------
# Stage 4b: Set up CUDA Environment Variables
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 4b] Setting up CUDA environment paths..."

export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"

# Create symlink if CUDA 13.0 exists
if [ -d /usr/local/cuda-13.0 ] && [ ! -L /usr/local/cuda ]; then
    sudo ln -sf /usr/local/cuda-13.0 /usr/local/cuda 2>/dev/null || \
        log_info "[INFO] Could not create CUDA symlink (may require root)"
fi

log_info "[Stage 4b] Completed."

# -----------------------------------------------------------------------------
# Enforce Conda Environment for pip
# -----------------------------------------------------------------------------
# Configure pip mirror
pip config set global.index-url "${PIP_INDEX_URL}"

# 严格锁定在当前的 Conda 环境中
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# =============================================================================
# >>> CORE GPU LIBRARIES (ALL-IN-ONE RESOLUTION) <<<
# =============================================================================
echo ""
log_info "[Stage 4c] Installing Core GPU Libraries..."

# 提取 Python 版本检查 (用于 TensorFlow)
PYTHON_MAJOR=$(python -c "import sys; print(sys.version_info.major)")
PYTHON_MINOR=$(python -c "import sys; print(sys.version_info.minor)")
TF_PACKAGE=""
if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 14 ]; then
    TF_PACKAGE="tensorflow[and-cuda]"
fi

# 修正索引至 cu130
pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cu130 \
    torch torchvision torchaudio \
    cuda-python==13.0.3 \
    cuda-bindings==13.0.3 \
    cupy-cuda13x \
    ${TF_PACKAGE}

log_info "[Stage 4c] Completed."

# =============================================================================
# >>> BIOINFORMATICS STACK (THE CORE) <<<
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 4d: Generate Version Constraints
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 4d] Generating constraints to protect core GPU libraries..."

pip freeze | grep -Ei "^(torch|torchvision|torchaudio|tensorflow|cupy|cuda|nvidia)" > "${SCRIPT_DIR}/gpu_constraints.txt"

log_info "Active Constraints (Sample):"
head -n 10 "${SCRIPT_DIR}/gpu_constraints.txt"
echo "..."
log_info "[Stage 4d] Completed."

# -----------------------------------------------------------------------------
# Stage 4e: Bioinformatics Python Packages with GPU Support
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 4e] Installing bioinformatics packages..."

mamba install -y -c conda-forge "rpy2>=3.6.4" anndata2ri zlib

pip install --no-cache-dir -c "${SCRIPT_DIR}/gpu_constraints.txt" \
    "scvi-tools>=1.12" \
    "scanpy>=1.10" \
    cellbender \
    harmonypy \
    flowio \
    bbknn \
    scirpy \
    pertpy \
    cellrank \
    liana \
    FlowKit \
    PhenoGraph \
    muon \
    snapatac2 \
    ktplotspy \
    cellphonedb \
    pydeseq2 \
    pybiomart \
    diffxpy \
    statsmodels \
    statannotations \
    pingouin \
    pynndescent \
    scikit-network \
    scikit-learn \
    scikit-image \
    scikit-misc \
    scikit-survival \
    PyCytoData

log_info "[Stage 4e] Completed."

# -----------------------------------------------------------------------------
# Stage 4f: PyTorch Geometric
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 4f] Installing PyTorch Geometric..."

pip install --no-cache-dir -c "${SCRIPT_DIR}/gpu_constraints.txt" torch-geometric

log_info "[Stage 4f] Completed."

# -----------------------------------------------------------------------------
# Stage 4g: Additional Python Packages
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 4g] Installing additional Python packages..."

mamba install -y -n "${CONDA_ENV_NAME}" pycytodata -c kevin931 -c bioconda

pip install --no-cache-dir -c "${SCRIPT_DIR}/gpu_constraints.txt" \
    pydot

log_info "[Stage 4g] Completed."

# -----------------------------------------------------------------------------
# Verify GPU Setup
# -----------------------------------------------------------------------------
echo ""
echo "  Verifying GPU Setup"

echo ""
echo "Checking PyTorch CUDA availability..."
python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
    print(f'GPU name: {torch.cuda.get_device_name(0)}')
" || log_warn "[WARNING] PyTorch CUDA verification failed"

echo ""
echo "Checking JAX GPU availability..."
python -c "
import jax
try:
    print(f'JAX version: {jax.__version__}')
    print(f'GPU devices: {jax.devices(\"gpu\")}')
except Exception as e:
    print(f'JAX GPU Check failed: {e}')
" 2>/dev/null || log_info "[INFO] JAX GPU verification skipped"

log_info "GPU script execution finished successfully!"