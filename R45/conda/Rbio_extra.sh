#!/bin/bash
# =============================================================================
# Rbio_extra.sh - for adding extra or customized packages and tools
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

log_stage "Custoizing Rbio environment with extra packages and tools"

# Set environment (using conda environment directly)
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}"
export R_LIBS_USER="${CONDA_PREFIX}/lib/R/site-library"
export R_LIB_DIR="${CONDA_PREFIX}/lib/R/site-library"

# ----------------------------
# Conda pre-complied packages
# ----------------------------
mamba install -y -c conda-forge -c bioconda \
    bioconductor-celldex hcc aspera-cli \
    

# Python packages
# Important: keep "${SCRIPT_DIR}/gpu_constraints.txt"
pip install --no-cache-dir \
    celldex \
    biocpy \
    datahugger
    

# -----------------------------
# R packages
# -----------------------------

Rscript -e "
# Install R packages via direct network
options(repos = c(CRAN = '${CRAN_MIRROR}')); \
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}'); \
options(download.file.method = "auto", download.file.extra = NULL); \
BiocManager::install(c('dbscan', 'ggraph', 'tidygraph', 'ggforce', 'graphlayouts'), ask = FALSE, update = FALSE, dependencies = TRUE); \
# Install R packages via proxy
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
); \
BiocManager::install("celldex", ask = FALSE, update = FALSE); \
devtools::install_github('', dependencies = TRUE, upgrade = FALSE); \
options(download.file.method = "auto", download.file.extra = NULL) \
"