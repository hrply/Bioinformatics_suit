#!/bin/bash
# Stage 5: Seurat + Signac + Azimuth 安装 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate bio
#   ./Rbio_5.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 5: Seurat + Signac + Azimuth
#========================================
install_seurat_ecosystem() {
    log_stage "[Stage 5] 安装 Seurat + Signac + Azimuth"
    
    local cran_url="${CRAN_MIRROR:-https://cloud.r-project.org}"
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    
    # Step 1: 安装 Seurat (conda-forge预编译版本)
    log_info "Installing Seurat from conda-forge"
    mamba install -y -c conda-forge r-seurat r-uwot r-sctransform r-seuratobject \
        || { log_warn "conda Seurat安装失败，尝试CRAN..."; 
             Rscript -e "install.packages('Seurat', repos='${cran_url}')" || log_warn "Seurat安装失败"; }
    
    # Step 2: 安装 Signac (Bioconductor)
    log_info "Installing Signac from Bioconductor"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install(version = '${BIOC_VERSION}', ask = FALSE, update = FALSE);
BiocManager::install('Signac', ask = FALSE, update = FALSE);
cat('Signac installed\n');
" || log_warn "Signac安装失败"
    
    # Step 3: 安装 Seurat 生态扩展包
    log_info "Installing Seurat ecosystem packages"
    # presto 从 GitHub 安装
    Rscript -e "
options(repos = c(cran = '${cran_url}'));
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('immunogenomics/presto', upgrade='never');
cat('presto installed\n');
" || log_warn "presto安装失败"
    
    # Step 3.5: 安装 Azimuth 依赖包（必须在 Azimuth 之前安装）
    # Azimuth 依赖: BSgenome.Hsapiens.UCSC.hg38, EnsDb.Hsapiens.v86, JASPAR2020, TFBSTools
    log_info "Installing Azimuth dependencies"
    
    # 检查 BSgenome.Hsapiens.UCSC.hg38 是否已通过离线包安装
    if ! Rscript -e "library(BSgenome.Hsapiens.UCSC.hg38, quietly=TRUE); cat('OK\n')" 2>/dev/null | grep -q "OK"; then
        log_warn "BSgenome.Hsapiens.UCSC.hg38 未安装！"
        log_warn "请先运行离线包安装："
        log_warn "  1. 确保 BSgenome.Hsapiens.UCSC.hg38_*.tar.gz 在脚本目录"
        log_warn "  2. 重新从 Stage 3 开始安装"
        # 继续执行，不返回错误
    else
        log_info "BSgenome.Hsapiens.UCSC.hg38 已安装（离线包）"
    fi
    
    # TFBSTools 从 bioconda 安装（Azimuth 依赖）
    mamba install -y -c bioconda -c conda-forge bioconductor-tfbstools \
        || log_warn "TFBSTools conda 安装失败，尝试 BiocManager..."
    
    # JASPAR2020, EnsDb 从 BiocManager 安装
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install(version = '${BIOC_VERSION}', ask = FALSE, update = FALSE);
BiocManager::install(c('JASPAR2020', 'EnsDb.Hsapiens.v86'), ask = FALSE, update = FALSE);
cat('Azimuth dependencies installed\n');
" || log_warn "Azimuth 依赖安装失败"
    
    
    # Step 4: 安装 Azimuth (带重试)
    log_info "Installing Azimuth (with retry)"
    local azimuth_success=false
    for i in 1 2 3; do
        log_info "Azimuth attempt $i/3"
        if Rscript -e "
options(repos = c(cran = '${cran_url}'));
options(download.file.method = 'libcurl');
options(timeout = 300);
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('satijalab/azimuth', upgrade = 'never');
cat('Azimuth installed\n');
" 2>&1; then
            azimuth_success=true
            break
        fi
        log_warn "Azimuth attempt $i failed, retrying..."
        sleep 10
    done
    
    if [ "$azimuth_success" = true ]; then
        log_info "Azimuth 安装成功"
    else
        log_warn "Azimuth安装失败（非关键包）"
        log_warn "如果缺少 BSgenome.Hsapiens.UCSC.hg38，请运行: ./Rbio_download_bsgenome.sh --china"
    fi
    
    log_stage_complete "Stage 5: Seurat 生态"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 5: Seurat + Signac + Azimuth 安装 (R 4.5.2 + Bioconductor 3.22)"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_seurat_ecosystem
    log_info "Stage 5 完成！跳过 Stage 6 (ArchR)，继续执行 Stage 7"
}

main "$@"
