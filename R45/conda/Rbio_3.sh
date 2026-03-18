#!/bin/bash
# =============================================================================
# Rbio_3.sh - Giotto + External Packages
# =============================================================================
# Purpose: Install Giotto and external packages
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

log_stage "[Stage 3] Giotto + External Scripts"

# Install dependencies via conda first to avoid compilation errors
log_info "[Stage 3] Installing dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    r-igraph \
    r-fs \
    r-dqrng \
    r-rcpp \
    r-rcppeigen \
    || echo "[INFO] Some dependencies may already be installed"

# -----------------------------------------------------------------------------
# Stage 3a: Giotto (GitHub - prone to failure, separate layer)
# -----------------------------------------------------------------------------
log_info "[Stage 3a] Installing Giotto dependencies..."

# Install Giotto CRAN dependencies first
Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}'));
install.packages(c('dbscan', 'ggraph', 'tidygraph', 'ggforce', 'graphlayouts'), Ncpus = 4)
"

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 3a] Using GitHub proxy: ${GITHUB_PROXY}"
fi

# Install Giotto GitHub dependencies first (order matters)
log_info "[Stage 3a] Installing GiottoUtils..."
Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
remotes::install_github('drieslab/GiottoUtils', dependencies = FALSE)
"

log_info "[Stage 3a] Installing GiottoVisuals..."
Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
remotes::install_github('drieslab/GiottoVisuals', dependencies = TRUE, upgrade = 'never')
"

log_info "[Stage 3a] Installing GiottoClass..."
Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
remotes::install_github('drieslab/GiottoClass', dependencies = TRUE, upgrade = 'never')
"

log_info "[Stage 3a] Installing Giotto..."
Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
remotes::install_github('drieslab/Giotto', dependencies = TRUE, upgrade = 'never')
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 3a] Completed."

log_stage "[Stage 3b] ComplexHeatmap + AUCell"

# -----------------------------------------------------------------------------
# Stage 3b: CRAN Dependencies (ComplexHeatmap deps + missing packages)
# -----------------------------------------------------------------------------
log_info "[Stage 3b] Installing CRAN dependencies..."

Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}'));
install.packages(c('GlobalOptions', 'circlize', 'ggExtra', 'randomForest'), Ncpus = 4)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 3b] Completed."

# -----------------------------------------------------------------------------
# Stage 3c: Bioconductor Base Packages (ComplexHeatmap + AUCell)
# -----------------------------------------------------------------------------
log_info "[Stage 3c] Installing ComplexHeatmap and AUCell from Bioconductor..."

Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
BiocManager::install(c('ComplexHeatmap', 'AUCell'), ask = FALSE, update = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

log_info "[Stage 3c] Completed."

log_stage "[Stage 3d] Spatial Analysis + Cell Communication"

# Install dependencies via conda first to avoid compilation errors
# Note: igraph, fs, textshaping, svglite, systemfonts should already be installed from Rbio_3.sh
log_info "Checking/installing dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    r-rfast \
    r-ggnewscale \
    r-ks \
    dmlc \
    xgboost py-xgboost r-xgboost \
    || echo "[INFO] Some dependencies may already be installed"

# -----------------------------------------------------------------------------
# Stage 3d: SpatialCellChat Dependencies (ALRA + MERINGUE)
# -----------------------------------------------------------------------------
log_info "[Stage 3d] Installing MERINGUE dependencies..."

# Install MERINGUE CRAN dependencies
Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}'));
install.packages(c('akima', 'dynamicTreeCut', 'geometry', 'DT'), Ncpus = 4)
"

log_info "[Stage 3d] Installing ALRA and MERINGUE..."

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 3d] Using GitHub proxy: ${GITHUB_PROXY}"
    Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
remotes::install_github('KlugerLab/ALRA', dependencies = FALSE)
remotes::install_github('JEFworks-Lab/MERINGUE', build_vignettes = FALSE, dependencies = FALSE)
"
else
    Rscript -e "
options(download.file.method = 'auto')
remotes::install_github('KlugerLab/ALRA', dependencies = FALSE)
remotes::install_github('JEFworks-Lab/MERINGUE', build_vignettes = FALSE, dependencies = FALSE)
"
fi

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 3d] Completed."

# -----------------------------------------------------------------------------
# Stage 3e: Cell Communication Packages (GitHub)
# -----------------------------------------------------------------------------
log_info "[Stage 3e] Installing CellChat dependencies..."

# Install CellChat CRAN dependencies
Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}'));
install.packages(c('NMF', 'ggalluvial', 'sna', 'ggnetwork', 'collapse'), Ncpus = 4)
"

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 3e] Using GitHub proxy: ${GITHUB_PROXY}"
    CELLCHAT_OPTS="download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))"
else
    CELLCHAT_OPTS="download.file.method = 'auto'"
fi

# CellChat
log_info "[Stage 3e] Installing CellChat..."
Rscript -e "
options(${CELLCHAT_OPTS})
remotes::install_github('jinworks/CellChat', dependencies = FALSE)
"

