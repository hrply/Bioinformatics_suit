#!/bin/bash
# Stage 2: 预编译 R 包安装
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage2_prebuilt_r.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 2: 预编译 R 包安装
#========================================
install_prebuilt_r_packages() {
    log_stage "[Stage 2] 安装预编译 R 包"

    # 批次1: 核心依赖（必须先安装）
    log_info "Installing core packages (batch 1/4)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-rlang r-cli r-glue r-magrittr \
        || log_warn "核心包安装失败"

    # 批次2: 网络/编译依赖重的包
    log_info "Installing network and compilation packages (batch 2/4)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-rcpp r-curl r-openssl r-sys r-askpass \
        r-jsonlite r-mime r-httr \
        r-stringi r-xml2 r-rcurl \
        || log_warn "部分网络包安装失败"
    
    # 批次2b: pak/remotes/devtools 包管理器（提前安装，后续包安装需要）
    log_info "Installing pak/remotes/devtools package managers (batch 2b/4)"
    
    # pak 安装（优先 conda 预编译版本，避免编译依赖问题）
    # 注意: pak 从源码编译会因 cli/progress.h 头文件冲突失败
    if ! mamba install -y -c conda-forge --freeze-installed r-base=4.4.3 r-pak 2>/dev/null; then
        log_warn "pak conda 安装失败，尝试从 CRAN 安装..."
        Rscript -e "options(timeout=300); install.packages('pak', repos='${CRAN_MIRROR:-https://cloud.r-project.org}')" \
            || log_warn "pak 安装失败，将使用 remotes 代替"
    fi
    
    # remotes 安装（ggrepel、GitHub包安装需要）
    # 优先从 CRAN 安装，失败则使用 conda 预编译版本
    log_info "Installing remotes (required for ggrepel and GitHub packages)"
    if ! Rscript -e "install.packages('remotes', repos='${CRAN_MIRROR:-https://cloud.r-project.org}')" 2>/dev/null; then
        log_warn "remotes CRAN 安装失败，尝试 conda 预编译版本..."
        mamba install -y -c conda-forge --freeze-installed r-base=4.4.3 r-remotes \
            || log_warn "remotes conda 安装也失败"
    fi
    
    # devtools 安装（GitHub包安装需要）
    # 优先从 CRAN 安装，失败则使用 conda 预编译版本
    log_info "Installing devtools (required for GitHub package installation)"
    if ! Rscript -e "install.packages('devtools', repos='${CRAN_MIRROR:-https://cloud.r-project.org}')" 2>/dev/null; then
        log_warn "devtools CRAN 安装失败，尝试 conda 预编译版本..."
        mamba install -y -c conda-forge --freeze-installed r-base=4.4.3 r-devtools \
            || log_warn "devtools conda 安装也失败"
    fi
    
    # 验证 remotes 和 devtools 是否可用
    Rscript -e "
if (requireNamespace('remotes', quietly = TRUE)) cat('remotes OK\n') else cat('remotes MISSING\n')
if (requireNamespace('devtools', quietly = TRUE)) cat('devtools OK\n') else cat('devtools MISSING\n')
" 2>/dev/null || log_warn "remotes/devtools 验证失败"
    
    # 批次3: 复杂 C++ 编译包（CRAN 源码编译容易失败）
    # 注意: igraph 编译需要内部头文件，必须使用 conda 预编译版本
    log_info "Installing complex C++ packages (batch 3/4)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-yaml r-igraph r-rcpparmadillo \
        || log_warn "部分 C++ 包安装失败"
    
    # 验证 igraph 是否安装成功（编译需要 igraph_centrality.h）
    if ! Rscript -e "library(igraph, quietly=TRUE)" 2>/dev/null; then
        log_warn "igraph conda 安装失败，尝试从 CRAN 安装..."
        Rscript -e "install.packages('igraph', repos='${CRAN_MIRROR:-https://cloud.r-project.org}')" \
            || log_warn "igraph 安装失败，后续包可能受影响"
    fi
    
    # 批次4: 需要系统库的包（拆分为多个小批次，按依赖顺序安装）

    # 批次4a: 基础工具包（无复杂依赖）
    # 注意: vroom 编译需要 mio 库，必须使用 conda 预编译版本
    log_info "Installing base tool packages (batch 4a/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-rann r-xml r-rcppparallel r-fastmap r-sourcetools r-commonmark r-fs r-zoo \
        r-sitmo r-kernsmooth r-arrow r-vroom r-rsqlite r-sctransform \
        || log_warn "批次4a部分包安装失败"
    
    # 验证 vroom 是否安装成功（编译需要 mio 库）
    if ! Rscript -e "library(vroom, quietly=TRUE)" 2>/dev/null; then
        log_warn "vroom conda 安装失败，尝试从 CRAN 安装（可能需要 mio 库）..."
        Rscript -e "install.packages('vroom', repos='${CRAN_MIRROR:-https://cloud.r-project.org}')" \
            || log_warn "vroom 安装失败，后续包可能受影响"
    fi

    # 批次4b: Rcpp 相关包（依赖 sitmo）
    # 注意: dqrng 编译需要 mystdint.h，必须使用 conda 预编译版本
    log_info "Installing Rcpp-related packages (batch 4b/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-rcppannoy r-rcpphnsw r-zigg r-wk r-cairo \
        r-dqrng r-rspectra \
        || log_warn "批次4b部分包安装失败"
    
    # 验证 dqrng 是否安装成功
    if ! Rscript -e "library(dqrng, quietly=TRUE)" 2>/dev/null; then
        log_warn "dqrng conda 安装失败，尝试从 CRAN 安装..."
        Rscript -e "install.packages('dqrng', repos='${CRAN_MIRROR:-https://cloud.r-project.org}')" \
            || log_warn "dqrng 安装失败，后续包可能受影响"
    fi

    # 批次4c: 系统字体/测试/样式包
    log_info "Installing system fonts/test/sass packages (batch 4c/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-systemfonts r-testthat r-sass r-nloptr \
        || log_warn "批次4c部分包安装失败"

    # 批次4d: 网络/图像/Git 包
    log_info "Installing network/image/git packages (batch 4d/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-httpuv r-png r-gert \
        || log_warn "批次4d部分包安装失败"

    # 批次4e-pre: 修复 bioconda 数据包下载问题
    log_info "Patching installBiocDataPackage.sh to skip existing packages"
    installer_script="${CONDA_PREFIX}/bin/installBiocDataPackage.sh"
    if [ -f "$installer_script" ]; then
        cp "$installer_script" "${installer_script}.bak"
        
        sed -i '/^set -ex$/a\
# Check if package already exists in R library\
PKG_NAME=$(echo "$1" | sed "s/-[0-9].*//" | sed "s/\\(\\.\\)\\([0-9]\\)/\\u\\2/g" | sed "s/\\(^.\\)/\\u\\1/")\
if Rscript -e "library($PKG_NAME, quietly=TRUE)" 2>/dev/null; then\
  echo "Package $PKG_NAME already installed, skipping download"\
  exit 0\
fi' "$installer_script"
        
        log_info "installBiocDataPackage.sh 已修补"
    else
        log_warn "未找到 installBiocDataPackage.sh，跳过修补"
    fi
    
    # 预安装 GenomeInfoDbData（从镜像下载，避免 bioconda 从官网下载）
    log_info "Pre-installing GenomeInfoDbData via BiocManager (use mirror)"
    bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    Rscript -e "
options(repos = c(cran = '${CRAN_MIRROR:-https://cloud.r-project.org}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', upgrade = FALSE);
BiocManager::install('GenomeInfoDbData', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/data/annotation');
cat('GenomeInfoDbData pre-installed\n');
" 2>/dev/null || log_warn "GenomeInfoDbData 预安装失败"
    
    # 批次4e: Bioconductor 包（使用 mamba 加速依赖解析）
    # 注意: BiocParallel 编译需要 boost interprocess，rhdf5 需要 HDF5 库兼容
    log_info "Installing Bioconductor packages (batch 4e/7)"
    if command -v mamba &> /dev/null; then
        mamba install -y -c conda-forge -c bioconda \
            bioconductor-rprotobuflib=2.18.0 \
            bioconductor-rhdf5=2.50.0 \
            bioconductor-rhtslib=3.2.0 \
            bioconductor-biocparallel=1.40.0 \
            bioconductor-beachmat=2.22.0 \
            bioconductor-biocneighbors=2.0.0 \
            bioconductor-scuttle=1.16.0 \
            bioconductor-hdf5array=1.34.0 \
            bioconductor-rsamtools=2.22.0 \
            bioconductor-genomicalignments=1.42.0 \
            bioconductor-glmgampoi=1.18.0 \
            bioconductor-rtracklayer=1.66.0 \
            || log_warn "批次4e部分包安装失败"
    else
        mamba install -y -c conda-forge -c bioconda \
            bioconductor-rprotobuflib=2.18.0 \
            bioconductor-rhdf5=2.50.0 \
            bioconductor-rhtslib=3.2.0 \
            bioconductor-biocparallel=1.40.0 \
            bioconductor-beachmat=2.22.0 \
            bioconductor-biocneighbors=2.0.0 \
            bioconductor-scuttle=1.16.0 \
            bioconductor-hdf5array=1.34.0 \
            bioconductor-rsamtools=2.22.0 \
            bioconductor-genomicalignments=1.42.0 \
            bioconductor-glmgampoi=1.18.0 \
            bioconductor-rtracklayer=1.66.0 \
            || log_warn "批次4e部分包安装失败"
    fi
    
    # 验证 BiocParallel 是否安装成功（编译需要 boost interprocess）
    if ! Rscript -e "library(BiocParallel, quietly=TRUE)" 2>/dev/null; then
        log_warn "BiocParallel conda 安装失败，尝试从 BiocManager 安装..."
        bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
        Rscript -e "
options(repos = c(cran = '${CRAN_MIRROR:-https://cloud.r-project.org}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install('BiocParallel', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');
" || log_warn "BiocParallel 安装失败，后续包可能受影响"
    fi
    
    # 验证 rhdf5 是否安装成功（链接需要 HDF5 库符号兼容）
    if ! Rscript -e "library(rhdf5, quietly=TRUE)" 2>/dev/null; then
        log_warn "rhdf5 conda 安装失败，尝试从 BiocManager 安装..."
        bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
        Rscript -e "
options(repos = c(cran = '${CRAN_MIRROR:-https://cloud.r-project.org}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install('rhdf5', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');
" || log_warn "rhdf5 安装失败，后续包可能受影响"
    fi

    # 批次4f: 统计相关包（mnormt 在前，mvtnorm 依赖它）
    log_info "Installing statistics packages (batch 4f/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-mnormt r-quantreg r-polyclip \
        || log_warn "批次4f部分包安装失败"

    # 批次4g: 多元统计包（依赖 mnormt）
    log_info "Installing multivariate statistics packages (batch 4g/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-mvtnorm r-qqconf \
        || log_warn "批次4g部分包安装失败"

    # 批次4h: Seurat 依赖包（预编译版本，避免 CRAN 编译失败）
    log_info "Installing Seurat dependency packages (batch 4h/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-textshaping r-ragg r-units r-sf r-s2 \
        r-uwot r-rcppannoy r-rann \
        || log_warn "批次4h部分包安装失败"

    # 批次4i: Rfast 和其他数学包 + testthat
    log_info "Installing Rfast, testthat and math packages (batch 4i/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-rfast r-testthat r-rnanoflann r-mutoss r-metap \
        || log_warn "批次4i部分包安装失败"
    
    # 批次4j: microbenchmark（预编译版本，CRAN 编译会失败）
    log_info "Installing microbenchmark (batch 4j/7)"
    mamba install -y -c conda-forge --freeze-installed r-base=4.4.3 r-microbenchmark \
        || log_warn "r-microbenchmark 安装失败"
    
    # 批次4k: uuid 和 hdf5r（预编译版本，CRAN 编译会失败）
    log_info "Installing uuid and hdf5r (batch 4k/7)"
    mamba install -y -c conda-forge r-uuid r-hdf5r \
        || log_warn "批次4k部分包安装失败"
    
    # 批次4l: 图像/地理空间包（预编译版本，CRAN 编译会因库链接失败）
    log_info "Installing image/geospatial packages (batch 4l/7)"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        r-jpeg r-fields r-raster r-exactextractr \
        || log_warn "批次4l部分包安装失败"
    
    # 验证关键包
    log_info "Verifying critical packages..."
    local missing=""
    for pkg in cli jsonlite curl httr stringi yaml igraph RANN XML; do
        if ! Rscript -e "library($pkg, quietly=TRUE)" 2>/dev/null; then
            missing="$missing $pkg"
        fi
    done
    if [ -n "$missing" ]; then
        log_warn "缺失关键包:$missing - 将尝试从 CRAN 安装"
    else
        log_info "所有关键 R 包已通过 conda 安装"
    fi
    
    # 强制锁定 R 版本
    log_info "强制锁定 R 版本到 4.4.3（Bioconductor 3.20 需要 R 4.4）"
    mamba install -y -c conda-forge r-base=4.4.3 || log_warn "r-base 4.4.3 安装失败，可能影响后续 Bioconductor 安装"
    
    log_stage_complete "Stage 2: 预编译 R 包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 2: 预编译 R 包安装"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_prebuilt_r_packages
    log_info "Stage 2 完成！可以继续执行 Stage 3"
}

main "$@"

