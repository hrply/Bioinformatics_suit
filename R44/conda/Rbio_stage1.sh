#!/bin/bash
# Stage 1: Conda 编译依赖安装
#
# 使用方法:
#   conda activate rbio2
#   ./Rbio_stage1_conda_deps.sh [--china]

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
    # leidenbase 依赖: 需要安装 r-leidenbase 或确保 igraph 头文件可用
        mamba install -y -c conda-forge --freeze-installed \
            r-base=4.4.3 \
            r-rlang r-cli r-glue r-magrittr \
            || { log_warn "核心包安装失败"; }    
    # R 包编译需要的额外库
    # - yaml-cpp, yaml: 多个R包需要
    # - boost: C++库 (BiocParallel等需要)
    #   注意: boost-cpp 与 icu 版本冲突严重，改用 boost（header-only 部分）
    # - igraph: leidenbase需要 (注意: libigraph包不存在，只有igraph)
    # - nanoflann: Rnanoflann需要 (header-only)
    # - udunits2: units包需要
    # - abseil-cpp/libabseil: s2包需要
    # - ann: 近邻搜索
    # - libjpeg-turbo: jpeg 包需要（替代 libjpeg）
    # - libtiff: 多个图像处理包需要
    #
    # 关键修复：锁定 r-base=4.4.3 防止版本漂移
    # mamba install 会自动升级依赖，必须显式锁定
    log_info "Installing additional libraries for R package compilation"
    # 核心编译依赖说明:
    # 注意: mio 和 boost-headers 在 conda-forge 中不存在
    # - vroom 需要的 mio: 使用 r-vroom 预编译包（第二批安装）
    # - BiocParallel 需要的 boost: 使用 r-bh 预编译包（第二批安装）
    # - cmake: 部分包编译需要
    # - expat: XML 解析
    # - libxml2: 多个 R 包需要
    # - openssl: 多个 R 包需要
    # - proj, geos, gdal: sf/terra/Giotto 需要
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
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
    # 这些包如果从源码编译会因库路径问题导致 undefined symbol 或找不到头文件
    #
    # 注意: bioconductor-dirichletmultinomial 1.40.0 需要 R <4.3，
    #       与 R 4.4.3 不兼容，从 CRAN/Bioc 安装
    #       bioconductor-cner 同样存在版本兼容问题
    #
    # 关键修复：使用 --freeze-installed 防止 R 版本被升级
    log_info "Installing pre-compiled R packages to avoid linking/compilation issues"
    
    # 第一批：bioconda 核心 Bioconductor 包
    mamba install -y -c bioconda -c conda-forge --freeze-installed \
        r-base=4.4.3 \
        bioconductor-rhdf5=2.50.0 \
        bioconductor-biocparallel=1.40.0 \
        --channel-priority flexible \
        || log_warn "部分 bioconda 包安装失败，将在后续重试..."
    
    # 第二批：conda-forge 预编译 R 包（避免编译错误）
    # - r-igraph: 避免 igraph_centrality.h 找不到
    # - r-vroom: 避免 mio/shared_mmap.hpp 找不到
    # - r-dqrng: 避免 mystdint.h 找不到
    # - r-cpp11: dqrng 依赖
    # - r-bh: Boost Headers for R, 多个包需要
    log_info "Installing pre-compiled CRAN R packages from conda-forge"
    mamba install -y -c conda-forge --freeze-installed \
        r-base=4.4.3 \
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
        echo "Stage 1: Conda 编译依赖安装"
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
