#!/bin/bash
# Stage 5: Seurat + Signac + Azimuth 安装
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage5_seurat.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 5: Seurat + Signac + Azimuth
#========================================
install_seurat_ecosystem() {
    log_stage "[Stage 5] 安装 Seurat + Signac + Azimuth"
    
    # 强制使用国内镜像源
    local cran_url="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"
    local bioc_url="https://mirrors.westlake.edu.cn/bioconductor"
    
    log_info "CRAN 镜像: $cran_url"
    log_info "Bioconductor 镜像: $bioc_url"
    
    # Step 1: 安装 Seurat (conda-forge预编译版本)
    log_info "Installing Seurat from conda-forge"
    mamba install -y -c conda-forge r-seurat r-uwot r-sctransform r-seuratobject \
        || { log_warn "conda Seurat安装失败，尝试CRAN..."; 
             Rscript -e "install.packages('Seurat', repos='${cran_url}')" || log_warn "Seurat安装失败"; }
    
    # Step 2: 安装 Signac (Bioconductor)
    log_info "Installing Signac from Bioconductor"
    Rscript -e "
options(repos = c(cran = '${cran_url}'));
options(download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install('Signac', ask = FALSE, update = FALSE);
cat('Signac installed\n');
" || log_error "Signac安装失败"
    
    # Step 3: 安装 presto (GitHub)
    log_info "Installing presto from GitHub"
    Rscript -e "
options(repos = c(cran = '${cran_url}'));
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('immunogenomics/presto', upgrade='never');
cat('presto installed\n');
" || log_error "presto安装失败"
    
    # Step 4: 检查 BSgenome (离线包)
    log_info "Checking BSgenome.Hsapiens.UCSC.hg38"
    if ! Rscript -e "library(BSgenome.Hsapiens.UCSC.hg38, quietly=TRUE); cat('OK\n')" 2>/dev/null | grep -q "OK"; then
        log_error "BSgenome.Hsapiens.UCSC.hg38 未安装！请先运行离线包安装"
        return 1
    fi
    log_info "BSgenome.Hsapiens.UCSC.hg38 已安装（离线包）"
    
    # Step 5: 安装 Azimuth 依赖 - 关键：必须用 conda 同时安装 TFBSTools + JASPAR2020
    log_info "Installing TFBSTools + JASPAR2020 from conda (关键步骤)"
    mamba install -y -c conda-forge -c bioconda bioconductor-tfbstools bioconductor-jaspar2020
    
    # 验证 TFBSTools
    if ! Rscript -e "library(TFBSTools, quietly=TRUE); cat('OK\n')" 2>/dev/null | grep -q "OK"; then
        log_error "TFBSTools 安装失败！"
        return 1
    fi
    log_info "TFBSTools 安装成功"
    
    # Step 5.1: 安装 EnsDb.Hsapiens.v86 (Azimuth 必需依赖)
    log_info "Installing EnsDb.Hsapiens.v86 (Azimuth 必需依赖)"
    mamba install -y -c conda-forge -c bioconda bioconductor-ensdb.hsapiens.v86
    
    # 验证 EnsDb.Hsapiens.v86
    if ! Rscript -e "library(EnsDb.Hsapiens.v86, quietly=TRUE); cat('OK\n')" 2>/dev/null | grep -q "OK"; then
        log_warn "conda EnsDb.Hsapiens.v86 安装失败，尝试 Bioconductor..."
        Rscript -e "
options(repos = c(cran = '${cran_url}'));
options(download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install('EnsDb.Hsapiens.v86', ask = FALSE, update = FALSE);
cat('EnsDb.Hsapiens.v86 installed\n');
"
    fi
    
    if ! Rscript -e "library(EnsDb.Hsapiens.v86, quietly=TRUE); cat('OK\n')" 2>/dev/null | grep -q "OK"; then
        log_error "EnsDb.Hsapiens.v86 安装失败！Azimuth 将无法使用"
        return 1
    fi
    log_info "EnsDb.Hsapiens.v86 安装成功"
    
    # Step 6: 安装 Azimuth
    log_info "Installing Azimuth from GitHub"
    local azimuth_success=false
    for i in 1 2 3; do
        log_info "Azimuth attempt $i/3"
        if Rscript -e "
options(repos = c(cran = '${cran_url}'));
options(download.file.method = 'libcurl');
options(timeout = 300);
if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools');
devtools::install_github('satijalab/azimuth', upgrade = 'never');
if (requireNamespace('Azimuth', quietly = TRUE)) {
    cat('Azimuth installed successfully\n');
    quit(status = 0);
} else {
    cat('ERROR: Azimuth load failed\n');
    quit(status = 1);
}
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
        log_error "Azimuth 安装失败"
        return 1
    fi
    
    # 验证所有核心包
    log_info "验证安装结果..."
    Rscript -e "
pkgs <- c('Seurat', 'Signac', 'Azimuth', 'presto')
for (p in pkgs) {
    if (requireNamespace(p, quietly = TRUE)) {
        cat(sprintf('[OK] %s %s\n', p, packageVersion(p)))
    } else {
        cat(sprintf('[FAIL] %s\n', p))
    }
}
"
    
    log_stage_complete "Stage 5: Seurat 生态"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 5: Seurat + Signac + Azimuth 安装"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_seurat_ecosystem
    log_info "Stage 5 完成！可以继续执行 Stage 6"
}

main "$@"
