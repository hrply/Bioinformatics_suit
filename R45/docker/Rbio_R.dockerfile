# =============================================================================
# Stage 2: Rbio_R - 多阶段构建
# Base: r-bio:base
# Purpose: 生信分析 R 包 + Python 环境
# 
# 镜像命名: r-bio:R-1, r-bio:R-2, ..., r-bio:R-14, r-bio:R
# =============================================================================

# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# Stage 2-1: Python 环境
# 生成镜像: r-bio:R-1
# -----------------------------------------------------------------------------
FROM r-bio:base AS R-1

ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN
ARG CRAN_URL
ARG BIOC_URL
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}
ENV PIP_INDEX_URL=${PIP_INDEX_URL:-}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST:-}

# Python 3.12 虚拟环境
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 配置 pip 镜像源 (如果设置了 PIP_INDEX_URL)
RUN if [ -n "${PIP_INDEX_URL}" ]; then \
        pip config set global.index-url "${PIP_INDEX_URL}"; \
        if [ -n "${PIP_TRUSTED_HOST}" ]; then \
            pip config set global.trusted-host "${PIP_TRUSTED_HOST}"; \
        fi; \
    fi

# 创建 Python 虚拟环境
RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV=/opt/venv

# 核心 Python 包
RUN pip install --no-cache-dir \
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

# -----------------------------------------------------------------------------
# Stage 2-2: 注释数据库
# 生成镜像: r-bio:R-2
# -----------------------------------------------------------------------------
FROM R-1 AS R-2

