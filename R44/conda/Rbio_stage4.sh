#!/bin/bash
# Stage 4: R 包安装（其他R依赖包）
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage4_r_packages.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 4: R 包安装（其他R依赖包）
#========================================
install_r_packages() {
    log_stage "[Stage 4] 安装 R 包"
    
    local cran_url="${CRAN_MIRROR:-https://cloud.r-project.org}"
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    
    # pak 已在 Stage 2 提前安装
    
    log_info "Installing Bioconductor core packages"
    Rscript -e "
options(download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
options(repos = c(CRAN = '${cran_url}'));
BiocManager::install(version = '3.20', ask = FALSE, update = FALSE, 
    site_repository = '${bioc_url}/packages/3.20/bioc');
BiocManager::install(c('Biobase','BiocGenerics','DESeq2','DelayedArray',
    'GenomicRanges','GenomeInfoDb','glmGamPoi','IRanges','limma','MAST',
    'rtracklayer','S4Vectors','SingleCellExperiment',
    'SummarizedExperiment'), update = FALSE, ask = FALSE,
    site_repository = '${bioc_url}/packages/3.20/bioc')" \
        || { log_warn "部分Bioconductor包安装失败，继续..."; }
    
    log_info "Installing additional CRAN packages"
    Rscript -e "options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
install.packages(c(
    'dissimilarities','fastDummies','fitdistrplus','ggridges','ica','irlba',
    'lmtest','matrixStats','miniUI',
    'pbapply','plotly','progressr','RColorBrewer',
    'ROCR','Rtsne',
    'scattermore','shiny','spatstat.explore','spatstat.geom',
    'ape','base64enc','ggrastr','harmony',
    'metap','mixtools','rsvd','R.utils','sp','VGAM'
), upgrade = FALSE)" \
        || { log_warn "部分CRAN包安装失败，继续..."; }
    
    # enrichR 安装（需要先安装依赖 WriteXLS）
    log_info "Installing enrichR dependencies"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
install.packages('WriteXLS');
cat('WriteXLS installed\n');
" || log_warn "WriteXLS 安装失败"
    
    log_info "Installing enrichR"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(timeout = 120);
tryCatch({
    install.packages('enrichR');
    cat('enrichR installed\n');
}, error = function(e) {
    cat('enrichR installation warning:', conditionMessage(e), '\n');
});
" || log_warn "enrichR 安装失败（非关键包，部分功能可能受限）"
    
    # 验证 enrichR 安装（只检查包是否存在，不加载以避免网络超时）
    if Rscript -e "cat(if (requireNamespace('enrichR', quietly = TRUE)) '[OK] enrichR installed' else '[WARN] enrichR not installed', '\n')" 2>/dev/null; then
        log_info "enrichR 验证完成"
    fi
    
    # leidenbase 单独安装（CRAN 编译容易失败，尝试多种方式）
    log_info "Installing leidenbase"
    if ! Rscript -e "library(leidenbase)" 2>/dev/null; then
        # 方式1: 尝试 conda 安装
        mamba install -y -c conda-forge r-leidenbase 2>/dev/null || {
            # 方式2: 尝试 CRAN 安装
            Rscript -e "install.packages('leidenbase', repos='${cran_url}')" 2>/dev/null || {
                # 方式3: 尝试 GitHub 安装
                Rscript -e "devtools::install_github('cole-trapnell-lab/leidenbase', upgrade='never')" 2>/dev/null || {
                    log_warn "leidenbase安装失败（Seurat聚类功能可能受限）"
                }
            }
        }
    fi
    
    log_info "Installing ggrepel"
    Rscript -e "options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
remotes::install_version('ggrepel', version = '0.9.5', upgrade = FALSE)" \
        || { log_warn "ggrepel安装失败，继续..."; }
    
    # BPCells 安装（优先使用 bioconda 预编译版本）
    log_info "Installing BPCells (required for monocle3)"
    
    local bpcells_success=false
    
    # 方式1: 使用 bioconda 预编译版本（推荐）
    log_info "尝试从 bioconda 安装预编译 BPCells..."
    if command -v mamba &> /dev/null; then
        mamba install -y -c bioconda r-bpcells --channel-priority flexible 2>/dev/null && bpcells_success=true
    else
        mamba install -y -c bioconda r-bpcells --channel-priority flexible 2>/dev/null && bpcells_success=true
    fi
    
    # 验证 bioconda 版本
    if [ "$bpcells_success" = true ]; then
        if Rscript -e "library(BPCells); cat('BPCells 版本:', as.character(packageVersion('BPCells')), '\n')" 2>/dev/null; then
            log_info "BPCells (bioconda预编译版本) 安装成功"
        else
            log_warn "bioconda BPCells 加载失败，尝试备用方案..."
            bpcells_success=false
        fi
    fi
    
    # 方式2: 备用 - 从 GitHub 源码安装
    if [ "$bpcells_success" = false ]; then
        log_warn "bioconda预编译版本失败，尝试从 GitHub 源码安装..."
        Rscript -e "remotes::install_github('bnprks/BPCells/r', upgrade='never')" 2>/dev/null || {
            log_warn "BPCells GitHub安装失败"
        }
        
        if Rscript -e "library(BPCells)" 2>/dev/null; then
            bpcells_success=true
            log_info "BPCells (GitHub版本) 安装成功"
        fi
    fi
    
    if [ "$bpcells_success" = false ]; then
        log_error "BPCells 安装失败"; exit 1;
    fi
    
    log_info "Installing monocle3"
    cd /tmp
    wget -q https://cran.r-project.org/src/contrib/Archive/grr/grr_0.9.5.tar.gz
    R CMD INSTALL grr_0.9.5.tar.gz 2>/dev/null || log_warn "grr安装失败"
    rm -f grr_0.9.5.tar.gz 2>/dev/null
    
    # monocle3 安装（带重试，必要包）
    local monocle_success=false
    for i in 1 2 3; do
        log_info "monocle3 attempt $i/3"
        if Rscript -e "options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
options(Bioconductor.version = '3.20');
BiocManager::install(version = '3.20', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc', force = TRUE);
BiocManager::install(c('batchelor'), update = FALSE, ask = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('cole-trapnell-lab/monocle3', upgrade = 'never');
cat('monocle3 installed\n');
" 2>&1; then
            monocle_success=true
            break
        fi
        log_warn "monocle3 attempt $i failed, retrying..."
        sleep 5
    done
    [ "$monocle_success" = true ] || { log_error "monocle3安装失败（必要包）"; exit 1; }
    cd "$SCRIPT_DIR"
    
    log_stage_complete "Stage 4: R 包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 4: R 包安装（CRAN + Bioconductor）"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_r_packages
    log_info "Stage 4 完成！可以继续执行 Stage 5"
}

main "$@"
