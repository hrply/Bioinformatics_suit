# =============================================================================
# Rbio_update.dockerfile - 用于已构建后少量更新包内软件，大量更新推荐重新构建
# =============================================================================
# 用法:
#   CPU: docker build -f Rbio_update.dockerfile --build-arg BASE_IMAGE=rbio:cpu -t rbio:cpu-v2 .
#   GPU: docker build -f Rbio_update.dockerfile --build-arg BASE_IMAGE=rbio:gpu -t rbio:gpu-v2 .
# =============================================================================

ARG BASE_IMAGE=rbio:gpu
FROM ${BASE_IMAGE}

ARG CRAN_URL=https://mirrors.tuna.tsinghua.edu.cn/CRAN
ARG GITHUB_PROXY=http://192.168.3.147:7890

# 更新 srtdisk
RUN Rscript -e " \
    options(repos = c(cran = Sys.getenv('CRAN_URL')), download.file.method = 'curl', download.file.extra = paste0('--proxy ', Sys.getenv('GITHUB_PROXY'))); \
    options(BioC_mirror = Sys.getenv('BIOC_URL')); \
    remotes::install_github('mianaz/srtdisk', upgrade = FALSE, dependencies = TRUE)" \
    && rm -rf /root/.cache/R /tmp/*