# 重新声明 ARG（多阶段构建需要）
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 注释数据库 (Bioconductor)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install(c('AnnotationDbi', 'AnnotationHub', 'org.Hs.eg.db', 'org.Mm.eg.db', \
    'BSgenome', 'GenomeInfoDbData', 'ensembldb', 'EnsDb.Hsapiens.v86'), ask = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# 基因组数据库 (BSgenome)
# 复制本地离线包 (如果存在) - 使用通配符匹配任意版本
COPY external_files/BSgenome*.tar.gz /tmp/

# 安装基因组数据库
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
# 查找本地 BSgenome.Hsapiens.UCSC.hg38 包 \
hg38_local <- Sys.glob('/tmp/BSgenome.Hsapiens.UCSC.hg38_*.tar.gz'); \
if (length(hg38_local) > 0) { \
    message('Installing BSgenome.Hsapiens.UCSC.hg38 from local file: ', hg38_local[1]); \
    install.packages(hg38_local[1], repos = NULL); \
} else { \
    message('Installing BSgenome.Hsapiens.UCSC.hg38 from Bioconductor...'); \
    BiocManager::install('BSgenome.Hsapiens.UCSC.hg38', ask = FALSE); \
}; \
# 查找本地 BSgenome.Mmusculus.UCSC.mm39 包 \
mm39_local <- Sys.glob('/tmp/BSgenome.Mmusculus.UCSC.mm39_*.tar.gz'); \
if (length(mm39_local) > 0) { \
    message('Installing BSgenome.Mmusculus.UCSC.mm39 from local file: ', mm39_local[1]); \
    install.packages(mm39_local[1], repos = NULL); \
} else { \
    message('Installing BSgenome.Mmusculus.UCSC.mm39 from Bioconductor...'); \
    BiocManager::install('BSgenome.Mmusculus.UCSC.mm39', ask = FALSE); \
} \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-3: 核心分析包
# 生成镜像: r-bio:R-3
# -----------------------------------------------------------------------------
FROM R-2 AS R-3

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 分析工具包 (Bioconductor)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install(c('limma', 'edgeR', 'DESeq2', 'scran', 'scater', \
    'GSVA', 'GSEABase', 'GEOquery', 'impute', 'preprocessCore'), ask = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# Seurat v5 (CRAN官方安装)
RUN Rscript -e " \
install.packages(c('Seurat', 'SeuratObject'), repos = Sys.getenv('CRAN_URL'), Ncpus = 4) \
" && \
    rm -rf /root/.cache/R /tmp/*

# Seurat 增强包 (GitHub) - 使用代理
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
devtools::install_github('immunogenomics/presto') \
" && \
    rm -rf /root/.cache/R /tmp/*

# Signac (Bioconductor官方安装)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install('Signac', ask = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# SingleR (Bioconductor官方安装)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install('SingleR', ask = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-4: Giotto (容易失败，单独分层)
# 生成镜像: r-bio:R-4
# -----------------------------------------------------------------------------
FROM R-3 AS R-4

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# Giotto (GitHub安装 - 避免CRAN网络问题) - 使用代理
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('drieslab/Giotto'); \
remotes::install_github('drieslab/GiottoClass') \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-5: 其他常用R包 + 外部脚本
# 生成镜像: r-bio:R-5
# -----------------------------------------------------------------------------
FROM R-4 AS R-5

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN
ARG CRAN_URL
ARG BIOC_URL
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}
ENV CRAN_URL=${CRAN_URL:-https://cloud.r-project.org}
ENV BIOC_URL=${BIOC_URL:-https://bioconductor.org}
ENV PIP_INDEX_URL=${PIP_INDEX_URL:-}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST:-}

# 设置镜像源
RUN if [ "${mirror}" = "china" ] || [ "${mirror}" = "China" ]; then \
        echo "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN'))" >> /usr/local/lib/R/etc/Rprofile.site; \
        export BIOC_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/bioconductor"; \
    else \
        echo "options(repos = c(CRAN = 'https://cloud.r-project.org'))" >> /usr/local/lib/R/etc/Rprofile.site; \
        export BIOC_MIRROR="https://bioconductor.org/packages/release/bioc"; \
    fi && \
    echo "options(BioC_mirror = '${BIOC_MIRROR}')" >> /usr/local/lib/R/etc/Rprofile.site

# 复制外部脚本
COPY external_files/ScType /usr/local/lib/R/site-library/ScType
COPY external_files/RaceID /usr/local/lib/R/site-library/RaceID

# 创建 ScType.R 入口文件（解决验证脚本路径问题）
RUN echo '# ScType entry point' > /usr/local/lib/R/site-library/ScType/R/ScType.R && \
    echo 'source("/usr/local/lib/R/site-library/ScType/R/sctype_wrapper.R")' >> /usr/local/lib/R/site-library/ScType/R/ScType.R

# -----------------------------------------------------------------------------
# Stage 2-6: CRAN 包 (ComplexHeatmap 依赖 + 缺失包)
# 生成镜像: r-bio:R-6
# -----------------------------------------------------------------------------
FROM R-5 AS R-6

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 安装 ComplexHeatmap 依赖 + 缺失的 CRAN 包
RUN Rscript -e " \
options(repos = c(CRAN = Sys.getenv('CRAN_URL'))); \
install.packages(c('GlobalOptions', 'circlize', 'ggExtra', 'randomForest'), Ncpus = 4) \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-7: Bioconductor 基础包
# 生成镜像: r-bio:R-7
# -----------------------------------------------------------------------------
FROM R-6 AS R-7

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 安装 ComplexHeatmap + AUCell (Bioconductor)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install(c('ComplexHeatmap', 'AUCell'), ask = FALSE, update = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-8: SpatialCellChat 依赖 (ALRA + MERINGUE)
# 生成镜像: r-bio:R-8
# -----------------------------------------------------------------------------
FROM R-7 AS R-8

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 安装 ALRA + MERINGUE (SpatialCellChat 依赖)
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
devtools::install_github('KlugerLab/ALRA'); \
remotes::install_github('JEFworks-Lab/MERINGUE', build_vignettes = TRUE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-9: 细胞通讯包 (GitHub)
# 生成镜像: r-bio:R-9
# -----------------------------------------------------------------------------
FROM R-8 AS R-9

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# CellChat (依赖 ComplexHeatmap)
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('jinworks/CellChat') \
" && \
    rm -rf /root/.cache/R /tmp/*

# celltalker
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('CilloLaboratory/celltalker') \
" && \
    rm -rf /root/.cache/R /tmp/*

# SpatialCellChat (依赖 CellChat + ALRA + MERINGUE)
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('jinworks/SpatialCellChat') \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-10: 轨迹分析包 (Bioconductor)
# 生成镜像: r-bio:R-10
# -----------------------------------------------------------------------------
FROM R-9 AS R-10

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 安装轨迹分析包
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install(c('monocle', 'slingshot', 'tradeSeq'), update = FALSE, ask = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-11: GitHub 包 - MAST, Nebulosa
# 生成镜像: r-bio:R-11
# -----------------------------------------------------------------------------
FROM R-10 AS R-11

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# MAST
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('RGLab/MAST') \
" && \
    rm -rf /root/.cache/R /tmp/*

# Nebulosa
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('powellgenomicslab/Nebulosa') \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-12: harmony + scDblFinder
# 生成镜像: r-bio:R-12
# -----------------------------------------------------------------------------
FROM R-11 AS R-12

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# harmony (CRAN)
RUN Rscript -e " \
options(repos = c(CRAN = Sys.getenv('CRAN_URL'))); \
install.packages(c('harmony'), Ncpus = 4) \
" && \
    rm -rf /root/.cache/R /tmp/*

# scDblFinder (Bioconductor)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install('scDblFinder', ask = FALSE, update = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-13: 需要编译的包 (BPCells, monocle3)
# 生成镜像: r-bio:R-13
# -----------------------------------------------------------------------------
FROM R-12 AS R-13

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 安装 grr (从 CRAN Archive，monocle3 依赖)
RUN cd /tmp && \
    curl -o grr_0.9.5.tar.gz https://cran.r-project.org/src/contrib/Archive/grr/grr_0.9.5.tar.gz && \
    R CMD INSTALL grr_0.9.5.tar.gz && \
    rm -f grr_0.9.5.tar.gz

# BPCells (需要编译，耗时长)
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
remotes::install_github('bnprks/BPCells/r') \
" && \
    rm -rf /root/.cache/R /tmp/*

# batchelor (monocle3 依赖)
RUN Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install('batchelor', update = FALSE, ask = FALSE) \
" && \
    rm -rf /root/.cache/R /tmp/*

# monocle3 (需要代理访问 GitHub)
RUN echo -e "\033[1;32m[Stage] Installing monocle3\033[0m" && \
    export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(repos = c(cran = Sys.getenv('CRAN_URL')), download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools'); \
devtools::install_github('cole-trapnell-lab/monocle3', upgrade = 'never') \
" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-14: 可选包 (允许失败)
# 生成镜像: r-bio:R-14
# -----------------------------------------------------------------------------
FROM R-13 AS R-14

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# scde (Bioconductor 包名是小写)
RUN (Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
BiocManager::install('scde', ask = FALSE, update = FALSE) \
" && rm -rf /root/.cache/R /tmp/*) || \
    echo "[WARNING] scde installation failed, skipping..."

# Rsubread (需要编译) - 允许失败
RUN (Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install('Rsubread', ask = FALSE, update = FALSE) \
" && rm -rf /root/.cache/R /tmp/*) || \
    echo "[WARNING] Rsubread installation failed, skipping..."

# flowCore (需要编译)
RUN (Rscript -e " \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager'); \
BiocManager::install('flowCore', ask = FALSE, update = FALSE) \
" && rm -rf /root/.cache/R /tmp/*) || \
    echo "[WARNING] flowCore installation failed, skipping..."

# Seurat 扩展包：seurat-disk, seurat-data, seurat-wrappers
RUN export http_proxy=${GITHUB_PROXY} && export https_proxy=${GITHUB_PROXY} && \
    Rscript -e " \
options(repos = c(cran = Sys.getenv('CRAN_URL')), download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools'); \
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes'); \
install.packages(c('dendsort', 'drat', 'fastcluster', 'urltools', 'RMTstat', 'Rook'), repos = c(cran = Sys.getenv('CRAN_URL')), Ncpus = 4); \
devtools::install_github('kharchenkolab/N2R', upgrade = FALSE, dependencies = TRUE); \
devtools::install_github('kharchenkolab/pagoda2', upgrade = FALSE, dependencies = TRUE); \
remotes::install_github('mojaveazure/seurat-disk', upgrade = TRUE); \
devtools::install_github('satijalab/seurat-data', upgrade = TRUE); \
remotes::install_github('satijalab/seurat-wrappers', upgrade = TRUE); \
remotes::install_github('mianaz/srtdisk@v0.3.1', upgrade = FALSE, dependencies = TRUE); \
BiocManager::install('FlowSOM', ask = FALSE, update = FALSE); \
BiocManager::install('diffcyt', ask = FALSE, update = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

# HDF5 LZF 插件 (Azimuth 依赖) 使用 pip 安装 h5py 替代手动编译
RUN echo -e "\033[1;32m[Stage 2] Installing h5py with LZF support\033[0m" && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir h5py && \
    mkdir -p /lzf && \
    echo "h5py installed, LZF support via h5py"

# Azimuth 用于单细胞数据注释和整合
RUN echo -e "\033[1;32m[Stage 3] Installing Azimuth\033[0m" && \
    Rscript -e "\
options(repos = c(cran = Sys.getenv('CRAN_URL')), download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
options(BioC_mirror = Sys.getenv('BIOC_URL')); \
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools'); \
devtools::install_github('satijalab/azimuth'); \
devtools::install_version('plogr', version = '0.2.0', repos = c(cran = Sys.getenv('CRAN_URL')))" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 2-15: 最终镜像
# 生成镜像: r-bio:R
# -----------------------------------------------------------------------------
FROM R-14 AS R-final

# 重新声明 ARG
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 配置 reticulate
RUN Rscript -e " \
reticulate::use_python('/opt/venv/bin/python', required = TRUE); \
reticulate::py_config(); \
"

# 复制验证脚本并执行
# COPY Rbio_verify.R /tmp/Rbio_verify.R
# RUN Rscript /tmp/Rbio_verify.R && rm -f /tmp/Rbio_verify.R

# 设置默认工作目录
WORKDIR /data

# 默认命令
CMD ["R"]