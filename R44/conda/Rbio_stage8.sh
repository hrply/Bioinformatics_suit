#!/bin/bash
# Stage 8: 额外工具包安装
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage8_extra.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 8: 额外工具包
#========================================
install_extra_tools() {
    log_stage "[Stage 8] 安装额外工具包"
    
    log_info "Installing scanpy"
    pip_install "scanpy" || { log_warn "scanpy安装失败，继续..."; }
    
    log_stage_complete "Stage 8: 额外工具包"

    # Step 2: 安装 SingleR
    log_info "Installing SingleR"
    Rscript -e "
options(repos = c(cran = '${cran_url}'), download.file.method = 'libcurl');
options(BioC_mirror = '${bioc_url}');
BiocManager::install(version = '3.20', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');
BiocManager::install('SingleR', ask = FALSE, update = FALSE, site_repository = '${bioc_url}/packages/3.20/bioc');
cat('SingleR installed\n');
" || log_warn "SingleR安装失败"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "Stage 8: 额外工具包安装"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    rbio_init "$@"
    install_extra_tools
    
    # 验证安装（检查核心 R 和 Python 包）
    verify_installation
    
    log_info "Stage 8 完成！所有 CPU stage 已完成"
}

main "$@"
