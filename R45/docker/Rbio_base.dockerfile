# =============================================================================
# Stage 1: Rbio_base - 多阶段构建
# Base: rocker/geospatial:4.5.2 (R 4.5.2 with geospatial dependencies pre-installed)
# Purpose: 安装基础R包和Bioconductor包，分层构建生成多个中间镜像
# =============================================================================

# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# Stage 1a: 系统依赖 + R包管理器
# 生成镜像: r-bio:base-sys
# -----------------------------------------------------------------------------
FROM docker.io/rocker/geospatial:4.5.2 AS base-sys

# Build Arguments
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN

# 根据 mirror 参数设置镜像源 ARG
ARG CRAN_URL=${mirror:+https://mirrors.tuna.tsinghua.edu.cn/CRAN}
ARG CRAN_URL=${CRAN_URL:-https://cloud.r-project.org}
ARG BIOC_URL=${mirror:+https://mirrors.tuna.tsinghua.edu.cn/bioconductor}
ARG BIOC_URL=${BIOC_URL:-https://bioconductor.org}

# Environment Variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Etc/UTC"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV R_PKG_INSTALL_ARGS="--no-html"
ENV R_VERSION=4.5.2
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}

# 设置全局代理（如果传入 http_proxy）
ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 设置 apt 国内镜像 (如果是 china 模式，或设置了 APT_MIRROR 环境变量)
ARG APT_MIRROR
ENV APT_MIRROR=${APT_MIRROR:-}
RUN if [ "${mirror}" = "china" ] || [ "${mirror}" = "China" ] || [ -n "${APT_MIRROR}" ]; then \
        APT_MIRROR_URL="${APT_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu}"; \
        if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
            sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list.d/ubuntu.sources && \
            sed -i "s|http://security.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list.d/ubuntu.sources; \
        elif [ -f /etc/apt/sources.list ]; then \
            sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list && \
            sed -i "s|http://security.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list; \
        fi; \
    fi

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake curl wget git libtool pkg-config \
    libcurl4-openssl-dev libssl-dev libxml2-dev libbz2-dev liblzma-dev \
    zlib1g-dev libhdf5-dev libglpk-dev libgit2-dev \
    libfftw3-dev libgdal-dev libgeos-dev libproj-dev \
    libpng-dev libjpeg-dev libtiff-dev libfreetype6-dev \
    libgmp-dev libmpfr-dev libgfortran5 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 验证 R 版本
RUN R --version

# 创建 R 配置目录
RUN mkdir -p /usr/local/lib/R/etc

# 写入 Rprofile.site (使用环境变量，运行时动态读取)
RUN echo 'local({' > /usr/local/lib/R/etc/Rprofile.site && \
    echo '  cran_url <- Sys.getenv("CRAN_URL", "https://cloud.r-project.org")' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo '  bioc_url <- Sys.getenv("BIOC_URL", "https://bioconductor.org")' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo '  options(repos = c(CRAN = cran_url))' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo '  options(BioC_mirror = bioc_url)' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo '})' >> /usr/local/lib/R/etc/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))' >> /usr/local/lib/R/etc/Rprofile.site

# 安装 R 包管理器 (pak, devtools, remotes)
# 如果设置了 GITHUB_PROXY，则使用代理下载 pak
RUN if [ -n "${GITHUB_PROXY}" ]; then \
        export http_proxy=${GITHUB_PROXY} && \
        export https_proxy=${GITHUB_PROXY}; \
    fi && \
    Rscript -e "install.packages('pak', repos = 'https://r-lib.github.io/p/pak/stable/')" && \
    Rscript -e "install.packages(c('devtools', 'remotes'), repos = '${CRAN_URL}')" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 1b: CRAN核心包
# 生成镜像: r-bio:base-cran
# -----------------------------------------------------------------------------
FROM base-sys AS base-cran

# 重新声明 ARG（多阶段构建需要）
ARG CRAN_URL
ARG BIOC_URL
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}

# 核心 CRAN 包 - 数据处理和可视化
# 注意：tidyverse核心包、ggplot2、RColorBrewer、rmarkdown已由基础镜像预装
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    # 数据处理 (tidyverse核心已由基础镜像预装)
    'data.table', 'reshape2', 'plyr', 'tidymodels', \
    # 可视化 (ggplot2, RColorBrewer已由基础镜像预装)
    'cowplot', 'patchwork', 'ggridges', 'ggrepel', \
    'gridExtra', 'gtable', 'viridisLite', 'viridis', \
    'ggplotify', 'ggpubr', 'ggthemes', 'plotly', 'htmlwidgets', \
    # 统计
    'MASS', 'Matrix', 'lattice', 'survival', 'boot', 'cluster', 'KernSmooth', \
    'broom', 'modelr', 'car', 'multcomp', 'emmeans', 'effectsize', 'performance', \
    # 工具
    'rlang', 'vctrs', 'magrittr', 'glue', 'cli', 'crayon', 'tidyselect', \
    'withr', 'fs', 'rappdirs', 'rprojroot', 'desc', 'pkgbuild', 'pkgload', \
    # 其他 (rmarkdown, knitr已由基础镜像预装)
    'evaluate', 'highr', 'xfun', 'yaml', \
    'httr', 'httr2', 'curl', 'jsonlite', 'xml2', 'rvest', 'openxlsx', \
    'progress', 'progressr', 'logging', 'futile.logger', 'futile.options', \
    'lambda.r', 'snow', 'parallelly', 'future', 'future.apply', 'listenv' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 1c: Bioconductor基础包
