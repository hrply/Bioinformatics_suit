#!/bin/bash
# =============================================================================
# Rbio_1.sh - Rbio_base Stage 1+2
# =============================================================================
# Purpose: Install system dependencies, R package managers, and core CRAN packages
# Note: Equivalent to rocker/geospatial:4.5.2 base image
# =============================================================================

set -e

# Load common environment variables from Rbio_common.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

# Initialize with command line arguments
rbio_init "$@"

# Get mirror settings from Rbio_common.sh
CONDA_ENV_NAME="${CONDA_ENV_NAME:-bio1}"

echo "  R-bio Stage 0 (1a + 1b)"
echo "  Conda Environment: ${CONDA_ENV_NAME}"
echo "  CRAN Mirror: ${CRAN_MIRROR}"
echo "  Bioconductor Mirror: ${BIOCONDUCTOR_MIRROR}"
echo "  Proxy: ${HTTP_PROXY:-${http_proxy:-Not set}}"

# -----------------------------------------------------------------------------
# Stage 1a: System Dependencies (equivalent to rocker/geospatial base)
# -----------------------------------------------------------------------------
echo ""
echo "[Stage 1a] Installing geospatial system dependencies..."

# Stage 1a-1: Check libabsl-dev
if ! dpkg -l libabsl-dev >/dev/null 2>&1; then
    log_error "libabsl-dev is not installed."
    log_error "Please run command before setup: sudo apt install libabsl-dev"
    exit 1
fi
log_info "libabsl-dev is installed."

mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    geos gdal proj \
    || echo "[INFO] May already be installed"

# Stage 1a-2: HDF5 and netcdf
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    hdf5 netcdf4 \
    || echo "[INFO] May already be installed"

# Stage 1a-3: UDUnits
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    udunits2 \
    || echo "[INFO] May already be installed"

# Stage 1a-4: Database libs
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    libpq postgresql libsqlite sqlite libabseil \
    || echo "[INFO] May already be installed"

# Stage 1a-5: Build tools and libs
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    libssh2 libcurl openssl libxml2 \
    libgfortran libgcc-ng libgomp \
    fftw gsl libglu tk unixodbc \
    cmake curl wget git libtool pkg-config \
    libpng libjpeg-turbo libtiff freetype \
    gmp mpfr \
    || echo "[INFO] May already be installed"

# Install R package managers and core R packages
echo "[Stage 1a] Installing R package managers..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-remotes \
    r-pak \
    r-rcpp \
    r-rcpparmadillo \
    r-rcppeigen \
    || true

rm -rf /tmp/Rtmp* 2>/dev/null || true
echo "[Stage 1a] Completed."

# -----------------------------------------------------------------------------
# Stage 1b: Core R Packages
# -----------------------------------------------------------------------------
echo ""
echo "[Stage 1b] Installing core R packages..."

# Batch 1: Tidyverse core
echo "[Stage 1b - Batch 1] Installing tidyverse core..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-dplyr r-tidyr r-purrr r-tibble r-stringr r-forcats \
    r-data.table r-reshape2 r-plyr \
    || echo "[INFO] Some packages may already be installed"

# Batch 2: ggplot2 and visualization
echo "[Stage 1b - Batch 2] Installing visualization packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-ggplot2 r-cowplot r-patchwork r-ggrepel r-gridextra r-gtable \
    r-viridis r-scales r-colorspace \
    r-ggthemes r-ggplotify r-ggpubr r-ggridges r-plotly \
    || echo "[INFO] Some packages may already be installed"

# Batch 3: Statistics
echo "[Stage 1b - Batch 3] Installing statistics packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-mass r-matrix r-lattice r-survival r-boot r-cluster r-kernsmooth \
    r-broom r-car r-mvtnorm r-glmnet \
    r-multcomp r-emmeans r-effectsize r-performance \
    || echo "[INFO] Some packages may already be installed"

# Batch 4: R markdown
echo "[Stage 1b - Batch 4] Installing R markdown packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-rmarkdown r-knitr r-htmltools r-htmlwidgets \
    r-yaml r-jsonlite r-evaluate r-highr r-xfun \
    || echo "[INFO] Some packages may already be installed"

