# =============================================================================
# Rbio_update.dockerfile - 用于已构建后少量更新包内软件，大量更新推荐重新构建
# =============================================================================
# 用法:
#   CPU: nohup docker build -f Rbio_update.dockerfile --build-arg BASE_IMAGE=rbio:cpu -t rbio:cpu-v2 . > update.log 2>&1 &
#   GPU: nohup docker build -f Rbio_update.dockerfile --build-arg BASE_IMAGE=rbio:gpu -t rbio:gpu-v2 . > update.log 2>&1 &
#   注意GITHUB_TOKE需要补全为toke，因为git设置避免toke泄露会被禁止上传
# =============================================================================

ARG BASE_IMAGE=rbio:gpu
FROM ${BASE_IMAGE}

ARG CRAN_URL=https://mirrors.tuna.tsinghua.edu.cn/CRAN
ARG GITHUB_PROXY=http://192.168.3.147:7890
#注意补全toke，因为git设置避免toke泄露会被禁止上传
ENV GITHUB_TOKE=your_token

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
        "miloR", \
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
    token <- Sys.getenv("GITHUB_TOKEN"); \
    print(paste("Using GitHub token:", token)); \
    if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes"); \
    if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager"); \
    remotes::install_github("mianaz/srtdisk", upgrade = FALSE, dependencies = TRUE)'

RUN . /opt/venv/bin/activate && \
    # 锁定numpy numba和pandas避免RAPIDS环境损坏 \
    CUR_NUMPY=$(pip show numpy | grep "^Version:" | awk '{print $2}') && \
    CUR_PANDAS=$(pip show pandas | grep "^Version:" | awk '{print $2}') && \
    CUR_NUMBA=$(pip show numba | grep "^Version:" | awk '{print $2}') && \
    echo "==================================================" && \
    echo "🔒 锁定版本: Numpy=${CUR_NUMPY}, Pandas=${CUR_PANDAS}, Numba=${CUR_NUMBA}" && \
    echo "==================================================" && \
    \
    pip install --no-cache-dir \
    "numpy==${CUR_NUMPY}" "pandas==${CUR_PANDAS}" "numba==${CUR_NUMBA}" \
    celldex \
    biocpy \
    pyreadr \
    pytometry \
    scyan \
    scarf \
    openTSNE

# 清理缓存以减小镜像体积
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /var/lib/apt/lists/*
ENV GITHUB_TOKE=