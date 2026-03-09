# R-Bio 集成分析Docker镜像基础镜像构建文件
# 整合 Seurat, Signac, Azimuth, ArchR, Giotto
# 基础镜像构建于 rocker/tidyverse，包含R 4.4.3和常用数据科学包
# 采用多阶段构建，本文件用于构建基础镜像，后续阶段将基于此镜像构建用于生成环境的最终镜像
# 构建命令: 
#   分阶段构建:
#     docker build --target stage1 -t r-bio:stage1 -f R-bioBase.dockerfile .
#     docker build --target stage2 -t r-bio:stage2 -f R-bioBase.dockerfile .
#     docker build --target stage3 -t r-bio:stage3 -f R-bioBase.dockerfile .
#     docker build --target stage4 -t r-bio:stage4 -f R-bioBase.dockerfile .
#     docker build --target stage5 -t r-bio:stage5 -f R-bioBase.dockerfile .
#   若使用代理构建:
#     docker build --target stage1 -t r-bio:stage1 -f R-bioBase.dockerfile --build-arg HTTP_PROXY=http:// --build-arg HTTPS_PROXY=http:// .
#   若使用国内镜像构建 (推荐):
#     docker build -t r-bio:latest -f R-bioBase.dockerfile \
#       --build-arg CRAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/CRAN/ \
#       --build-arg BIOCONDUCTOR_MIRROR=https://mirrors.westlake.edu.cn/bioconductor .
#   可用的国内镜像源:
#     CRAN: https://mirrors.tuna.tsinghua.edu.cn/CRAN/ (清华)
#           https://mirrors.ustc.edu.cn/CRAN/ (中科大)
#           https://mirrors.hit.edu.cn/CRAN/ (哈工大)
#     Bioconductor: https://mirrors.westlake.edu.cn/bioconductor (西湖大学)

#========================================
# 第一阶段：系统依赖 + Python环境 + Shiny + 基础R包
#========================================
FROM rocker/tidyverse:4.4.3 AS stage1

# 设置R选项
ENV R_PKG_INSTALL_ARGS="--no-html"
ENV RETICULATE_MINICONDA_ENABLED=FALSE
ENV HDF5_PLUGIN_PATH=/lzf

# 代理设置（仅用于构建，不内置于最终镜像）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}
ENV GITHUB_PAT=${GITHUB_TOKEN:-}
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=localhost,127.0.0.1

# 镜像源设置（可通过 build-arg 覆盖）
ARG CRAN_MIRROR=https://cloud.r-project.org
ARG BIOCONDUCTOR_MIRROR=https://bioconductor.org
ENV CRAN_URL=${CRAN_MIRROR}
ENV BIOCONDUCTOR_URL=${BIOCONDUCTOR_MIRROR}