# Batch 5: Tools and utilities
echo "[Stage 1b - Batch 5] Installing utility packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-testthat r-rlang r-vctrs r-cli r-glue r-crayon r-withr \
    r-lifecycle r-pillar r-generics r-tidyselect r-magrittr \
    r-r6 r-fansi r-prettyunits \
    r-ellipsis r-memoise r-sessioninfo r-urlchecker r-waldo \
    r-commonmark r-stringi r-rappdirs r-rprojroot r-selectr \
    || echo "[INFO] Some packages may already be installed"

# Batch 6: Web and data import
echo "[Stage 1b - Batch 6] Installing web and data packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-xml2 r-curl r-httr r-openssl \
    r-readr r-haven r-cellranger r-googlesheets4 r-gargle \
    r-rvest r-openxlsx \
    r-conflicted r-dbplyr r-dtplyr r-googledrive r-ids \
    || echo "[INFO] Some packages may already be installed"

# Batch 7: Spatial packages (via mamba)
# Note: r-spatialreg, r-rnetcdf, r-tidync not available for r45, install via pak
echo "[Stage 1b - Batch 7] Installing spatial packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-sf r-sp r-raster r-terra r-stars \
    r-classint r-rcolorbrewer \
    r-spdep r-gstat \
    r-s2 r-wk r-units \
    r-ncdf4 r-hdf5r \
    r-fnn r-abind \
    || echo "[INFO] Some packages may already be installed"

# Batch 8: Parallel/future packages
echo "[Stage 1b - Batch 8] Installing parallel/future packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-progressr r-logging r-snow r-parallelly r-future r-future.apply r-listenv \
    || echo "[INFO] Some packages may already be installed"

# Batch 9: Time/date packages
echo "[Stage 1b - Batch 9] Installing time/date packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-hms r-timechange r-lubridate r-tzdb \
    || echo "[INFO] Some packages may already be installed"

# Batch 10: Build tools and web packages
echo "[Stage 1b - Batch 10] Installing build tools and web packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-desc r-pkgbuild r-pkgload r-digest r-cachem r-fastmap \
    r-later r-promises r-httpuv r-shiny r-shinybs r-shinydashboard \
    || echo "[INFO] Some packages may already be installed"

# Batch 11: Data I/O packages
echo "[Stage 1b - Batch 11] Installing data I/O packages..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    r-vroom r-bit r-bit64 r-plogr r-cpp11 r-mime r-progress r-tidync \
    || echo "[INFO] Some packages may already be installed"

# Batch 12: Install packages not available in conda-forge for r45
echo "[Stage 1b - Batch 12] Installing remaining packages via pak..."
Rscript -e "
options(repos = c(CRAN = '${CRAN_MIRROR}', Bioconductor = '${BIOCONDUCTOR_MIRROR}'));

# Packages NOT available in conda-forge for r45
# These require compilation via pak
pkgs <- c(
    'spatialreg',
    'RNetCDF', 
    'tidync'
);

missing <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)];
if (length(missing) > 0) {
    message('Installing via pak: ', paste(missing, collapse = ', '));
    pak::pkg_install(missing, upgrade = FALSE);
} else {
    message('All packages already installed');
}
" || echo "[INFO] Some packages may need manual installation"

rm -rf /tmp/Rtmp* 2>/dev/null || true
echo "[Stage 1b] Completed."

log_stage "Bioconductor + ML/Statistics + Seurat Dependencies"
# -----------------------------------------------------------------------------
# Stage 1c: Bioconductor Base Packages (via conda only)
# -----------------------------------------------------------------------------
log_info "[Stage 1c] Installing Bioconductor base packages via conda..."

# Install core dependencies via conda to avoid compilation issues
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    r-fs \
    r-igraph \
    r-dqrng \
    r-svglite \
    r-rcppparallel \
    || true

