#!/bin/bash
# Stage 3: Python 包安装 + BSgenome 离线包安装 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate bio
#   ./Rbio_3.sh [--china]
#
# 注意: 如果脚本目录存在 BSgenome.Hsapiens.UCSC.hg38_*.tar.gz 离线包，
#       会优先使用离线包安装，避免大文件下载问题。

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# 从离线包安装 BSgenome.Hsapiens.UCSC.hg38
#========================================
install_bsgenome_from_offline() {
    log_stage "[Stage 3a] 检查并安装 BSgenome.Hsapiens.UCSC.hg38 离线包"
    
    # 查找离线包（在上级目录）
    local parent_dir="$(dirname "$SCRIPT_DIR")"
    local pattern="BSgenome.Hsapiens.UCSC.hg38_*.tar.gz"
    local offline_pkg=$(ls "$parent_dir"/$pattern 2>/dev/null | head -1)
    
    if [ -z "$offline_pkg" ]; then
        log_warn "未找到 BSgenome.Hsapiens.UCSC.hg38 离线包"
        log_info "可运行 ./Rbio_download_bsgenome.sh --china 预下载"
        log_info "离线包安装已跳过，将在后续 stage 从网络安装"
        return 0
    fi
    
    local pkg_size=$(du -h "$offline_pkg" | cut -f1)
    log_info "找到离线包: $offline_pkg ($pkg_size)"
    
    # 安装 BiocManager 和 BSgenome（依赖）
    local cran_url="${CRAN_MIRROR:-https://cloud.r-project.org}"
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    
    log_info "安装 BSgenome 依赖..."
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager');
BiocManager::install(version = '${BIOC_VERSION}', ask = FALSE, update = FALSE);
BiocManager::install(c('BSgenome', 'GenomeInfoDb'), ask = FALSE, update = FALSE);
cat('Dependencies installed\n');
" || log_warn "BSgenome 依赖安装失败，继续..."
    
    # 从离线包安装
    log_info "从离线包安装 BSgenome.Hsapiens.UCSC.hg38..."
    R CMD INSTALL "$offline_pkg" || {
        log_error "离线包安装失败！"
        log_error "请检查离线包是否完整，或删除后重新下载"
        exit 1
    }
    
    # 验证安装
    if Rscript -e "library(BSgenome.Hsapiens.UCSC.hg38); cat('BSgenome.Hsapiens.UCSC.hg38 版本:', as.character(packageVersion('BSgenome.Hsapiens.UCSC.hg38')), '\n')" 2>/dev/null; then
        log_info "BSgenome.Hsapiens.UCSC.hg38 离线安装成功！"
    else
        log_warn "BSgenome.Hsapiens.UCSC.hg38 验证失败"
    fi
    
    log_stage_complete "Stage 3a: BSgenome 离线包"
}

#========================================
# Stage 3: Python 包安装
#========================================
install_python_packages() {
    log_stage "[Stage 3b] 安装 Python 包"
    
    log_info "Installing Python packages via pip"
    pip_install "numpy umap-learn llvmlite pandas scipy scikit-learn h5py macs3" \
        || { log_error "Python包安装失败"; exit 1; }
    
    log_info "Installing additional Python packages"
    pip_install "imagecodecs tifffile scikit-image annoy matplotlib seaborn biopython" \
        || { log_warn "部分额外Python包安装失败，继续..."; }
    
    # scanpy 生态（单细胞分析）
    log_info "Installing scanpy ecosystem"
    pip_install "scanpy anndata leidenalg python-igraph" \
        || { log_warn "scanpy生态安装失败，继续..."; }
    
    log_stage_complete "Stage 3b: Python 包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 3: Python 包安装 + BSgenome 离线包安装"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        echo "此脚本会检查并安装 BSgenome.Hsapiens.UCSC.hg38 离线包（如果存在）"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    
    # Step 1: 检查并安装离线包
    install_bsgenome_from_offline
    
    # Step 2: 安装 Python 包
    install_python_packages
    
    log_info "Stage 3 完成！可以继续执行 Stage 4"
}

main "$@"
