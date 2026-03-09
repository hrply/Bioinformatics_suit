#!/bin/bash
# 下载 BSgenome 离线包
#
# 这个脚本支持下载以下包：
#   - BSgenome.Hsapiens.UCSC.hg38
#   - BSgenome.Mmusculus.UCSC.mm39
#
# 使用方法:
#   ./Rbio_download_bsgenome.sh [--china] [all|hg38|mm39]
#
# 离线包会下载到脚本所在目录

set -e

#========================================
# 配置
#========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USE_CHINA_MIRROR=false
DOWNLOAD_TARGET="all"
BIOC_VERSION="3.20"

# 包名（不含版本）
PKG_HG38_NAME="BSgenome.Hsapiens.UCSC.hg38"
PKG_MM39_NAME="BSgenome.Mmusculus.UCSC.mm39"

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
# 解析参数
#========================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --china)
                USE_CHINA_MIRROR=true
                shift
                ;;
            all|hg38|mm39)
                DOWNLOAD_TARGET="$1"
                shift
                ;;
            --help|-h)
                echo "下载 BSgenome 离线包"
                echo ""
                echo "用法: $0 [--china] [all|hg38|mm39]"
                echo ""
                echo "选项:"
                echo "  --china    使用国内镜像"
                echo "  all        下载所有包 (默认)"
                echo "  hg38       仅下载 BSgenome.Hsapiens.UCSC.hg38"
                echo "  mm39       仅下载 BSgenome.Mmusculus.UCSC.mm39"
                echo "  --help     显示此帮助"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

#========================================
# 获取包的最新版本号
#========================================
get_package_version() {
    local pkg_name=$1
    
    # 构建镜像 URL
    local BASE_URL
    if [ "$USE_CHINA_MIRROR" = true ]; then
        BASE_URL="https://mirrors.westlake.edu.cn/bioconductor/packages/${BIOC_VERSION}/data/annotation/src/contrib"
    else
        BASE_URL="https://bioconductor.org/packages/${BIOC_VERSION}/data/annotation/src/contrib"
    fi
    
    # 从 PACKAGES 文件获取版本号
    local version=""
    if command -v curl &> /dev/null; then
        version=$(curl -s "${BASE_URL}/PACKAGES" | grep -A1 "^Package: ${pkg_name}$" | grep "^Version:" | head -1 | cut -d' ' -f2)
    elif command -v wget &> /dev/null; then
        version=$(wget -qO- "${BASE_URL}/PACKAGES" | grep -A1 "^Package: ${pkg_name}$" | grep "^Version:" | head -1 | cut -d' ' -f2)
    fi
    
    echo "$version"
}

#========================================
# 检查是否已存在离线包
#========================================
check_existing() {
    local pkg_name=$1
    local pattern="${pkg_name}_*.tar.gz"
    local existing=$(ls "$SCRIPT_DIR"/$pattern 2>/dev/null | head -1)
    
    if [ -n "$existing" ]; then
        local size=$(du -h "$existing" | cut -f1)
        log_info "已存在离线包: $(basename "$existing") ($size)"
        return 0
    fi
    return 1
}

#========================================
# 下载离线包
#========================================
download_package() {
    local pkg_name=$1
    
    # 获取版本号
    log_info "查询 ${pkg_name} 的最新版本..."
    local pkg_version=$(get_package_version "$pkg_name")
    
    if [ -z "$pkg_version" ]; then
        log_error "无法获取 ${pkg_name} 的版本信息"
        return 1
    fi
    
    log_info "最新版本: ${pkg_version}"
    
    local TAR_FILE="${pkg_name}_${pkg_version}.tar.gz"
    local OUTPUT_FILE="${SCRIPT_DIR}/${TAR_FILE}"
    
    # 选择镜像
    local BASE_URL
    if [ "$USE_CHINA_MIRROR" = true ]; then
        BASE_URL="https://mirrors.westlake.edu.cn/bioconductor/packages/${BIOC_VERSION}/data/annotation/src/contrib"
        log_info "使用国内镜像: 西湖大学"
    else
        BASE_URL="https://bioconductor.org/packages/${BIOC_VERSION}/data/annotation/src/contrib"
        log_info "使用官方镜像: bioconductor.org"
    fi
    
    local DOWNLOAD_URL="${BASE_URL}/${TAR_FILE}"
    
    log_info "=========================================="
    log_info "下载 ${pkg_name}"
    log_info "=========================================="
    log_info "版本: ${pkg_version}"
    log_info "目标: ${OUTPUT_FILE}"
    log_warn "此包较大，下载可能需要较长时间..."
    
    # 下载
    if command -v wget &> /dev/null; then
        log_info "使用 wget 下载..."
        wget -c --progress=bar:force -O "$OUTPUT_FILE" "$DOWNLOAD_URL" || {
            log_error "下载失败: $DOWNLOAD_URL"
            rm -f "$OUTPUT_FILE" 2>/dev/null
            return 1
        }
    elif command -v curl &> /dev/null; then
        log_info "使用 curl 下载..."
        curl -L -C - -o "$OUTPUT_FILE" "$DOWNLOAD_URL" || {
            log_error "下载失败: $DOWNLOAD_URL"
            rm -f "$OUTPUT_FILE" 2>/dev/null
            return 1
        }
    else
        log_error "未找到 wget 或 curl"
        return 1
    fi
    
    # 验证
    if ! gzip -t "$OUTPUT_FILE" 2>/dev/null; then
        log_error "文件损坏"
        rm -f "$OUTPUT_FILE"
        return 1
    fi
    
    local size_mb=$(($(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null) / 1024 / 1024))
    log_info "下载完成: ${size_mb}MB"
    
    return 0
}

#========================================
# 处理包
#========================================
process_package() {
    local pkg_name=$1
    
    if check_existing "$pkg_name"; then
        log_warn "如需重新下载，请先删除现有文件"
        return 0
    fi
    
    download_package "$pkg_name"
}

#========================================
# 主程序
#========================================
main() {
    parse_args "$@"
    
    log_info "脚本目录: $SCRIPT_DIR"
    log_info "下载目标: $DOWNLOAD_TARGET"
    
    local failed=0
    
    case $DOWNLOAD_TARGET in
        all)
            process_package "$PKG_HG38_NAME" || ((failed++))
            process_package "$PKG_MM39_NAME" || ((failed++))
            ;;
        hg38)
            process_package "$PKG_HG38_NAME" || ((failed++))
            ;;
        mm39)
            process_package "$PKG_MM39_NAME" || ((failed++))
            ;;
    esac
    
    if [ $failed -gt 0 ]; then
        log_error "有 $failed 个包下载失败"
        exit 1
    fi
    
    log_info "所有下载任务完成！"
}

main "$@"
