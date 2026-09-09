#!/bin/bash
# =============================================================================
# Rbio_1.sh - Stage Seurat + Enhancement Packages + Signac and SingleR
# =============================================================================
# Purpose: Install Seurat and Seurat enhancement packages
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Load common environment from Rbio_common.sh
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

# Initialize with command line arguments
rbio_init "$@"

log_stage "[Stage 2 extra] Seurat + Enhancement Packages"

# Set environment
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# -----------------------------------------------------------------------------
# Stage 2g: Seurat v5 (CRAN Official)
# -----------------------------------------------------------------------------
log_info "[Stage 2g] Installing Seurat v5 from CRAN..."

# Install Seurat dependencies via conda first to avoid compilation
log_info "[Stage 2g] Installing Seurat dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge r-devtools\
    r-rcpphnsw \
    r-rcppeigen \
    r-rcpparmadillo \
    r-reticulate \
    r-sf \
    r-s2 \
    r-rcpptoml \
    r-polyclip \
    r-rann \
    r-gtools \
    r-catools \
    r-here \
    r-gplots \
    r-fitdistrplus \
    r-miniui \
    r-pbapply \
    r-rocr \
    r-scattermore \
    || echo "[INFO] Some dependencies may already be installed"

# Try to install Seurat via conda (r-seurat exists in conda-forge)
log_info "[Stage 2g] Installing Seurat via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    r-seurat \
    || echo "[INFO] Will install Seurat from CRAN"

# Install Seurat from CRAN if not installed via conda
log_info "[Stage 2g] Installing Seurat from CRAN..."
Rscript -e "
if (!requireNamespace('Seurat', quietly = TRUE)) {
    install.packages(c('Seurat', 'SeuratObject'), repos = '${CRAN_MIRROR}', Ncpus = 4)
}
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 2g] Completed."

# -----------------------------------------------------------------------------
# Stage 2h: Seurat Enhancement Packages (GitHub)
# -----------------------------------------------------------------------------
log_info "[Stage 2h] Installing Seurat enhancement packages from GitHub..."

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 2h] Using GitHub proxy: ${GITHUB_PROXY}"
    Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
devtools::install_github('immunogenomics/presto')
"
else
    Rscript -e "
options(download.file.method = 'auto')
devtools::install_github('immunogenomics/presto')
"
fi

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 2h] Completed."

log_stage "[Stage 2i] Signac + SingleR"

echo "  Bioconductor Mirror: ${BIOCONDUCTOR_MIRROR}"

# -----------------------------------------------------------------------------
# Stage 2i: Signac (Bioconductor Official)
# -----------------------------------------------------------------------------
echo ""
echo "[Stage 2i] Installing Signac from Bioconductor..."

Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
# Install Signac without updating dependencies that are already installed
BiocManager::install('Signac', ask = FALSE, update = FALSE, force = TRUE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
echo "[Stage 2i] Completed."

# -----------------------------------------------------------------------------
# Stage 2j: SingleR (Bioconductor Official)
# -----------------------------------------------------------------------------
echo ""
echo "[Stage 2j] Installing SingleR from Bioconductor..."

Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
# Install SingleR without updating dependencies that are already installed
BiocManager::install('SingleR', ask = FALSE, update = FALSE, force = TRUE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

echo "[Stage 2j] Completed."

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
log_stage_complete "Stage 2: Seurat + Enhancement Packages + Signac and SingleR"
log_info "Next step: Run Rbio_3.sh for Signac and SingleR"