# celltalker
log_info "[Stage 3e] Installing celltalker..."
Rscript -e "
options(${CELLCHAT_OPTS})
remotes::install_github('CilloLaboratory/celltalker', dependencies = FALSE)
"

# SpatialCellChat (depends on CellChat + ALRA + MERINGUE)
log_info "[Stage 3e] Installing SpatialCellChat..."
Rscript -e "
options(${CELLCHAT_OPTS})
remotes::install_github('jinworks/SpatialCellChat', dependencies = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 3e] Completed."

log_stage "Trajectory Analysis + GitHub Packages"

# -----------------------------------------------------------------------------
# Stage 3f: Trajectory Analysis Packages (Bioconductor)
# -----------------------------------------------------------------------------
log_info "[Stage 3f] Installing trajectory analysis packages..."

Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
BiocManager::install(c('monocle', 'slingshot', 'tradeSeq'), update = FALSE, ask = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 3f] Completed."

# -----------------------------------------------------------------------------
# Stage 3g: GitHub Packages (MAST, Nebulosa)
# -----------------------------------------------------------------------------
log_info "[Stage 3g] Installing GitHub packages (MAST, Nebulosa)..."

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 3g] Using GitHub proxy: ${GITHUB_PROXY}"
fi

# MAST
log_info "[Stage 3g] Installing MAST..."
Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
# Use dependencies = FALSE to avoid upgrading conda-installed packages
remotes::install_github('RGLab/MAST', dependencies = FALSE)
"

# Nebulosa
log_info "[Stage 3g] Installing Nebulosa..."
Rscript -e "
options(
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
# Use dependencies = FALSE to avoid upgrading conda-installed packages
remotes::install_github('powellgenomicslab/Nebulosa', dependencies = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 3g] Completed."

log_stage "Harmony + Compilation Packages"

# -----------------------------------------------------------------------------
# Stage 3h: harmony + scDblFinder
# -----------------------------------------------------------------------------
log_info "[Stage 3h] Installing harmony (CRAN)..."

Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}'));
install.packages(c('harmony'), Ncpus = 4)
"

# Setting conda UDUNITS2_XML_PATH to avoid udunits2.xml not found error in some packages (e.g. scDblFinder)
conda env config vars set UDUNITS2_XML_PATH="${CONDA_PREFIX}/share/udunits/udunits2.xml"
export UDUNITS2_XML_PATH="${CONDA_PREFIX}/share/udunits/udunits2.xml"

log_info "[Stage 3h] Installing scDblFinder (Bioconductor)..."
Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
BiocManager::install(c('leiden', 'raster', 'vegan', 'RcppTOML'), ask = FALSE, dependencies = TRUE, update = FALSE);
BiocManager::install('scDblFinder', ask = FALSE, update = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 3h] Completed."

# -----------------------------------------------------------------------------
# Stage 3i: Packages Requiring Compilation (BPCells, monocle3)
# -----------------------------------------------------------------------------
log_info "[Stage 3i] Installing packages requiring compilation..."

# Install BPCells from GitHub (compilation required)
log_info "[Stage 3i] Installing BPCells from GitHub..."
Rscript -e "
options(repos = c(cran = '${CRAN_MIRROR}'));
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', repos = '${CRAN_MIRROR}');
# Install from GitHub with dependencies = FALSE to use conda-installed deps
remotes::install_github('bnprks/BPCells/r', dependencies = FALSE, upgrade = 'never')
" || echo "[WARNING] BPCells installation may have failed"

# Install grr from CRAN Archive (monocle3 dependency)
log_info "[Stage 3i] Installing grr from CRAN Archive..."
cd /tmp
curl -o grr_0.9.5.tar.gz https://cran.r-project.org/src/contrib/Archive/grr/grr_0.9.5.tar.gz
R CMD INSTALL grr_0.9.5.tar.gz
rm -f grr_0.9.5.tar.gz
cd -

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 3i] Using GitHub proxy: ${GITHUB_PROXY}"
fi

# batchelor (monocle3 dependency)
log_info "[Stage 3i] Installing batchelor..."
Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
BiocManager::install('batchelor', update = FALSE, ask = FALSE)
"

# monocle3 CRAN dependencies (not available via conda)
log_info "[Stage 3i] Installing monocle3 CRAN dependencies..."
Rscript -e "
options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'));
install.packages(c('ggdist', 'pbmcapply', 'pscl', 'rsample', 'speedglm'), Ncpus = 4);
BiocManager::install(c('Matrix', 'irlba', 'Rcpp'), update = FALSE, ask = FALSE, dependencies = TRUE, type = 'source')
"

# monocle3 (requires proxy for GitHub access)
log_info "[Stage 3i] Installing monocle3..."
Rscript -e "
options(
    repos = c(cran = '${CRAN_MIRROR}'),
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools', repos = '${CRAN_MIRROR}');
# Use upgrade = 'never' and dependencies = FALSE to avoid recompiling dependencies
devtools::install_github('cole-trapnell-lab/monocle3', upgrade = 'never', dependencies = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 3i] Completed."

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
log_stage_complete "Stage 3: Giotto + External Packages"
log_info "Next step: Run Rbio_cpu.sh for Azimuth and final setup"