# RUN 1: 基础构建工具
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-1] Installing build tools\033[0m" && \
    apt-get install -y --no-install-recommends \
        cmake git gcc g++ make patch wget curl \
        && rm -rf /var/lib/apt/lists/*

# RUN 2: Java
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-2] Installing Java\033[0m" && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jdk \
        && rm -rf /var/lib/apt/lists/*

# RUN 3: Python
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-3] Installing Python\033[0m" && \
    apt-get install -y --no-install-recommends \
        python3-dev python3-pip python3.12-venv python3-numpy \
        && rm -rf /var/lib/apt/lists/*

# RUN 4: 核心开发库
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-4] Installing core libraries\033[0m" && \
    apt-get install -y --no-install-recommends \
        libboost-all-dev libcurl4-openssl-dev libfftw3-dev \
        libbz2-dev liblzma-dev zlib1g-dev libz-dev libv8-dev \
        && rm -rf /var/lib/apt/lists/*

# RUN 5: Giotto dependencies (GIS库)
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-5] Installing GIS libraries\033[0m" && \
    apt-get install -y --no-install-recommends \
        libgdal-dev libgeos-dev libgsl-dev libhdf5-dev \
        libproj-dev libsqlite3-dev \
        && rm -rf /var/lib/apt/lists/*

# RUN 6: 图像和图形库
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-6] Installing graphics libraries\033[0m" && \
    apt-get install -y --no-install-recommends \
        libpng-dev libcairo2-dev libtesseract-dev \
        libpango1.0-dev libatk1.0-dev libatkmm-1.6-dev libglib2.0-dev libharfbuzz-dev \
        libpoppler-cpp-dev \
        && rm -rf /var/lib/apt/lists/*

# RUN 7: 其他依赖库
RUN apt-get update && \
    echo -e "\033[1;32m[Stage 1-7] Installing other dependencies\033[0m" && \
    apt-get install -y --no-install-recommends \
        libssl-dev libudunits2-dev libxml2-dev libuv1 \
        libglpk40 libgit2-dev libxt-dev \
        && rm -rf /var/lib/apt/lists/*

# Python venv (UMAP和Giotto)
RUN echo -e "\033[1;32m[Stage 1] Installing python dependencies via venv\033[0m" && \
    python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir numpy umap-learn llvmlite pandas scipy scikit-learn h5py macs3

ENV PATH="/opt/venv/bin:${PATH}"

# Miniconda (Giotto依赖)
RUN echo -e "\033[1;32m[Stage 1] Installing Miniconda\033[0m" && \
    mkdir -p /opt/r-miniconda && \
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -u -b -p /opt/r-miniconda && \
    rm /tmp/miniconda.sh

ENV RETICULATE_MINICONDA_PATH=/opt/r-miniconda
ENV PATH="/opt/r-miniconda/bin:${PATH}"

# Shiny Server (Ubuntu 24.04官方仓库)
RUN echo -e "\033[1;32m[Stage 1] Installing Shiny Server\033[0m" && \
    apt-get update && apt-get install -y shiny-server && rm -rf /var/lib/apt/lists/*

# 额外Python包 (Miniconda)
RUN echo -e "\033[1;32m[Stage 1] Installing additional Python packages\033[0m" && \
    /opt/r-miniconda/bin/pip install --no-cache-dir imagecodecs tifffile scikit-image annoy

# 安装pak包管理器
RUN echo -e "\033[1;32m[Stage 1] Installing pak package manager\033[0m" && \
    Rscript -e "install.packages('pak', repos='https://r-lib.github.io/p/pak/stable/')"

# 设置自定义库路径
RUN Rscript -e "dir.create('/usr/local/lib/R/custom-lib', recursive = TRUE); .libPaths('/usr/local/lib/R/custom-lib')"

# 先安装 BiocManager
RUN echo -e "\033[1;32m[Stage 1] Installing BiocManager\033[0m" && \
    Rscript -e "options(repos = c(cran = '${CRAN_MIRROR}'), download.file.method = 'libcurl'); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', upgrade = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

# 安装 Bioconductor 核心包
RUN echo -e "\033[1;32m[Stage 1] Installing Bioconductor core packages\033[0m" && \
    Rscript -e "options(download.file.method = 'libcurl'); \
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}'); \
options(repos = c(CRAN = '${CRAN_MIRROR}')); \
BiocManager::install(c('Biobase','BiocGenerics','DESeq2','DelayedArray', \
    'GenomicRanges','GenomeInfoDb','glmGamPoi','IRanges','limma','MAST', \
    'monocle','rtracklayer','S4Vectors','SingleCellExperiment', \
    'SummarizedExperiment'), update = FALSE, ask = FALSE, \
    site_repository = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc')" && \
    rm -rf /root/.cache/R /tmp/*

# 安装 CRAN 包 (via pak)
RUN echo -e "\033[1;32m[Stage 1] Installing CRAN packages via pak\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}'), \
      download.file.method = 'libcurl'); \
pak::pkg_install(c( \
    'cowplot','fastDummies','fitdistrplus','future','future.apply', \
    'generics','ggplot2','ggridges','httr','ica','igraph','irlba','jsonlite', \
    'KernSmooth','leidenbase','lifecycle','lmtest','matrixStats','miniUI','patchwork', \
    'pbapply','plotly','png','progressr','RANN','RColorBrewer','Rcpp', \
    'RcppAnnoy','RcppHNSW','reticulate','ROCR','RSpectra','Rtsne', \
    'scales','scattermore','sctransform','shiny','spatstat.explore', \
    'spatstat.geom','uwot','ape','arrow','base64enc','data.table','enrichR', \
    'ggrastr','harmony','hdf5r','magrittr','metap','mixtools','rsvd', \
    'R.utils','Rfast2','sf','sp','testthat','VGAM','remotes'), upgrade = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

# 安装兼容版本ggrepel
RUN echo -e "\033[1;32m[Stage 1] Installing ggrepel (compatible version)\033[0m" && \
    Rscript -e "options(repos = c(cran = '${CRAN_MIRROR}'), download.file.method = 'libcurl'); \
remotes::install_version('ggrepel', version = '0.9.5', upgrade = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

# 安装 monocle3 (需要 grr from CRAN Archive)
RUN echo -e "\033[1;32m[Stage 1] Installing monocle3\033[0m" && \
    cd /tmp && \
    wget -q ${CRAN_MIRROR}/src/contrib/Archive/grr/grr_0.9.5.tar.gz && \
    R CMD INSTALL grr_0.9.5.tar.gz && \
    rm -f grr_0.9.5.tar.gz && \
    Rscript -e "options(repos = c(cran = '${CRAN_MIRROR}'), download.file.method = 'libcurl'); \
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}'); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install(c('batchelor'), update = FALSE, ask = FALSE, \
    site_repository = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'); \
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools'); \
devtools::install_github('cole-trapnell-lab/monocle3', upgrade = 'never')" && \
    rm -rf /root/.cache/R /tmp/*

# 更新基础R包
RUN echo -e "\033[1;32m[Stage 1] Updating base R packages\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'), \
      download.file.method = 'libcurl'); \
update.packages(oldPkgs = c('withr', 'rlang'), ask = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

#========================================
# 可视化包 (Stage1末尾 - 不破坏已有缓存)
#========================================

# Python可视化包 (CyTOF)
RUN echo -e "\033[1;32m[Stage 1] Installing Python visualization packages\033[0m" && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir matplotlib seaborn biopython

# R可视化包
RUN echo -e "\033[1;32m[Stage 1] Installing R visualization packages\033[0m" && \
    Rscript -e "options(repos = c(cran = '${CRAN_MIRROR}'), download.file.method = 'libcurl'); \
install.packages(c('ggplot2', 'patchwork'), upgrade = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

#========================================
# 第二阶段：Seurat + Signac + HDF5 LZF + Azimuth
#========================================
FROM stage1 AS stage2

# 代理设置（仅用于构建，不内置于最终镜像）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=localhost,127.0.0.1

# 镜像源设置（继承自 stage1，需要重新声明）
ARG CRAN_MIRROR=https://cloud.r-project.org
ARG BIOCONDUCTOR_MIRROR=https://bioconductor.org
ENV CRAN_URL=${CRAN_MIRROR}
ENV BIOCONDUCTOR_URL=${BIOCONDUCTOR_MIRROR}

RUN echo -e "\033[1;32m[Stage 2] Installing Seurat and Signac ecosystem\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc', \
                  bnprks = 'https://bnprks.r-universe.dev', \
                  satijalab = 'https://satijalab.r-universe.dev'), \
      download.file.method = 'libcurl'); \
proxy <- Sys.getenv('HTTP_PROXY'); \
if (nzchar(proxy)) { \
    Sys.setenv(HTTP_PROXY = proxy, HTTPS_PROXY = proxy); \
}; \
pak::pkg_install(c( \
    'satijalab/seurat-object@cran', 'satijalab/seurat@cran', \
    'Signac', \
    'mojaveazure/seurat-disk', 'satijalab/seurat-data', 'satijalab/seurat-wrappers', \
    'BPCells', 'presto'), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# HDF5 LZF插件 (Azimuth依赖) - 使用pip安装h5py替代手动编译
RUN echo -e "\033[1;32m[Stage 2] Installing h5py with LZF support\033[0m" && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir h5py && \
    mkdir -p /lzf && \
    echo "h5py installed, LZF support via h5py"

# Azimuth安装
RUN echo -e "\033[1;32m[Stage 2] Installing Azimuth\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'), \
      download.file.method = 'libcurl'); \
proxy <- Sys.getenv('HTTP_PROXY'); \
if (nzchar(proxy)) { \
    Sys.setenv(HTTP_PROXY = proxy, HTTPS_PROXY = proxy); \
}; \
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools'); \
devtools::install_github('satijalab/azimuth')" && \
    rm -rf /root/.cache/R /tmp/*

#========================================
# 第三阶段：ArchR
#========================================
FROM stage2 AS stage3

# 代理设置（仅用于构建，不内置于最终镜像）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=localhost,127.0.0.1

# 镜像源设置（需要重新声明）
ARG CRAN_MIRROR=https://cloud.r-project.org
ARG BIOCONDUCTOR_MIRROR=https://bioconductor.org
ENV CRAN_URL=${CRAN_MIRROR}
ENV BIOCONDUCTOR_URL=${BIOCONDUCTOR_MIRROR}

RUN echo -e "\033[1;32m[Stage 3] Installing ArchR and dependencies\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'), \
      download.file.method = 'libcurl'); \
options(BioC_mirror = '${BIOCONDUCTOR_MIRROR}'); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install(c('GenomicRanges', 'GenomeInfoDb', 'IRanges', 'S4Vectors', \
    'SummarizedExperiment', 'SingleCellExperiment', 'limma', 'BiocParallel', \
    'rhdf5', 'rsvd', 'JASPAR2020', 'BSgenome.Hsapiens.UCSC.hg38', 'EnsDb.Hsapiens.v86', \
    'TFBSTools', 'chromVAR', 'motifmatchr'), update = FALSE, ask = FALSE, \
    site_repository = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc')" && \
    rm -rf /root/.cache/R /tmp/*

# 安装TFMPvalue from CRAN Archive
RUN echo -e "\033[1;32m[Stage 3] Installing TFMPvalue from CRAN Archive\033[0m" && \
    cd /tmp && \
    wget -q ${CRAN_MIRROR}/src/contrib/Archive/TFMPvalue/TFMPvalue_0.0.9.tar.gz && \
    R CMD INSTALL TFMPvalue_0.0.9.tar.gz && \
    rm -f TFMPvalue_0.0.9.tar.gz

# 安装ArchR
RUN echo -e "\033[1;32m[Stage 3] Installing ArchR\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'), \
      download.file.method = 'libcurl'); \
proxy <- Sys.getenv('HTTP_PROXY'); \
if (nzchar(proxy)) { \
    Sys.setenv(HTTP_PROXY = proxy, HTTPS_PROXY = proxy); \
}; \
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools'); \
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes'); \
remotes::install_github('GreenleafLab/ArchR', ref='master', \
    repos = BiocManager::repositories(), quiet = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 安装ArchR额外依赖
RUN echo -e "\033[1;32m[Stage 3] Installing ArchR extra packages\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'), \
      download.file.method = 'libcurl'); \
library(ArchR); \
ArchR::installExtraPackages()" && \
    rm -rf /root/.cache/R /tmp/*

#========================================
# 第四阶段：Giotto
#========================================
FROM stage3 AS stage4

# 代理设置（仅用于构建，不内置于最终镜像）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=localhost,127.0.0.1

# 镜像源设置（需要重新声明）
ARG CRAN_MIRROR=https://cloud.r-project.org
ARG BIOCONDUCTOR_MIRROR=https://bioconductor.org
ENV CRAN_URL=${CRAN_MIRROR}
ENV BIOCONDUCTOR_URL=${BIOCONDUCTOR_MIRROR}

RUN echo -e "\033[1;32m[Stage 4] Installing Giotto and dependencies\033[0m" && \
    Rscript -e "\
options(repos = c(cran = '${CRAN_MIRROR}', \
                  bioconductor = '${BIOCONDUCTOR_MIRROR}/packages/3.20/bioc'), \
      download.file.method = 'libcurl'); \
proxy <- Sys.getenv('HTTP_PROXY'); \
if (nzchar(proxy)) { \
    Sys.setenv(HTTP_PROXY = proxy, HTTPS_PROXY = proxy); \
}; \
pak::pkg_install(c('units', 'scattermore', 'reshape2', 'geometry', 'RTriangle', 'drieslab/Giotto'), upgrade = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

# 验证Giotto
RUN echo -e "\033[1;32m[Stage 4] Verifying Giotto installation\033[0m" && \
    Rscript -e "library(Giotto); cat('Giotto version:', as.character(packageVersion('Giotto')), '\n')" && \
    rm -rf /root/.cache/R /tmp/*

#========================================
# 第五阶段：RStudio配置 + 额外工具包
#========================================
FROM stage4 AS stage5

# 代理设置（仅用于构建，不内置于最终镜像）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=localhost,127.0.0.1

# 镜像源设置（需要重新声明）
ARG CRAN_MIRROR=https://cloud.r-project.org
ARG BIOCONDUCTOR_MIRROR=https://bioconductor.org
ENV CRAN_URL=${CRAN_MIRROR}
ENV BIOCONDUCTOR_URL=${BIOCONDUCTOR_MIRROR}

# RStudio配置
RUN echo -e "\033[1;32m[Stage 5] Configuring RStudio\033[0m" && \
    cat > /usr/local/lib/R/etc/Rprofile.site << 'RPROFILE'
local({
  options(repos = c(
    CRAN = "CRAN_MIRROR_PLACEHOLDER",
    BioCsoft = "BIOCONDUCTOR_MIRROR_PLACEHOLDER/packages/3.20/bioc",
    BioCann = "BIOCONDUCTOR_MIRROR_PLACEHOLDER/packages/3.20/data/annotation",
    BioCexp = "BIOCONDUCTOR_MIRROR_PLACEHOLDER/packages/3.20/data/experiment",
    BioCworkflows = "BIOCONDUCTOR_MIRROR_PLACEHOLDER/packages/3.20/workflows"
  ))
})
RPROFILE
    sed -i "s|CRAN_MIRROR_PLACEHOLDER|${CRAN_MIRROR}|g" /usr/local/lib/R/etc/Rprofile.site && \
    sed -i "s|BIOCONDUCTOR_MIRROR_PLACEHOLDER|${BIOCONDUCTOR_MIRROR}|g" /usr/local/lib/R/etc/Rprofile.site

# 创建用户
RUN (useradd -m -s /bin/bash rstudio || echo "User rstudio already exists") && \
    echo "rstudio:rstudio" | chpasswd

# 额外Python工具包（scanpy等）
RUN echo -e "\033[1;32m[Stage 5] Installing additional Python packages (scanpy)\033[0m" && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir scanpy

# 清理临时文件
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/R

#========================================
