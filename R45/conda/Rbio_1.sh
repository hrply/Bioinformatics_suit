#!/bin/bash
# Stage 1: Conda 编译依赖安装 (R 4.5.2 + Bioconductor 3.22)
#
# 使用方法:
#   conda activate bio
#   ./Rbio_1.sh [--china]

set -e

# 引入公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

#========================================
# Stage 1: Conda 依赖安装
#========================================
install_conda_deps() {
    log_stage "[Stage 1] 安装 Conda 编译依赖"

    # 清理 conda 缓存中损坏的包（修复 SHA256 校验失败）
    log_info "Cleaning corrupted conda cache"
    conda clean --all --yes 2>/dev/null || true

    log_info "Installing build tools and libraries via conda-forge"
    # 核心编译工具 + 系统库（geos/gdal/proj/gsl 供 sf/terra/Giotto 编译使用）
    # fribidi: textshaping 需要
    # 注意: R 4.5.2 对应 Bioconductor 3.22，不使用 --freeze-installed 以安装兼容版本
    mamba install -y -c conda-forge \
        r-base=4.5.2 \
        r-rlang r-cli r-glue r-magrittr \
        || { log_warn "核心包安装失败"; }    
    
    # R 包编译需要的额外库
    # - yaml-cpp, yaml: 多个R包需要
    # - igraph: leidenbase需要
    # - nanoflann: Rnanoflann需要 (header-only)
    # - udunits2: units包需要
    # - abseil-cpp/libabseil: s2包需要
    # - ann: 近邻搜索
    # - libjpeg-turbo: jpeg 包需要
    # - libtiff: 多个图像处理包需要
    #
    # 修正：不锁定版本，让 conda 自动选择 R 4.5 兼容版本
    log_info "Installing additional libraries for R package compilation"
    mamba install -y -c conda-forge \
        r-base=4.5.2 \
        yaml-cpp yaml \
        igraph \
        nanoflann \
        udunits2 \
        libabseil \
        ann \
        libjpeg-turbo \
        libtiff \
        cmake \
        expat \
        libxml2 \
        openssl \
        proj geos gdal \
        || log_warn "部分额外库安装失败，继续..."

    # 安装预编译的 bioconda/conda-forge 包（解决 GSL/HDF5 链接问题和编译头文件问题）
    # 注意: 不使用 --freeze-installed，让包管理器自动选择 R 4.5 兼容版本
    log_info "Installing pre-compiled R packages to avoid linking/compilation issues"
    
    # 第一批：bioconda 核心 Bioconductor 包
    mamba install -y -c bioconda -c conda-forge \
        r-base=4.5.2 \
        bioconductor-rhdf5 \
        bioconductor-biocparallel \
        --channel-priority flexible \
        || log_warn "部分 bioconda 包安装失败，将在后续从 BiocManager 安装..."
    
    # 第二批：conda-forge 预编译 R 包（避免编译错误）
    log_info "Installing pre-compiled CRAN R packages from conda-forge"
    mamba install -y -c conda-forge \
        r-base=4.5.2 \
        r-igraph \
        r-vroom \
        r-dqrng \
        r-cpp11 \
        r-bh \
        || log_warn "部分 conda-forge R 包安装失败，将尝试从 CRAN 安装..."
    
    # 安装 mamba 加速 Bioconductor 包依赖解析
    log_info "Installing mamba for faster dependency resolution"
    mamba install -y -c conda-forge mamba \
        || log_warn "mamba 安装失败，将使用 conda"
    
    log_stage_complete "Stage 1: Conda 依赖"
}

#========================================
# 主程序
#========================================
main() {
    # 显示帮助
    if [[ "$1" == "--help" ]]; then
        echo "Stage 1: Conda 编译依赖安装 (R 4.5.2 + Bioconductor 3.22)"
        echo ""
        echo "用法: $0 [--china] [--password PWD]"
        echo ""
        show_common_help
        exit 0
    fi
    
    # 初始化（解析参数、检查环境）
    rbio_init "$@"
    
    # 配置 R 环境（写入 Rprofile.site，为后续 Stage 提前配置镜像）
    setup_environment
    
    # 执行安装
    install_conda_deps
    
    log_info "Stage 1 完成！可以继续执行 Stage 2"
}

main "$@"

