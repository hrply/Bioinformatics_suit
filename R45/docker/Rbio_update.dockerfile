# =============================================================================
# Rbio_update.dockerfile - 用于已构建后少量更新包内软件，大量更新推荐重新构建
# =============================================================================
# 用法:
#   CPU: nohup docker build -f Rbio_update.dockerfile --build-arg BASE_IMAGE=rbio:cpu --build-arg GITHUB_TOKEN=your_token -t rbio:cpu-v2 . > update.log 2>&1 &
#   GPU: nohup docker build -f Rbio_update.dockerfile --build-arg BASE_IMAGE=rbio:gpu --build-arg GITHUB_TOKEN=your_token -t rbio:gpu-v2 . > update.log 2>&1 &
# =============================================================================

ARG BASE_IMAGE=rbio:gpu
FROM ${BASE_IMAGE}

ARG CRAN_URL=https://mirrors.tuna.tsinghua.edu.cn/CRAN
ARG GITHUB_PROXY=http://192.168.3.147:7890

# 更新 R 包 (非github 包)
RUN Rscript -e '\
    options(repos = c(CRAN = Sys.getenv("CRAN_URL"))); \
    options(BioC_mirror = Sys.getenv("BIOC_URL")); \
    if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes"); \
    if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager"); \
    BiocManager::install(c( \
        "diffcyt", \
        "flowCore", \
        "flowViz", \
        "ConsensusClusterPlus", \
        "zellkonverter", \
        "CytoGLMM", \
        "CATALYST", \
        "drc", \
        "nnls", \
        "plotrix" \
    ), ask = FALSE, update = FALSE)'

# 更新 R 包 (github 包)
RUN Rscript -e '\
    gh_proxy <- Sys.getenv("GITHUB_PROXY"); \
    if (nzchar(gh_proxy)) { \
        options(download.file.method = "curl", download.file.extra = paste0("--proxy ", gh_proxy)) \
    }; \
    options(repos = c(CRAN = Sys.getenv("CRAN_URL"))); \
    options(BioC_mirror = Sys.getenv("BIOC_URL")); \
    if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes"); \
    if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager"); \
    remotes::install_github("mianaz/srtdisk", upgrade = FALSE, dependencies = TRUE)'

# 更新 Python 包
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    celldex \
    biocpy \
    pytometry \
    scyan \
    pyFlowSOM \
    milopy \
    scarf \
    openTSNE \
    pyreadr

# 清理缓存以减小镜像体积
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /var/lib/apt/lists/*