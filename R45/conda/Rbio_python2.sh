#!/bin/bash
# =============================================================================
# Rbio_python2.sh - RAPIDS Environment (Based on Rbio_python.sh)
# =============================================================================
# Purpose: Install RAPIDS and additional bioinformatics packages
#          that are in dockerfile but not in Rbio_python.sh
#
# IMPORTANT: This script is for RAPIDS environment with GPU support
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

# Initialize with command line arguments
rbio_init "$@"

log_stage "[Stage RAPIDS] RAPIDS + Additional Bioinformatics Packages"

# -----------------------------------------------------------------------------
# Stage 1: Set up Constraints File (for version compatibility)
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 1] Setting up version constraints..."

cat > "${SCRIPT_DIR}/rapids_constraints.txt" << 'EOF'
bokeh<=3.6.3
holoviews<1.21.0
scikit-image<0.26.0,>=0.25.0
cupy-cuda13x>=13.6.0
shapely<2.1.0
nvidia-nvimgcodec-cu13<0.8.0,>=0.7.0
EOF

log_info "Constraints file created."

# -----------------------------------------------------------------------------
# Stage 2: Install Core Scientific Computing Packages (via mamba)
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 2] Installing core scientific packages via mamba..."

mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    -c nvidia \
    scipy \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    h5py \
    tables \
    zarr \
    pyarrow \
    scrublet \
    python-igraph \
    leidenalg \
    phate \
    umap-learn \
    rpy2 \
    anndata2ri \
    bokeh \
    holoviews \
    scikit-image \
    shapely \
    anndata \
    "scanpy>=1.12" \
    "scvi-tools>=1.4.2" \
    scvelo \
    squidpy \
    gseapy \
    decoupler \
    torch-geometric \
    || log_warn "[WARNING] Some packages may need pip fallback"

log_info "[Stage 2] Completed."

# -----------------------------------------------------------------------------
# Stage 3: Install RAPIDS and GPU Libraries
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 3] Installing RAPIDS and GPU libraries..."

# Configure pip mirror
pip config set global.index-url "${PIP_INDEX_URL}"
pip config set global.extra-index-url "https://pypi.nvidia.com"

# Enforce Conda Environment
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# Install with constraints (only cupy and nvimgcodec)
pip install --no-cache-dir -c "${SCRIPT_DIR}/rapids_constraints.txt" \
    "cupy-cuda13x>=13.6.0" \
    "nvidia-nvimgcodec-cu13<0.8.0,>=0.7.0"

# Install PyTorch with CUDA
pip install --no-cache-dir \
    torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu130

# Install RAPIDS packages
pip install --no-cache-dir -c "${SCRIPT_DIR}/rapids_constraints.txt" \
    rapids-singlecell \
    "jax[cuda13]"

log_info "[Stage 3] Completed."

# -----------------------------------------------------------------------------
# Stage 4: Install Bioinformatics Packages (via pip with constraints)
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 4] Installing bioinformatics packages..."

# Generate constraints from installed GPU packages
pip freeze | grep -Ei "^(torch|torchvision|torchaudio|tensorflow|cupy|cuda|nvidia|jax)" > "${SCRIPT_DIR}/gpu_constraints.txt"

pip install --no-cache-dir -c "${SCRIPT_DIR}/gpu_constraints.txt" \
    cellbender \
    harmonypy \
    flowio \
    bbknn \
    adjustText \
    joblib \
    pydot \
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
    scikit-misc \
    scikit-survival \
    PyCytoData

log_info "[Stage 4] Completed."

# -----------------------------------------------------------------------------
# Stage 5: Additional Packages
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 5] Installing additional packages..."

mamba install -y -n "${CONDA_ENV_NAME}" pycytodata -c kevin931 -c bioconda || \
    pip install --no-cache-dir pycytodata

log_info "[Stage 5] Completed."

# -----------------------------------------------------------------------------
# Verify Installation
# -----------------------------------------------------------------------------
echo ""
log_info "Verifying RAPIDS installation..."

python -c "
import scanpy
import scvi
import rapids_singlecell as rsc
print(f'scanpy version: {scanpy.__version__}')
print(f'scvi-tools version: {scvi.__version__}')
print(f'rapids-singlecell installed: {rsc is not None}')
" || log_warn "[WARNING] RAPIDS verification failed"

log_info "RAPIDS script execution finished successfully!"