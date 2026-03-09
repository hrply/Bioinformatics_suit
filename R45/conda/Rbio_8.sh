#!/bin/bash
# Stage 7: 额外工具包安装 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate bio
#   ./Rbio_7.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 7: 额外工具包
#========================================
install_extra_tools() {
    log_stage "[Stage 7] 安装额外工具包"
    
    local cran_url="${CRAN_MIRROR:-https://cloud.r-project.org}"
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    
    log_info "Installing scanpy"
    pip_install "scanpy" || { log_warn "scanpy安装失败，继续..."; }
    
    log_info "Installing SingleR"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install(version = '${BIOC_VERSION}', ask = FALSE, update = FALSE);
BiocManager::install('SingleR', ask = FALSE, update = FALSE);
cat('SingleR installed\n');
" || log_warn "SingleR安装失败"

    log_stage_complete "Stage 7: 额外工具包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 7: 额外工具包安装 (R 4.5.2 + Bioconductor 3.22)"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_extra_tools
    
    # 验证安装（检查核心 R 和 Python 包，不检查 ArchR）
    verify_installation
    
    log_info "Stage 7 完成！所有 CPU stage 已完成"
}

main "$@"
