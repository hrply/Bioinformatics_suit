#!/bin/bash
# R-bio 公共函数库 (R 4.5.2 + Bioconductor 3.22 版本)
# 被所有 stage 脚本引用
#
# 使用方法:
#   source "$(dirname "$0")/Rbio_common.sh"
#   rbio_init "$@"

#========================================
# 配置变量
#========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../.test/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ENV_NAME="${CONDA_DEFAULT_ENV:-r45}"
LOG_FILE="${LOG_DIR}/${ENV_NAME}_stage_${TIMESTAMP}.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 安装选项（默认值）
USE_CHINA_MIRROR=false
SUDO_PASSWORD=""

# sudo 前缀
SUDO=""

# 镜像源配置
PIP_INDEX_URL=""
PIP_TRUSTED_HOST=""
CRAN_MIRROR=""
BIOCONDUCTOR_MIRROR=""

# R 和 Bioconductor 版本
R_VERSION="4.5.2"
BIOC_VERSION="3.22"

#========================================
# 日志函数
#========================================
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "$1"
    echo "[$timestamp] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_info() { log "${GREEN}[INFO]${NC} $1"; }
log_warn() { log "${YELLOW}[WARN]${NC} $1"; }
log_error() { log "${RED}[ERROR]${NC} $1"; }
log_stage() { log "${CYAN}========================================\n$1\n========================================${NC}"; }
log_stage_complete() {
    log "${GREEN}========================================${NC}"
    log "${GREEN}[STAGE COMPLETE] $1 完成${NC}"
    log "${GREEN}========================================${NC}"
}

#========================================
# 权限检查
#========================================
setup_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if [ -n "$SUDO_PASSWORD" ]; then
            echo "$SUDO_PASSWORD" | sudo -S -v 2>/dev/null || {
                log_error "sudo 密码验证失败"
                exit 1
            }
            SUDO="sudo"
            log_info "sudo 凭据已验证"
        else
            SUDO="sudo"
        fi
    else
        SUDO=""
    fi
}

#========================================
# 镜像源设置 - CRAN 和 Bioconductor 都用清华源
#========================================
setup_china_mirrors() {
    log_info "配置国内镜像源（清华源）..."
    
    PIP_INDEX_URL="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
    PIP_TRUSTED_HOST="mirrors.tuna.tsinghua.edu.cn"
    CRAN_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/CRAN/"
    # Bioconductor 也使用清华源
    BIOCONDUCTOR_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/bioconductor"
    
    # 设置代理（用于访问 GitHub 等国外源）
    local proxy_url="${HTTP_PROXY:-${http_proxy:-}}"
    if [ -n "$proxy_url" ]; then
        export http_proxy="$proxy_url"
        export https_proxy="$proxy_url"
        export HTTP_PROXY="$proxy_url"
        export HTTPS_PROXY="$proxy_url"
        export no_proxy="localhost,127.0.0.1,mirrors.tuna.tsinghua.edu.cn"
        log_info "代理已设置: $proxy_url"
    else
        log_warn "未检测到代理环境变量 (HTTP_PROXY/http_proxy)，跳过代理设置"
        log_warn "如需代理，请先设置: export HTTP_PROXY=http://your-proxy:port"
    fi
    
    log_info "镜像源配置完成"
}

setup_default_mirrors() {
    log_info "使用默认镜像源..."
    
    PIP_INDEX_URL=""
    PIP_TRUSTED_HOST=""
    CRAN_MIRROR="https://cloud.r-project.org"
    BIOCONDUCTOR_MIRROR="https://bioconductor.org"
}

#========================================
# 环境检查
#========================================
check_conda_env() {
    if [ -z "$CONDA_PREFIX" ]; then
        log_error "未检测到 Conda 环境！"
        log_error "请先创建并激活 Conda 环境："
        log_error "  conda create -n r45 r-base=${R_VERSION} python=3.12"
        log_error "  conda activate r45"
        exit 1
    fi
    log_info "Conda 环境: $CONDA_DEFAULT_ENV"
    log_info "Conda 路径: $CONDA_PREFIX"
}

