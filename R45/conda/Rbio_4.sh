#!/bin/bash
# =============================================================================
# Rbio_4.sh - Stage 4 (Seurat extensions + Azimuth)
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

log_stage "[Stage 4] Seurat Extensions + Azimuth"

# Set environment (using conda environment directly)
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# -----------------------------------------------------------------------------
# Stage 4a (optional): Optional Packages (allow failure)
# -----------------------------------------------------------------------------
log_info "[Stage 4a optional] Installing optional packages (allowing failure)..."

# Rsubread (requires compilation) - allow failure
log_info "[Stage 4a optional] Installing Rsubread..."
(Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
BiocManager::install('Rsubread', ask = FALSE, update = FALSE)
" && rm -rf /tmp/Rtmp* 2>/dev/null) || log_warn "Rsubread installation failed, skipping..."

log_info "[Stage 4a optional] Completed."

# -----------------------------------------------------------------------------
# Install flowCore via conda (required for FlowSOM/diffcyt)
# flowCore compilation fails due to deprecated Rcpp:::LdFlags() usage
# FlowSOM/diffcyt will be compiled from source after flowCore is installed
# -----------------------------------------------------------------------------
log_info "[Stage 4b] Installing flowCore via conda..."
mamba install -y -c bioconda bioconductor-flowcore --freeze-installed 2>/dev/null || \
    log_warn "flowCore installation via conda failed"

log_info "[Stage 4b] Completed."

# -----------------------------------------------------------------------------
# Seurat Extension Packages: seurat-disk, seurat-data, seurat-wrappers
# -----------------------------------------------------------------------------
log_info "[Stage 4c] Installing Seurat extension packages..."
# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 4c] Using GitHub proxy: ${GITHUB_PROXY}"
fi

mamba install -y -c conda-forge r-sccore --freeze-installed 2>/dev/null || \
    log_warn "Failed to install r-sccore via conda, will attempt installation from CRAN in R"

Rscript -e "
options(
    repos = c(cran = '${CRAN_MIRROR}'),
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools', repos = '${CRAN_MIRROR}');
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', repos = '${CRAN_MIRROR}');
# pagoda2 dependencies (CRAN)
install.packages(c('dendsort', 'drat', 'fastcluster', 'urltools', 'RMTstat', 'Rook'), repos = '${CRAN_MIRROR}', Ncpus = 4)
# pagoda2 dependencies (GitHub)
devtools::install_github('kharchenkolab/N2R', upgrade = FALSE, dependencies = TRUE)
# Use upgrade = FALSE to avoid recompiling dependencies
devtools::install_github('kharchenkolab/pagoda2', upgrade = FALSE, dependencies = FALSE)
remotes::install_github('mojaveazure/seurat-disk', upgrade = FALSE, dependencies = FALSE)
devtools::install_github('satijalab/seurat-data', upgrade = FALSE, dependencies = TRUE)
remotes::install_github('satijalab/seurat-wrappers', upgrade = FALSE, dependencies = FALSE)
remotes::install_github('mianaz/srtdisk', upgrade = FALSE, dependencies = TRUE)
# FlowSOM and diffcyt (flowCore installed via conda)
BiocManager::install('FlowSOM', ask = FALSE, update = FALSE)
BiocManager::install('diffcyt', ask = FALSE, update = FALSE)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 4c] Seurat extension packages completed."

# -----------------------------------------------------------------------------
# HDF5 LZF Plugin (Azimuth dependency)
# Note: h5py is already installed in Rbio_1.sh, skipping re-installation
# -----------------------------------------------------------------------------
log_info "[Stage 4d] Checking h5py installation..."

# Verify h5py is installed (installed in stage1)
python -c "import h5py; print(f'h5py version: {h5py.__version__}')" 2>/dev/null && \
    log_info "h5py already installed, skipping..." || \
    log_warn "h5py not found, you may need to run Rbio_1.sh first"

# -----------------------------------------------------------------------------
# Azimuth for single-cell data annotation and integration
# -----------------------------------------------------------------------------
log_info "[Stage 4e] Installing Azimuth dependencies..."

# Install DT (CRAN) - required for Azimuth
Rscript -e "install.packages('DT', repos = '${CRAN_MIRROR}')"

# Install Bioconductor dependencies
Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
BiocManager::install(c('TFBSTools', 'JASPAR2020', 'glmGamPoi'), ask = FALSE, update = FALSE)
"

log_info "[Stage 4e] Installing Azimuth..."

# Setup proxy if GITHUB_PROXY is set
if [ -n "${GITHUB_PROXY}" ]; then
    export http_proxy="${GITHUB_PROXY}"
    export https_proxy="${GITHUB_PROXY}"
    log_info "[Stage 4e] Using GitHub proxy: ${GITHUB_PROXY}"
    Rscript -e "
options(
    repos = c(cran = '${CRAN_MIRROR}'),
    download.file.method = 'curl',
    download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))
)
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools', repos = '${CRAN_MIRROR}');
# Use upgrade = FALSE to avoid recompiling dependencies
devtools::install_github('satijalab/azimuth', upgrade = FALSE, dependencies = FALSE)
"
else
    Rscript -e "
