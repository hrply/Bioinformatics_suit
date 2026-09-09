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
ARG GITHUB_TOKEN=your_token

# 更新 R 包 (非github 包)
RUN Rscript -e '\
    options(repos = c(CRAN = Sys.getenv("CRAN_URL"))); \
    options(BioC_mirror = Sys.getenv("BIOC_URL")); \
    if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes"); \
    if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager"); \
    BiocManager::install(c( \
        "xxx", \
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
    remotes::install_github(" ", upgrade = FALSE, dependencies = TRUE)'

RUN . /opt/venv/bin/activate && \
    # 锁定numpy numba pandas避免RAPIDS环境损坏 \
    # 锁定torch全家桶避免pip回溯下载标准版替换cu130 \
    CORE_PKGS="numpy pandas numba torch torchaudio torchvision torch-geometric rpy2 scvi-tools zarr dask distributed spatialdata tifffile numcodecs" && \
    LOCK_STR="" && \
    for pkg in $CORE_PKGS; do \
        VER=$(pip show $pkg 2>/dev/null | grep "^Version:" | awk '{print $2}'); \
        [ -n "$VER" ] && LOCK_STR="$LOCK_STR $pkg==$VER"; \
    done && \
    echo "==================================================" && \
    echo "🔒 锁定核心版本:$LOCK_STR" && \
    echo "==================================================" && \
    uv pip install --no-cache $LOCK_STR \
    xxx

# 清理缓存以减小镜像体积
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /var/lib/apt/lists/*