check_r() {
    if ! command -v R &> /dev/null; then
        log_error "未找到 R，请在 Conda 环境中安装 R："
        log_error "  mamba install -c conda-forge r-base"
        exit 1
    fi
    
    R_VERSION_DETECTED=$(R --version | head -1 | awk '{print $3}')
    log_info "R 版本: $R_VERSION_DETECTED"
    
    R_MAJOR=$(echo "$R_VERSION_DETECTED" | cut -d. -f1)
    R_MINOR=$(echo "$R_VERSION_DETECTED" | cut -d. -f2)
    
    if [ "$R_MAJOR" != "4" ] || [ "$R_MINOR" != "5" ]; then
        log_warn "R 版本 $R_VERSION_DETECTED 不符合要求（需要 4.5.x）"
        log_info "强制重装 r-base=${R_VERSION}..."
        mamba install -y -c conda-forge r-base=${R_VERSION} || {
            log_error "r-base=${R_VERSION} 安装失败"
            exit 1
        }
        R_VERSION_DETECTED=$(R --version | head -1 | awk '{print $3}')
        log_info "R 版本已更新为: $R_VERSION_DETECTED"
    fi
}

check_python() {
    if ! command -v python3 &> /dev/null; then
        log_error "未找到 Python3"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    log_info "Python 版本: $PYTHON_VERSION"
}

#========================================
# GitHub Token 设置（避免API限速）
#========================================
setup_github_token() {
    log_info "设置 GitHub Token..."
    
    
    export GITHUB_TOKEN
    export GITHUB_PAT="$GITHUB_TOKEN"
    
    Rscript -e "
token <- Sys.getenv('GITHUB_PAT')
if (nchar(token) > 0) {
    cat('GITHUB_PAT已设置，长度:', nchar(token), '\n')
} else {
    cat('警告: GITHUB_PAT未设置\n')
}
" 2>/dev/null
    
    log_info "GitHub Token 设置完成"
}

#========================================
# pip 安装函数
#========================================
pip_install() {
    local packages="$1"
    local extra_args="${2:-}"
    
    if [ -n "$PIP_INDEX_URL" ]; then
        python3 -m pip install --no-cache-dir -i "$PIP_INDEX_URL" --trusted-host "$PIP_TRUSTED_HOST" $packages $extra_args
    else
        python3 -m pip install --no-cache-dir $packages $extra_args
    fi
}

#========================================
# 初始化函数（由各 stage 脚本调用）
#========================================
rbio_init() {
    # 解析通用参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --china)
                USE_CHINA_MIRROR=true
                shift
                ;;
            --password)
                SUDO_PASSWORD="$2"
                shift 2
                ;;
            --help)
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # 配置镜像源
    if [ "$USE_CHINA_MIRROR" = true ]; then
        setup_china_mirrors
    else
        setup_default_mirrors
    fi
    
    # 设置 sudo
    setup_sudo
    
    # 检查环境
    check_conda_env
    check_r
    check_python
    
    # 设置 GitHub Token
    setup_github_token
    
    # 清理之前中断遗留的锁定文件
    local r_lib="${CONDA_PREFIX}/lib/R/library"
    if [ -d "$r_lib" ]; then
        local lock_count=$(find "$r_lib" -maxdepth 1 -name "00LOCK-*" -type d 2>/dev/null | wc -l)
        if [ "$lock_count" -gt 0 ]; then
            log_info "清理 $lock_count 个遗留的锁定文件..."
            rm -rf "$r_lib"/00LOCK-* 2>/dev/null || true
        fi
    fi
    
    log_info "日志文件: $LOG_FILE"
}

