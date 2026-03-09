#!/bin/bash
# 下载 BSgenome.Hsapiens.UCSC.hg38 离线包
#
# 这个包约 800MB+，建议提前下载避免安装过程中网络问题
#
# 使用方法:
#   ./Rbio_download_bsgenome.sh [--china]
#
# 离线包会下载到脚本所在目录
# 用户也可以手动下载后放到脚本所在目录，文件名格式：BSgenome.Hsapiens.UCSC.hg38_*.tar.gz

set -e

#========================================
# 配置
#========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USE_CHINA_MIRROR=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --china)
            USE_CHINA_MIRROR=true
            shift
            ;;
        --help)
            echo "下载 BSgenome.Hsapiens.UCSC.hg38 离线包"
            echo ""
            echo "用法: $0 [--china]"
            echo ""
            echo "选项:"
            echo "  --china    使用国内镜像（西湖大学 Bioconductor 镜像）"
            echo "  --help     显示此帮助"
            echo ""
            echo "离线包会下载到: $SCRIPT_DIR"
            echo ""
            echo "用户也可以手动下载后放到此目录，文件名格式："
            echo "  BSgenome.Hsapiens.UCSC.hg38_*.tar.gz"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#========================================
# 检查是否已存在离线包
#========================================
check_existing() {
    local pattern="BSgenome.Hsapiens.UCSC.hg38_*.tar.gz"
    local existing=$(ls "$SCRIPT_DIR"/$pattern 2>/dev/null | head -1)
    
    if [ -n "$existing" ]; then
        local size=$(du -h "$existing" | cut -f1)
        log_info "已存在离线包: $existing ($size)"
        log_info "如需重新下载，请先删除现有文件"
        exit 0
    fi
}

#========================================
# 下载离线包
#========================================
download_package() {
    # Bioconductor 3.20 使用 R 4.4.x
    # 版本号可能更新，这里使用通配符匹配
    local BIOC_VERSION="3.20"
    local PKG_NAME="BSgenome.Hsapiens.UCSC.hg38"
    local PKG_VERSION="1.4.5"  # 当前最新版本
    local TAR_FILE="${PKG_NAME}_${PKG_VERSION}.tar.gz"
    
    # 选择镜像
    local BASE_URL
    if [ "$USE_CHINA_MIRROR" = true ]; then
        # 西湖大学 Bioconductor 镜像
        BASE_URL="https://mirrors.westlake.edu.cn/bioconductor/packages/${BIOC_VERSION}/data/annotation/src/contrib"
        log_info "使用国内镜像: 西湖大学 Bioconductor 镜像"
    else
        BASE_URL="https://bioconductor.org/packages/${BIOC_VERSION}/data/annotation/src/contrib"
        log_info "使用官方镜像: bioconductor.org"
    fi
    
    local DOWNLOAD_URL="${BASE_URL}/${TAR_FILE}"
    local OUTPUT_FILE="${SCRIPT_DIR}/${TAR_FILE}"
    
    log_info "=========================================="
    log_info "下载 BSgenome.Hsapiens.UCSC.hg38 离线包"
    log_info "=========================================="
    log_info "版本: ${PKG_VERSION}"
    log_info "来源: ${BASE_URL}"
    log_info "目标: ${OUTPUT_FILE}"
    log_info ""
    log_warn "此包约 800MB+，下载可能需要较长时间..."
    log_info ""
    
    # 使用 wget 下载（支持断点续传）
    if command -v wget &> /dev/null; then
        log_info "使用 wget 下载..."
        wget -c -O "$OUTPUT_FILE" "$DOWNLOAD_URL" || {
            log_error "下载失败！"
            log_error "URL: $DOWNLOAD_URL"
            rm -f "$OUTPUT_FILE" 2>/dev/null
            exit 1
        }
    elif command -v curl &> /dev/null; then
        log_info "使用 curl 下载..."
        curl -L -C - -o "$OUTPUT_FILE" "$DOWNLOAD_URL" || {
            log_error "下载失败！"
            log_error "URL: $DOWNLOAD_URL"
            rm -f "$OUTPUT_FILE" 2>/dev/null
            exit 1
        }
    else
        log_error "未找到 wget 或 curl，无法下载"
        exit 1
    fi
    
    # 验证文件大小（至少 700MB）
    local file_size=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null)
    local min_size=$((700 * 1024 * 1024))  # 700MB
    
    if [ "$file_size" -lt "$min_size" ]; then
        log_error "下载的文件不完整（${file_size} 字节）"
        log_error "预期至少 ${min_size} 字节（700MB）"
        rm -f "$OUTPUT_FILE"
        exit 1
    fi
    
    local size_mb=$((file_size / 1024 / 1024))
    log_info ""
    log_info "=========================================="
    log_info "${GREEN}下载完成！${NC}"
    log_info "文件: ${OUTPUT_FILE}"
    log_info "大小: ${size_mb}MB"
    log_info "=========================================="
}

#========================================
# 主程序
#========================================
main() {
    log_info "脚本目录: $SCRIPT_DIR"
    
    # 检查是否已存在
    check_existing
    
    # 下载
    download_package
}

main
