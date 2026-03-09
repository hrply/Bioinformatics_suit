#!/bin/bash
# Stage 6: Giotto 安装 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate bio
#   ./Rbio_stage6.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 6: Giotto
#========================================
install_giotto() {
    log_stage "[Stage 6] 安装 Giotto"
    
    local cran_url="${CRAN_MIRROR:-https://cloud.r-project.org}"
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    
    # Step 1: 先通过 conda 安装预编译依赖包
    log_info "Installing Giotto dependencies via conda"
    mamba install -y -c conda-forge \
        r-units r-scattermore r-reshape2 r-geometry r-RTriangle \
        r-data.table r-matrix r-ggplot2 r-rann r-igraph r-fnn \
        r-irlba r-proxy r-rcpp r-rcppeigen r-rcpparmadillo r-rspectra \
        r-terra \
        || log_warn "部分conda依赖安装失败"
    
    # Step 2: 安装 bluster（Giotto 核心依赖）
    log_info "Installing bluster from Bioconductor (required for Giotto)"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install(version = '${BIOC_VERSION}', ask = FALSE, update = FALSE);
BiocManager::install('bluster', ask = FALSE, update = FALSE);
cat('bluster installed\n');
" || log_warn "bluster安装失败"
    
    # Step 3: 安装其他 CRAN 依赖
    log_info "Installing additional Giotto dependencies from CRAN"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
deps <- c('dplyr', 'tidyr', 'purrr', 'tibble', 'sp', 'sf', 'raster', 'stars');
for (pkg in deps) {
    tryCatch({
        if (!requireNamespace(pkg, quietly = TRUE)) {
            install.packages(pkg, dependencies = TRUE);
            cat(pkg, 'installed\n');
        }
    }, error = function(e) {
        cat(pkg, 'warning:', conditionMessage(e), '\n');
    });
}
" 2>/dev/null || log_warn "部分CRAN依赖安装失败"
    
    # Step 4: 安装 Giotto (带重试)
    log_info "Installing Giotto (with retry)"
    local giotto_success=false
    for i in 1 2 3; do
        log_info "Giotto attempt $i/3"
        Rscript -e "
options(repos = c(cran = '${cran_url}'));
Sys.setenv(http_proxy = '${http_proxy}', https_proxy = '${https_proxy}');
options(download.file.method = 'curl');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('drieslab/Giotto', upgrade = 'never');
" 2>&1 || true
        # 验证是否真正安装成功
        if Rscript -e "library(Giotto); cat('Giotto version:', as.character(packageVersion('Giotto')), '\n')" 2>/dev/null; then
            giotto_success=true
            log_info "Giotto installed successfully"
            break
        fi
        log_warn "Giotto attempt $i failed, retrying..."
        sleep 10
    done
    
    # 验证
    log_info "Verifying Giotto"
    if [ "$giotto_success" = true ]; then
        Rscript -e "library(Giotto); cat('Giotto version:', as.character(packageVersion('Giotto')), '\n')" \
            || log_warn "Giotto验证失败"
    else
        log_warn "Giotto安装失败"
    fi
    
    log_stage_complete "Stage 6: Giotto"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 6: Giotto 安装 (R 4.5.2 + Bioconductor 3.22)"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_giotto
    log_info "Stage 6 完成！可以继续执行 Stage 7"
}

main "$@"