# Install Bioconductor packages via conda where available
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    -c bioconda \
    bioconductor-biocversion \
    bioconductor-biocgenerics \
    bioconductor-biocparallel \
    bioconductor-biobase \
    bioconductor-s4vectors \
    bioconductor-iranges \
    bioconductor-xvector \
    bioconductor-genomicranges \
    bioconductor-genomeinfodb \
    bioconductor-genomeinfodbdata \
    bioconductor-summarizedexperiment \
    bioconductor-singlecellexperiment \
    bioconductor-matrixgenerics \
    bioconductor-delayedarray \
    bioconductor-delayedmatrixstats \
    bioconductor-rhdf5 \
    bioconductor-rhdf5filters \
    bioconductor-rhdf5lib \
    bioconductor-hdf5array \
    bioconductor-annotationdbi \
    bioconductor-rsamtools \
    bioconductor-limma \
    bioconductor-edger \
    bioconductor-deseq2 \
    bioconductor-scran \
    bioconductor-scater \
    bioconductor-gsva \
    bioconductor-gseabase \
    bioconductor-geoquery \
    r-rcpp \
    r-checkmate \
    || echo "[INFO] Some Bioconductor packages will be installed via R later"

echo "[Stage 1c] Completed."

# -----------------------------------------------------------------------------
# Stage 1d: Statistics and ML + Seurat Dependencies (via conda only)
# -----------------------------------------------------------------------------
echo ""
echo "[Stage 1d] Installing statistics and ML packages via conda..."

mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    -c bioconda \
    r-irlba \
    r-rspectra \
    r-rtsne \
    r-uwot \
    r-mclust \
    r-lme4 \
    r-nlme \
    r-vegan \
    r-leiden \
    gcc_linux-64 gxx_linux-64 gfortran_linux-64 gcc make cmake libblas liblapack pkg-config \
    || echo "[INFO] Some packages will be installed via R later"

tools=("gcc" "g++" "gfortran")

for tool in "${tools[@]}"; do
    # 构造完整路径
    target_link="$CONDA_PREFIX/bin/$tool"
    # 构造原始 Conda 程序路径 (以 x86_64-conda-linux-gnu- 开头)
    source_bin="$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-$tool"

    if [ -L "$target_link" ] || [ -f "$target_link" ]; then
        echo "✅ $tool is existed in $target_link"
    else
        if [ -f "$source_bin" ]; then
            echo "🔗 creating soft link: $tool -> $(basename $source_bin)"
            ln -s "$source_bin" "$target_link"
        else
            echo "❌ warning: source file $source_bin not found, please confirm if the corresponding compiler package is installed."
        fi
    fi
done

log_info "[Stage 1d] Completed."

log_stage "Python 3.12 + Core Python Packages"
# -----------------------------------------------------------------------------
# Stage 2a: Python 3.12 Environment
# -----------------------------------------------------------------------------
log_info "[Stage 2a] Setting up Python 3.12 environment..."

# Install Python 3.12 via conda
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    python=3.12 \
    pip \
    setuptools \
    wheel \
    || echo "[WARNING] Python may already be installed"

# Configure pip mirror
pip config set global.index-url "${PIP_INDEX_URL}"

# Set environment variables (using conda environment directly)
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

log_info "[Stage 2a] Python 3.12 installed in conda environment"
log_info "[Stage 2a] Completed."

# -----------------------------------------------------------------------------
# Stage 2b: Core Python Packages
# -----------------------------------------------------------------------------
log_info "[Stage 2b] Installing core Python packages..."

pip install --no-cache-dir \
    numpy \
    scipy \
    pandas \
    matplotlib \
    seaborn \
    numba \
    h5py \
    tables \
    zarr \
    pyarrow

log_info "[Stage 2b] Completed."

# -----------------------------------------------------------------------------
# stage 2: Single-cell Python packages Annotation databases - Bioconductor)
# -----------------------------------------------------------------------------
log_stage "[Stage 2] Single-cell Python + Annotation Databases"

# Set environment (using conda environment directly)
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# Install system dependencies via conda first to avoid compilation errors
log_info "[Stage 2c] Installing system dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    libpng \
    libxml2 \
    xz \
    boost-cpp \
    libcurl \
    openssl \
    zlib \
    bzip2 \
    || echo "[INFO] Some dependencies may already be installed"