#========================================
# 配置环境（写入 Rprofile.site）
#========================================
setup_environment() {
    log_stage "[Config] 配置环境"
    
    local r_etc_dir="${CONDA_PREFIX}/lib/R/etc"
    mkdir -p "$r_etc_dir"
    
    if [ "$USE_CHINA_MIRROR" = true ]; then
        # CRAN 和 Bioconductor 都用清华源，Bioconductor 3.22
        tee "$r_etc_dir/Rprofile.site" << EOF
local({
  options(repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  options(BioC_mirror = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor")
  options(BioCsoft = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor/packages/${BIOC_VERSION}/bioc")
  options(BioCann = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor/packages/${BIOC_VERSION}/data/annotation")
  options(BioCexp = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor/packages/${BIOC_VERSION}/data/experiment")
  options(BioCworkflows = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor/packages/${BIOC_VERSION}/workflows")
})
EOF
    else
        tee "$r_etc_dir/Rprofile.site" << EOF
local({
  options(repos = "https://cloud.r-project.org")
  options(BioC_mirror = "https://bioconductor.org")
  options(BioCsoft = "https://bioconductor.org/packages/${BIOC_VERSION}/bioc")
  options(BioCann = "https://bioconductor.org/packages/${BIOC_VERSION}/data/annotation")
  options(BioCexp = "https://bioconductor.org/packages/${BIOC_VERSION}/data/experiment")
  options(BioCworkflows = "https://bioconductor.org/packages/${BIOC_VERSION}/workflows")
})
EOF
    fi
    log_info "R profile 已写入: $r_etc_dir/Rprofile.site"
    
    log_stage_complete "Config: 环境配置"
}

#========================================
# 验证安装 - 不检查 ArchR
#========================================
verify_installation() {
    log_stage "[Verify] 验证安装"
    
    log_info "Checking R packages..."
    Rscript -e "
packages <- c('Seurat', 'Signac', 'Azimuth', 'Giotto', 'monocle3')
for (pkg in packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
        cat(sprintf('  [OK] %s %s\n', pkg, packageVersion(pkg)))
    } else {
        cat(sprintf('  [MISSING] %s\n', pkg))
    }
}
" 2>/dev/null || log_warn "R包验证失败"
    
    log_info "Checking Python packages..."
    python3 -c "
packages = ['numpy', 'pandas', 'scanpy', 'umap', 'h5py']
for pkg in packages:
    try:
        mod = __import__(pkg)
        ver = getattr(mod, '__version__', 'unknown')
        print(f'  [OK] {pkg} {ver}')
    except ImportError:
        print(f'  [MISSING] {pkg}')
" 2>/dev/null || log_warn "Python包验证失败"
    
    log_stage_complete "Verify: 安装验证"
}

#========================================
# 显示通用帮助
#========================================
show_common_help() {
    cat << EOF
R-bio Stage 安装脚本 (R 4.5.2 + Bioconductor 3.22)

通用选项:
  --china         使用国内镜像源（清华源）
  --password P    提供 sudo 密码
  --help          显示此帮助信息

可用脚本:
  Rbio_1.sh           - Stage 1: Conda 编译依赖
  Rbio_2.sh           - Stage 2: 预编译 R 包
  Rbio_3.sh           - Stage 3: Python 包
  Rbio_4.sh           - Stage 4: R 包 (CRAN + Bioc)
  Rbio_5.sh           - Stage 5: Seurat + Signac + Azimuth
  Rbio_7.sh           - Stage 7: Giotto
  Rbio_8.sh           - Stage 8: 额外工具包
  Rbio_sgpu.sh        - GPU Stage: GPU Python 包
  Rbio_install.sh     - 顺序执行所有 stage

注意: Stage 6 (ArchR) 已移除，因为 ArchR 不适配 R 4.5

示例:
  ./Rbio_install.sh --china

前提条件:
  conda create -n r45 r-base=4.5.2 python=3.12
  conda activate r45
EOF
}
