#!/bin/bash
# Stage 6: ArchR 安装
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage6_archr.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 6: ArchR
#========================================
install_archr() {
    log_stage "[Stage 6] 安装 ArchR"
    
    local cran_url="${CRAN_MIRROR:-https://cloud.r-project.org}"
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"

    log_info "Installing ArchR dependencies"
    
    # Step 1: 安装 ArchR Bioconductor 依赖（通过 BiocManager 编译安装）
    # 注意: TFBSTools 已在 Stage 5 安装
    #       chromVAR/motifmatchr 因 bioconda 依赖冲突，直接用 BiocManager 安装
    log_info "Installing ArchR Bioconductor dependencies via BiocManager"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install(version = '3.20', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');

# ArchR 核心依赖（含 chromVAR/motifmatchr）
deps <- c('GenomicRanges', 'GenomeInfoDb', 'IRanges', 'S4Vectors',
    'SummarizedExperiment', 'SingleCellExperiment', 'limma', 'rsvd',
    'chromVAR', 'motifmatchr');
for (pkg in deps) {
    tryCatch({
        BiocManager::install(pkg, update = FALSE, ask = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');
        cat(pkg, 'installed\n');
    }, error = function(e) {
        cat(pkg, 'warning:', conditionMessage(e), '\n');
    });
}
cat('ArchR Bioconductor dependencies installed\n');
" || log_warn "ArchR依赖安装部分失败"
    
    # Step 2: 检查大型数据包（BSgenome.Hsapiens.UCSC.hg38 已通过离线包安装）
    log_info "Checking BSgenome.Hsapiens.UCSC.hg38"
    if Rscript -e "library(BSgenome.Hsapiens.UCSC.hg38)" 2>/dev/null; then
        log_info "BSgenome.Hsapiens.UCSC.hg38 已安装"
    else
        log_warn "BSgenome.Hsapiens.UCSC.hg38 未安装"
        log_warn "建议使用离线包：./Rbio_download_bsgenome.sh --china"
    fi
    
    # Step 3: ArchR 主包安装（带重试）
    log_info "Installing ArchR (with retry)"
    local archr_success=false
    for i in 1 2 3; do
        log_info "ArchR attempt $i/3"
        Rscript -e "
options(repos = c(cran = '${cran_url}'));
Sys.setenv(http_proxy = '${http_proxy}', https_proxy = '${https_proxy}');
options(download.file.method = 'curl');
options(BioC_mirror = '${bioc_url}');
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('GreenleafLab/ArchR', ref='master', repos = BiocManager::repositories(), upgrade = 'never');
" 2>&1 || true
        # 验证是否真正安装成功
        if Rscript -e "library(ArchR); cat('ArchR version:', as.character(packageVersion('ArchR')), '\n')" 2>/dev/null; then
            archr_success=true
            log_info "ArchR installed successfully"
            break
        fi
        log_warn "ArchR attempt $i failed, retrying..."
        sleep 10
    done
    [ "$archr_success" = true ] || log_warn "ArchR安装失败"
    
    log_info "Installing ArchR extra packages"
    Rscript -e "library(ArchR); ArchR::installExtraPackages()" 2>/dev/null \
        || log_warn "ArchR额外包安装失败（非关键）"
    
    log_stage_complete "Stage 6: ArchR"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 6: ArchR 安装"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_archr
    log_info "Stage 6 完成！可以继续执行 Stage 7"
}

main "$@"