options(
    repos = c(cran = '${CRAN_MIRROR}'),
    download.file.method = 'auto'
)
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools', repos = '${CRAN_MIRROR}');
# Use upgrade = FALSE to avoid recompiling dependencies
devtools::install_github('satijalab/azimuth', upgrade = FALSE, dependencies = FALSE)
"
fi

rm -rf /tmp/Rtmp* 2>/dev/null || true

# Reset proxy
unset http_proxy
unset https_proxy

log_info "[Stage 4e] Azimuth installation completed."

# -----------------------------------------------------------------------------
#  [Stage 4f] Configure reticulate for Python integration
# -----------------------------------------------------------------------------
log_info "[Stage 4f] Configuring reticulate..."

# Set RETICULATE_PYTHON to avoid conda activate issues
export RETICULATE_PYTHON="${CONDA_PREFIX}/bin/python"
export RETICULATE_MINICONDA_ENABLED=FALSE

# Create Renviron.site with reticulate configuration
R_ENVIRON_DIR="${CONDA_PREFIX}/lib/R/etc"
mkdir -p "${R_ENVIRON_DIR}"
cat > "${R_ENVIRON_DIR}/Renviron.site" << RENVIRON
# R environment configuration
RETICULATE_PYTHON=${CONDA_PREFIX}/bin/python
RETICULATE_MINICONDA_ENABLED=FALSE
PATH=${CONDA_PREFIX}/bin:\${PATH}
RENVIRON

# Verify reticulate can find python
Rscript -e "
Sys.setenv(RETICULATE_MINICONDA_ENABLED = 'FALSE')
reticulate::py_config()
"

log_info "[Stage 4f] reticulate configured."

# -----------------------------------------------------------------------------
#  [Stage 5] final configuration and cleanup
# -----------------------------------------------------------------------------
# Jupyter Lab version
JUPYTERLAB_VERSION="${JUPYTERLAB_VERSION:-4.3.5}"

log_stage "Final Installation: Jupyter Lab + Shiny Extensions"

# Set environment (using conda environment directly)
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# Configure pip mirror
pip config set global.index-url "${PIP_INDEX_URL}"

# -----------------------------------------------------------------------------
# Stage 5a: Install Jupyter Lab + IR kernel
# -----------------------------------------------------------------------------
log_info "[Stage 5a] Installing Jupyter Lab and IR kernel..."

pip install --no-cache-dir \
    jupyterlab==${JUPYTERLAB_VERSION} \
    notebook==7.3.2 \
    ipykernel==6.29.5 \
    ipywidgets==8.1.5 \
    jupyter-client

# R kernel for Jupyter
log_info "[Stage 5b] Installing IRkernel..."
Rscript -e "
install.packages('IRkernel', repos = '${CRAN_MIRROR}')
IRkernel::installspec()
"

# Create Jupyter configuration directory
JUPYTER_CONFIG_DIR="/home/rstudio/.jupyter"
mkdir -p "${JUPYTER_CONFIG_DIR}" 2>/dev/null || mkdir -p ~/.jupyter

# Note: Jupyter config file will be created/updated by init.sh at runtime
# This is just a placeholder with basic settings
cat > ~/.jupyter/jupyter_server_config.py << 'JUPYTER_CONF'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.root_dir = '/data'
JUPYTER_CONF

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 5b] Completed."