# Install R dependencies via conda first to avoid compilation
log_info "[Stage 2c] Installing R dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    -c bioconda \
    r-png \
    r-xml \
    r-rsqlite \
    bioconductor-rhtslib \
    || true

# Install BPCells dependencies via conda first to avoid complex dependency issues during installation
# Note: bioconductor-zlibbioc removed - only has r44 build, causes r-base downgrade
# zlibbioc will be compiled by R during BPCells installation
log_info "[Stage 3i] Installing BPCells dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    r-rcpp \
    r-rcppprogress \
    r-bh \
    || echo "[INFO] Some dependencies may already be installed"

# -----------------------------------------------------------------------------
# Stage 2c: Single-cell Analysis Python Packages (CPU only)
# Note: scvi-tools and cell2location are installed in Rbio_gpu.sh (GPU version)
# -----------------------------------------------------------------------------
log_info "[Stage 2c] Installing single-cell analysis Python packages (CPU only)..."

pip install --no-cache-dir \
    scanpy \
    anndata \
    leidenalg \
    python-igraph \
    louvain \
    umap-learn \
    phate \
    scvelo \
    squidpy \
    gseapy \
    decoupler

log_info "[Stage 2c] Completed."

# -----------------------------------------------------------------------------
# Stage 2d: Annotation Databases (Bioconductor)
# -----------------------------------------------------------------------------
log_info "[Stage 2d] Installing annotation databases..."

# First, try to install as many packages as possible via conda to avoid compilation
log_info "[Stage 2d] Installing Bioconductor packages via conda..."
# Note: Removed bioconductor-genomeinfodbdata - already installed as dependency of bioconductor-genomeinfodb in Rbio_0b.sh
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    -c bioconda \
    bioconductor-annotationhub \
    bioconductor-org.hs.eg.db \
    bioconductor-org.mm.eg.db \
    bioconductor-bsgenome \
    bioconductor-ensembldb \
    bioconductor-ensdb.hsapiens.v86 \
    || echo "[INFO] Some packages will be installed via BiocManager"

# Install remaining packages via BiocManager
log_info "[Stage 2d] Installing remaining packages via BiocManager..."
Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');

# List of packages to install
# Note: GenomeInfoDbData removed - already installed as dependency in Rbio_0b.sh
pkgs <- c(
    'AnnotationDbi', 'AnnotationHub',
    'org.Hs.eg.db', 'org.Mm.eg.db',
    'BSgenome',
    'ensembldb', 'EnsDb.Hsapiens.v86'
)

# Check which packages are already installed
installed <- pkgs[sapply(pkgs, requireNamespace, quietly = TRUE)]
missing <- pkgs[!pkgs %in% installed]

if (length(missing) > 0) {
    message('Installing missing packages: ', paste(missing, collapse = ', '))
    BiocManager::install(missing, ask = FALSE, update = FALSE)
} else {
    message('All packages already installed')
}
"

rm -rf /tmp/Rtmp* 2>/dev/null || true

log_info "[Stage 2d] Completed."

log_stage "[Stage 3] Genome Databases + Analysis Tools"

# Set environment
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# Install system dependencies via conda first to avoid compilation errors
log_info "[Stage 3] Installing system dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    freetype \
    fontconfig \
    cairo \
    imagemagick \
    libgit2 \
    libcurl \
    openssl \
    zlib \
    harfbuzz \
    fribidi \
    || echo "[INFO] Some dependencies may already be installed"

# Install R dependencies via conda first to avoid compilation
log_info "[Stage 3] Installing R dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    -c bioconda \
    r-systemfonts \
    r-textshaping \
    r-rcppannoy \
    r-cairo \
    r-ragg \
    r-ggrastr \
    r-magick \
    r-rcppml \
    r-memuse \
    bioconductor-beachmat \
    bioconductor-biocneighbors \
    bioconductor-biocsingular \
    bioconductor-bluster \
    bioconductor-scuttle \
    bioconductor-rhdf5 \
    bioconductor-h5mread \
    bioconductor-spatialexperiment \
    || echo "[INFO] Some packages will be installed via R later"