# 生成镜像: r-bio:base-bioc
# -----------------------------------------------------------------------------
FROM base-cran AS base-bioc

# 重新声明 ARG（多阶段构建需要）
ARG CRAN_URL
ARG BIOC_URL
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}

# Bioconductor 基础基础设施
# 注意：BiocManager已由基础镜像预装
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    # Bioconductor 基础 (BiocManager已由基础镜像预装)
    'BiocVersion', 'BiocBaseUtils', \
    'Biobase', 'BiocGenerics', 'BiocParallel', 'BiocStyle', 'biocViews', \
    # S4 系统
    'S4Vectors', 'IRanges', 'XVector', 'GenomicRanges', 'GenomeInfoDb', \
    'GenomicAlignments', 'SummarizedExperiment', 'SingleCellExperiment', \
    'MatrixGenerics', 'DelayedArray', 'DelayedMatrixStats', \
    # 数据结构
    'SparseArray', 'S4Arrays', 'abind', 'pillar', 'vroom', 'bit64', \
    # HDF5 支持
    'rhdf5', 'rhdf5filters', 'Rhdf5lib', 'HDF5Array', \
    # 数据导入/导出
    'AnnotationDbi', 'annotate', 'BiocIO', 'rtracklayer', 'Rsamtools', \
    # 工具
    'KEGGREST', 'SQUAREM', 'Rcpp', 'RcppArmadillo', 'RcppEigen', \
    'testthat', 'assertthat', 'checkmate', 'RUnit' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# Stage 1d: 统计和机器学习基础 + Seurat前置依赖
# 生成镜像: r-bio:base-ml
# -----------------------------------------------------------------------------
FROM base-bioc AS base-ml
ARG CRAN_URL
ARG BIOC_URL
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}

# 分批安装避免 pak 依赖解析问题

# 批次 1: 矩阵运算和降维
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'irlba', 'RSpectra', 'spam', 'dotCall64', 'Rtsne', 'uwot', 'FNN', 'RANN' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 2: 聚类和统计
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'cluster', 'mclust', 'Rfast', 'Rfast2', 'RcppZiggurat', \
    'glmnet', 'caret', 'lme4', 'nlme' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 3: 生存分析和ML工具
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'survival', 'survminer', 'survMisc', 'recipes', 'rsample', \
    'tune', 'workflows', 'parsnip', 'yardstick' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 4: Rcpp 生态
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'Rcpp', 'RcppEigen', 'RcppArmadillo', 'RcppProgress', 'RcppAnnoy', \
    'RcppHNSW', 'RcppRoll', 'spam64' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 5: 生信专用
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'vegan', 'permute', 'ade4', 'ape', 'phangorn', 'phytools' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 6: spatstat 系列
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'spatstat.data', 'spatstat.geom', 'spatstat.random', 'spatstat.explore', \
    'spatstat.model', 'spatstat.utils', 'spatstat.sparse', 'spatstat' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 7: 图形和网络
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'igraph', 'leiden', 'clustree', 'ggraph', 'tidygraph', 'graphlayouts' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 8: 并行计算
# 注意：snow, parallelly, future, future.apply, listenv 已由基础镜像预装
RUN Rscript -e "\
options(repos = c(CRAN = Sys.getenv('CRAN_URL'), Bioconductor = Sys.getenv('BIOC_URL'))); \
pak::pkg_install(c( \
    'pbapply', 'pbmcapply' \
), upgrade = TRUE)" && \
    rm -rf /root/.cache/R /tmp/*

# 批次 9: 空间分析
# 注意：sp, sf, raster, terra, stars, spdep, spatialreg 已由基础镜像 rocker/geospatial 预装
# 传统空间包（rgdal, rgeos, maptools, maps, mapproj）也已预装，但已弃用
# 现代空间分析使用 sf 和 terra 替代

# -----------------------------------------------------------------------------
# Stage 1e: 最终镜像 - 用户配置
# 生成镜像: r-bio:base
# -----------------------------------------------------------------------------
FROM base-ml AS base-final
ARG CRAN_URL
ARG BIOC_URL
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}

# 创建 rstudio 用户（如果已存在则跳过）
RUN id rstudio &>/dev/null || useradd -m -s /bin/bash rstudio && \
    echo "rstudio:rstudio" | chpasswd && \
    mkdir -p /home/rstudio && \
    chown -R rstudio:rstudio /home/rstudio

WORKDIR /home/rstudio

CMD ["R"]
