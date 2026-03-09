#!/bin/bash
# BSgenome.Hsapiens.UCSC.hg38 离线包下载脚本 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   ./Rbio_download_bsgenome.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# 下载 BSgenome.Hsapiens.UCSC.hg38
#========================================
download_bsgenome() {
    log_stage "[Download] 下载 BSgenome.Hsapiens.UCSC.hg38 离线包"
    
    local bioc_url="${BIOCONDUCTOR_MIRROR:-https://bioconductor.org}"
    local output_dir="$(dirname "$SCRIPT_DIR")"
    local target_file="${output_dir}/BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz"
    
    # 检查是否已存在
    if [ -f "$target_file" ]; then
        local pkg_size=$(du -h "$target_file" | cut -f1)
        log_info "离线包已存在: $target_file ($pkg_size)"
        log_info "如需重新下载，请先删除现有文件"
        return 0
    fi
    
    log_info "下载目录: $output_dir"
    log_info "镜像源: $bioc_url"
    
    # Bioconductor 3.22 数据包路径
    local download_url="${bioc_url}/packages/${BIOC_VERSION}/data/annotation/src/contrib/BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz"
    
    log_info "下载 URL: $download_url"
    
    # 使用 wget 下载
    cd "$output_dir"
    wget -c -O BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz "$download_url" || {
        log_error "下载失败！"
        log_error "请检查网络连接或尝试使用 --china 参数"
        exit 1
    }
    
    # 验证下载
    if [ -f "BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz" ]; then
        local pkg_size=$(du -h BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz | cut -f1)
        log_info "下载完成: BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz ($pkg_size)"
    else
        log_error "下载文件不存在"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    log_stage_complete "Download: BSgenome 离线包"
}

#========================================
# 主程序
#========================================
main() {
    if [[ "$1" == "--help" ]]; then
        echo "BSgenome.Hsapiens.UCSC.hg38 离线包下载脚本"
        echo ""
        echo "用法: $0 [--china]"
        echo ""
        echo "下载的文件将保存到上级目录"
        echo ""
        show_common_help
        exit 0
    fi
    
    # 只解析 --china 参数（不需要 conda 环境）
    USE_CHINA_MIRROR=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --china)
                USE_CHINA_MIRROR=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # 设置镜像
    if [ "$USE_CHINA_MIRROR" = true ]; then
        BIOCONDUCTOR_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/bioconductor"
        log_info "使用清华镜像"
    else
        BIOCONDUCTOR_MIRROR="https://bioconductor.org"
        log_info "使用官方镜像"
    fi
    
    download_bsgenome
}

main "$@"