# -----------------------------------------------------------------------------
# Stage 5c: Shiny Extension R Packages
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 5c] Installing Shiny extension packages..."

Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}'));
install.packages(c(
    'shinydashboard', 'shinythemes', 'shinyjs', 'shinyWidgets'
), Ncpus = 4)
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 5c] Completed."

# -----------------------------------------------------------------------------
# Stage 5d: Configure RStudio Server
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 5d] Configuring RStudio Server..."

# Check if RStudio Server is installed
if [ -d /etc/rstudio ]; then
    # Configure RStudio Server (only if not already configured)
    if ! grep -q "www-port=8787" /etc/rstudio/rserver.conf 2>/dev/null; then
        echo "www-port=8787" >> /etc/rstudio/rserver.conf 2>/dev/null || \
            log_info "[INFO] Could not modify rserver.conf (may require root)"
    fi
    if ! grep -q "auth-minimum-user-id" /etc/rstudio/rserver.conf 2>/dev/null; then
        echo "auth-minimum-user-id=1000" >> /etc/rstudio/rserver.conf 2>/dev/null || true
    fi
    if ! grep -q "session-default-working-dir" /etc/rstudio/rsession.conf 2>/dev/null; then
        echo "session-default-working-dir=/data" >> /etc/rstudio/rsession.conf 2>/dev/null || true
    fi

    log_info "[Stage 5d] RStudio Server configured."
else
    log_info "[INFO] RStudio Server not installed, skipping configuration..."
fi

log_info "[Stage 5d] Completed."

# -----------------------------------------------------------------------------
# Stage 5e: Copy External Scripts and Cleanup
# -----------------------------------------------------------------------------
echo ""
log_info "[Stage 5e] Setting up external scripts..."

EXTERNAL_FILES_DIR="${SCRIPT_DIR}/external_files"
R_LIB_DIR="${CONDA_PREFIX}/lib/R/site-library"

# Copy ScType (excluding .git directory to avoid permission issues)
if [ -d "${EXTERNAL_FILES_DIR}/ScType" ]; then
    # Remove .git directory if it exists before copying
    rm -rf "${EXTERNAL_FILES_DIR}/ScType/.git" 2>/dev/null || true
    cp -r "${EXTERNAL_FILES_DIR}/ScType" "${R_LIB_DIR}/"
    log_info "[Stage 5e] ScType copied to ${R_LIB_DIR}/ScType"

    # Create ScType.R entry point with correct path
    mkdir -p "${R_LIB_DIR}/ScType/R"
    cat > "${R_LIB_DIR}/ScType/R/ScType.R" << EOF
# ScType entry point
source("${R_LIB_DIR}/ScType/R/sctype_wrapper.R")
EOF
else
    log_warn "[WARNING] ScType not found in ${EXTERNAL_FILES_DIR}/ScType"
fi

# Copy RaceID (excluding .git directory to avoid permission issues)
if [ -d "${EXTERNAL_FILES_DIR}/RaceID" ]; then
    # Remove .git directory if it exists before copying
    rm -rf "${EXTERNAL_FILES_DIR}/RaceID/.git" 2>/dev/null || true
    cp -r "${EXTERNAL_FILES_DIR}/RaceID" "${R_LIB_DIR}/"
    log_info "[Stage 5e] RaceID copied to ${R_LIB_DIR}/RaceID"
else
    log_warn "[WARNING] RaceID not found in ${EXTERNAL_FILES_DIR}/RaceID"
fi

log_info "[Stage 5e] Cleaning up temporary files..."
rm -rf /tmp/* /var/tmp/* /root/.cache/R /root/.cache/pip 2>/dev/null || true

log_info "[Stage 5e] Completed."

# -----------------------------------------------------------------------------
# Stage 6: R packages verification
# -----------------------------------------------------------------------------

log_info "Starting R package verification..."

# 使用 --vanilla 模式运行，并重定向输出到日志文件
R --vanilla < "${SCRIPT_DIR}/Rbio_verify.R"

# 捕获 R 的退出状态码
R_EXIT_CODE=$?

if [ $R_EXIT_CODE -eq 0 ]; then
    log_info "R verification PASSED!"
else
    log_error "R verification FAILED! Check ${SCRIPT_DIR}/r_verification.log for details."
    exit $R_EXIT_CODE
fi
# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
log_stage_complete "R packages installed and verified successfully!"
log_info "Next step: Run Rbio_gpu.sh for GPU acceleration packages (if needed)"