# Set environment
export VIRTUAL_ENV="${CONDA_PREFIX}"
export PATH="${CONDA_PREFIX}/bin:$PATH"

# Install system dependencies via conda first to avoid compilation errors
log_info "[Stage 3] Installing system dependencies via conda..."
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c conda-forge \
    freetype \
    fontconfig \
    cairo \
    imagemagick \
    libgit2 \
    libcurl \
    openssl \
    zlib \
    harfbuzz \
    fribidi \
    || echo "[INFO] Some dependencies may already be installed"

log_stage "[Stage 2e-i] Genome Databases + Analysis Tools"
# -----------------------------------------------------------------------------
# Stage 2e: Genome Databases (BSgenome)
# -----------------------------------------------------------------------------
log_info "[Stage 2e] Installing genome databases (BSgenome)..."

# Check for local BSgenome packages in external_files directory
EXTERNAL_FILES_DIR="${SCRIPT_DIR}/external_files"

Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');

# Check for local BSgenome.Hsapiens.UCSC.hg38 package
hg38_local <- Sys.glob('${EXTERNAL_FILES_DIR}/BSgenome.Hsapiens.UCSC.hg38_*.tar.gz')
if (length(hg38_local) > 0) {
    message('Installing BSgenome.Hsapiens.UCSC.hg38 from local file: ', hg38_local[1])
    install.packages(hg38_local[1], repos = NULL)
} else {
    message('Installing BSgenome.Hsapiens.UCSC.hg38 from Bioconductor...')
    BiocManager::install('BSgenome.Hsapiens.UCSC.hg38', ask = FALSE)
}

# Check for local BSgenome.Mmusculus.UCSC.mm39 package
mm39_local <- Sys.glob('${EXTERNAL_FILES_DIR}/BSgenome.Mmusculus.UCSC.mm39_*.tar.gz')
if (length(mm39_local) > 0) {
    message('Installing BSgenome.Mmusculus.UCSC.mm39 from local file: ', mm39_local[1])
    install.packages(mm39_local[1], repos = NULL)
} else {
    message('Installing BSgenome.Mmusculus.UCSC.mm39 from Bioconductor...')
    BiocManager::install('BSgenome.Mmusculus.UCSC.mm39', ask = FALSE)
}
"

rm -rf /tmp/Rtmp* 2>/dev/null || true
log_info "[Stage 2e] Completed."

# -----------------------------------------------------------------------------
# Stage 2f: Analysis Tools (Bioconductor)
# Note: Core packages (limma, edgeR, DESeq2, scran, scater, GSVA)
# -----------------------------------------------------------------------------
log_info "[Stage 2f] Installing remaining analysis tools..."

# Install remaining packages that are not available via conda
Rscript -e "
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = '${CRAN_MIRROR}');
# Verify core packages are installed
core_pkgs <- c('limma', 'edgeR', 'DESeq2', 'scran', 'scater', 'GSVA', 'GSEABase', 'GEOquery')
installed <- core_pkgs[sapply(core_pkgs, requireNamespace, quietly = TRUE)]
missing <- core_pkgs[!core_pkgs %in% installed]
if (length(missing) > 0) {
    message('Installing missing core packages: ', paste(missing, collapse = ', '))
    BiocManager::install(missing, ask = FALSE, update = FALSE)
} else {
    message('All core packages already installed')
}
# Install remaining packages
BiocManager::install(c('impute', 'preprocessCore'), ask = FALSE, update = FALSE)
" || echo "[INFO] Some packages will be installed later"

rm -rf /tmp/Rtmp* 2>/dev/null || true

log_info "[Stage 2f] Completed."

# configure conda complier environment variables for later use in R packages installation
bash ./external_files/fix_conda_R_Makeconf.sh

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "  Rbio_1.sh Completed Successfully"
echo "  Stage 1: System deps + R package managers + Python basal env + Core R packages - DONE"
echo ""
echo "Next step: Run Rbio_1.sh for Seurat and enhancement packages"
echo ""