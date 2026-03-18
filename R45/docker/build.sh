#!/bin/bash
# =============================================================================
# Rbio Docker 交互式构建脚本
# Usage: bash build.sh [options]
# Options:
#   --stage N     从指定阶段开始构建 (1=base, 2=R, 3=cpubase/gpubase, 4=final)
#   --gpu         构建 GPU 版本 (包含 CUDA和RAPIDS)
#   --final       构建最终镜像 (Jupyter Lab + RStudio)
#   --from-scratch 从头开始构建（清理旧镜像）
#
# 构建流程:
#   CPU: base → R → CPU_base → final
#   GPU: base → R → GPU_base → final
# =============================================================================

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="rbio"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${SCRIPT_DIR}/.test/logs/docker_build"
BACKUP_DIR="${SCRIPT_DIR}/.test/backups"

# 确保目录存在
mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"

# =============================================================================
# GitHub Token 设置（避免API限速）
# =============================================================================
setup_github_token() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 设置 GitHub Token..."

    # 优先级：环境变量 GITHUB_TOKEN > 环境变量 GITHUB_PAT > .github_token 文件
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "从环境变量 GITHUB_TOKEN 读取"
    elif [ -n "$GITHUB_PAT" ]; then
        GITHUB_TOKEN="$GITHUB_PAT"
        echo "从环境变量 GITHUB_PAT 读取"
    elif [ -f "./.github_token" ]; then
        GITHUB_TOKEN=$(cat "./.github_token" | tr -d '\n')
        echo "从文件 ./.github_token 读取"
    else
        echo "警告: 未检测到 GitHub Token，将使用匿名访问（可能受限）"
        echo "请通过以下方式配置："
        echo "  方式1: export GITHUB_TOKEN=your_token"
        echo "  方式2: echo 'your_token' > .github_token"
        GITHUB_TOKEN=""
    fi

    export GITHUB_TOKEN
    export GITHUB_PAT="$GITHUB_TOKEN"

    if [ -n "$GITHUB_TOKEN" ]; then
        echo "GitHub Token 已设置，长度: ${#GITHUB_TOKEN}"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] GitHub Token 设置完成"
}

# 调用设置
cd "${SCRIPT_DIR}"
setup_github_token

# 默认参数
STAGE=1
BUILD_GPU=false
BUILD_FINAL=false
FROM_SCRATCH=false
MIRROR=""
HTTP_PROXY=""
HTTPS_PROXY=""
GITHUB_PROXY=""
NO_INTERACTIVE=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --stage)
            STAGE="$2"
            shift 2
            ;;
        --gpu)
            BUILD_GPU=true
            shift
            ;;
        --final)
            BUILD_FINAL=true
            shift
            ;;
        --from-scratch)
            FROM_SCRATCH=true
            shift
            ;;
        --mirror)
            MIRROR="$2"
            shift 2
            ;;
        --http-proxy)
            HTTP_PROXY="$2"
            shift 2
            ;;
        --https-proxy)
            HTTPS_PROXY="$2"
            shift 2
            ;;
        --github-proxy)
            GITHUB_PROXY="$2"
            shift 2
            ;;
        -y|--no-interactive)
            NO_INTERACTIVE=true
            shift
            ;;
        -h|--help)
            echo "Usage: bash build.sh [options]"
            echo ""
            echo "Options:"
            echo "  --stage N       从指定阶段开始构建 (1=base, 2=R, 3=cpu/gpu, 4=final)"
            echo "  --gpu           构建 GPU 版本"
            echo "  --final         构建到最终镜像"
            echo "  --from-scratch  从头开始构建（清理旧镜像）"
            echo "  --mirror        镜像源 (china/default)"
            echo "  --http-proxy    HTTP 代理地址"
            echo "  --https-proxy   HTTPS 代理地址"
            echo "  --github-proxy  GitHub 代理地址"
            echo "  -y, --no-interactive  跳过交互提示"
            echo ""
            echo "构建流程:"
            echo "  CPU: base → R → cpu → final"
            echo "  GPU: base → R → gpu → final"
            echo ""
            echo "示例:"
            echo "  --stage 1 --final --gpu    从stage 1构建到最终GPU镜像"
            echo "  --stage 1 --final          从stage 1构建到最终CPU镜像"
            echo "  --stage 3                  只构建stage 3 (CPU版本)"
            echo "  --stage 3 --gpu            只构建stage 3 (GPU版本)"
            echo "  --stage 3 --final --gpu    从stage 3构建到最终GPU镜像"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# =============================================================================
# 交互式配置（如果命令行未指定）
# =============================================================================

# 镜像源选择
if [[ "${NO_INTERACTIVE}" == "false" && -z "${MIRROR}" ]]; then
    echo "========================================"
    echo "  选择镜像源"
    echo "========================================"
    echo "1) 官方镜像 (默认)"
    echo "2) 国内镜像 (清华源)"
    read -p "请选择 [1/2] (默认: 1): " mirror_choice
    case "${mirror_choice}" in
        2)
            MIRROR="china"
            echo "已选择: 国内镜像"
            ;;
        *)
            MIRROR="default"
            echo "已选择: 官方镜像"
            ;;
    esac
fi

# 代理设置（仅在未指定时提示）
if [[ -z "${HTTP_PROXY}" && -z "${HTTPS_PROXY}" && "${MIRROR}" == "default" && "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    echo "========================================"
    echo "  代理设置 (留空表示不使用代理)"
    echo "========================================"
    read -p "HTTP 代理地址 (例如: http://127.0.0.1:7890): " HTTP_PROXY
    if [[ -n "${HTTP_PROXY}" ]]; then
        HTTPS_PROXY="${HTTP_PROXY}"
    fi
fi

# 构建阶段选择（仅在完全交互模式下提示）
if [[ "${STAGE}" == "1" && "${NO_INTERACTIVE}" == "false" && -z "$1" ]]; then
    echo ""
    echo "========================================"
    echo "  选择构建阶段"
    echo "========================================"
    echo "1) 完整构建 CPU 版本 (base → R → CPU → final)"
    echo "2) 完整构建 GPU 版本 (base → R → RAPIDS → final)"
    echo "3) 从 R 阶段开始"
    echo "4) 仅构建 CPU/GPU 阶段"
    echo "5) 仅构建 final 阶段"
    read -p "请选择 [1/2/3/4/5] (默认: 1): " stage_choice
    case "${stage_choice}" in
        2)
            STAGE=1
            BUILD_GPU=true
            BUILD_FINAL=true
            ;;
        3)
            STAGE=2
            ;;
        4)
            STAGE=3
            ;;
        5)
            STAGE=4
            BUILD_FINAL=true
            ;;
        *)
            STAGE=1
            BUILD_GPU=false
            BUILD_FINAL=true
            ;;
    esac
fi

# GPU 确认（仅在交互模式下提示）
if [[ "${STAGE}" -lt 3 && "${BUILD_GPU}" == "false" && "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    read -p "是否构建 GPU 版本? [y/N]: " gpu_choice
    if [[ "${gpu_choice}" =~ ^[Yy]$ ]]; then
        BUILD_GPU=true
    fi
fi

# Final 确认（仅在交互模式下提示）
if [[ "${BUILD_FINAL}" == "false" && -z "$1" && "${NO_INTERACTIVE}" == "false" ]]; then
    echo ""
    read -p "是否构建最终镜像 (Jupyter Lab + RStudio)? [Y/n]: " final_choice
    if [[ ! "${final_choice}" =~ ^[Nn]$ ]]; then
        BUILD_FINAL=true
    fi
fi

# 显示配置摘要
echo ""
echo "========================================"
echo "  构建配置摘要"
echo "========================================"
echo "镜像源: ${MIRROR}"
echo "HTTP 代理: ${HTTP_PROXY:-无}"
echo "GitHub 代理: ${GITHUB_PROXY:-无}"
echo "构建阶段: ${STAGE}"
echo "构建 GPU: ${BUILD_GPU}"
echo "构建 Final: ${BUILD_FINAL}"
echo "日志目录: ${LOG_DIR}"
echo "========================================"

# 检查是否跳过交互确认
if [[ "${NO_INTERACTIVE}" == "true" ]]; then
    echo "非交互模式，自动确认..."
else
    read -p "确认开始构建? [Y/n]: " confirm
    if [[ "${confirm}" =~ ^[Nn]$ ]]; then
        echo "构建已取消"
        exit 0
    fi
fi

# =============================================================================
# 构建函数
# =============================================================================

# 通用构建参数生成函数
generate_build_args() {
    local args=""

    # 镜像源参数
    args="--build-arg mirror=${MIRROR}"

    # 镜像源 URL（根据 mirror 参数设置）
    if [[ "${MIRROR}" == "china" ]]; then
        args="${args} --build-arg CRAN_URL=https://mirrors.tuna.tsinghua.edu.cn/CRAN"
        args="${args} --build-arg BIOC_URL=https://mirrors.tuna.tsinghua.edu.cn/bioconductor"
        args="${args} --build-arg APT_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu"
        args="${args} --build-arg PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple"
        args="${args} --build-arg PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn"
    fi

    # GitHub Token
    if [[ -n "${GITHUB_TOKEN}" ]]; then
        args="${args} --build-arg GITHUB_TOKEN=${GITHUB_TOKEN}"
    fi

    # 全局代理（影响所有网络请求）
    if [[ -n "${HTTP_PROXY}" ]]; then
        args="${args} --build-arg http_proxy=${HTTP_PROXY}"
        args="${args} --build-arg https_proxy=${HTTPS_PROXY:-${HTTP_PROXY}}"
    fi

    # GitHub 专用代理（只用于 GitHub 下载）
    if [[ -n "${GITHUB_PROXY}" ]]; then
        args="${args} --build-arg github_proxy=${GITHUB_PROXY}"
    fi

    echo "${args}"
}

# Stage 1: Base 构建
build_base() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 1: r-bio:base (多阶段)"
    local logfile="${LOG_DIR}/Rbio_base_${TIMESTAMP}.log"
    local build_args=$(generate_build_args)

    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"

    # 定义阶段列表 (target name, 镜像名称)
    local stages=(
        "base-1:r-bio:base-1"
        "base-2:r-bio:base-2"
        "base-3:r-bio:base-3"
        "base-4:r-bio:base-4"
        "base-final:r-bio:base"
    )

    for stage_info in "${stages[@]}"; do
        IFS=':' read -r target image_name <<< "${stage_info}"
        echo ""
        echo "构建 ${target}..."

        if ! docker build -f "${SCRIPT_DIR}/Rbio_base.dockerfile" \
            --target "${target}" \
            -t "${image_name}" \
            ${build_args} \
            "${SCRIPT_DIR}" 2>&1 | tee -a "${logfile}"; then
            echo "ERROR: ${target} 构建失败"
            return 1
        fi
        echo "[OK] ${image_name} 构建成功"
    done

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 1: 所有子阶段构建成功"
    echo ""
    echo "生成的镜像:"
    docker images | grep "r-bio.*base" || true
    return 0
}

# Stage 2: R 构建 (R 包安装)
build_R() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 2: r-bio:R (多阶段)"
    local logfile="${LOG_DIR}/Rbio_R_${TIMESTAMP}.log"

    # 检查依赖镜像是否存在
    if ! docker images | grep -q "r-bio.*base"; then
        echo "ERROR: 依赖镜像 r-bio:base 不存在"
        return 1
    fi

    local build_args=$(generate_build_args)
    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"

    # 定义阶段列表 (target name, 镜像名称)
    local stages=(
        "R-1:r-bio:R-1"
        "R-2:r-bio:R-2"
        "R-3:r-bio:R-3"
        "R-4:r-bio:R-4"
        "R-5:r-bio:R-5"
        "R-6:r-bio:R-6"
        "R-7:r-bio:R-7"
        "R-8:r-bio:R-8"
        "R-9:r-bio:R-9"
        "R-10:r-bio:R-10"
        "R-11:r-bio:R-11"
        "R-12:r-bio:R-12"
        "R-13:r-bio:R-13"
        "R-14:r-bio:R-14"
        "R-final:r-bio:R"
    )

    for stage_info in "${stages[@]}"; do
        IFS=':' read -r target image_name <<< "${stage_info}"
        echo ""
        echo "构建 ${target}..."

        if ! docker build -f "${SCRIPT_DIR}/Rbio_R.dockerfile" \
            --target "${target}" \
            -t "${image_name}" \
            ${build_args} \
            "${SCRIPT_DIR}" 2>&1 | tee -a "${logfile}"; then
            echo "ERROR: ${target} 构建失败"
            return 1
        fi
        echo "[OK] ${image_name} 构建成功"
    done

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 2: 所有子阶段构建成功"
    echo ""
    echo "生成的镜像:"
    docker images | grep "r-bio" | grep -E "R-|r-bio:R" || true
    return 0
}

# Stage 3a: CPU 构建 (CPU 版本的 Python ML 包)
build_cpu() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 3a: rbio:cpubase"
    local logfile="${LOG_DIR}/Rbio_CPU_${TIMESTAMP}.log"

    # 检查依赖镜像是否存在
    if ! docker images | grep -q "r-bio.*R"; then
        echo "ERROR: 依赖镜像 r-bio:R 不存在"
        return 1
    fi

    local build_args=$(generate_build_args)
    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"

    if ! docker build -f "${SCRIPT_DIR}/Rbio_cpu.dockerfile" \
        -t rbio:cpubase \
        ${build_args} \
        "${SCRIPT_DIR}" 2>&1 | tee "${logfile}"; then
        echo "ERROR: Stage 3a (cpu) 构建失败"
        return 1
    fi

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 3a: rbio:cpubase 构建成功"
    return 0
}

# Stage 3b: GPU 构建
build_gpu() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 3b: rbio:gpubase"
    local logfile="${LOG_DIR}/Rbio_gpu_${TIMESTAMP}.log"

    # 检查依赖镜像是否存在
    if ! docker images | grep -q "r-bio.*R"; then
        echo "ERROR: 依赖镜像 r-bio:R 不存在"
        return 1
    fi

    local build_args=$(generate_build_args)
    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"

    if ! docker build -f "${SCRIPT_DIR}/Rbio_gpu.dockerfile" \
        -t rbio:gpubase \
        ${build_args} \
        "${SCRIPT_DIR}" 2>&1 | tee "${logfile}"; then
        echo "ERROR: Stage 3b (gpu) 构建失败"
        return 1
    fi

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 3b: rbio:gpubase 构建成功"
    return 0
}

# Stage 4: Final 构建
build_final() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 4: 最终镜像"
    local logfile="${LOG_DIR}/Rbio_final_${TIMESTAMP}.log"
    local build_args=$(generate_build_args)

    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"

    # 根据 BUILD_GPU 选择构建 CPU 或 GPU 最终镜像
    if [[ "${BUILD_GPU}" == "true" ]]; then
        if ! docker images | grep -q "rbio:gpubase"; then
            echo "ERROR: 依赖镜像 rbio:gpubase 不存在"
            return 1
        fi
        echo ""
        echo "构建 rbio:gpu (基于 rbio:gpubase)..."
        if ! docker build -f "${SCRIPT_DIR}/Rbio_final.dockerfile" \
            --target gpu \
            -t rbio:gpu \
            ${build_args} \
            "${SCRIPT_DIR}" 2>&1 | tee -a "${logfile}"; then
            echo "ERROR: rbio:gpu 构建失败"
            return 1
        fi
        echo "[OK] rbio:gpu 构建成功"
    else
        if ! docker images | grep -q "rbio:cpubase"; then
            echo "ERROR: 依赖镜像 rbio:cpubase 不存在"
            return 1
        fi
        echo ""
        echo "构建 rbio:cpu (基于 rbio:cpubase)..."
        if ! docker build -f "${SCRIPT_DIR}/Rbio_final.dockerfile" \
            --target cpu \
            -t rbio:cpu \
            ${build_args} \
            "${SCRIPT_DIR}" 2>&1 | tee -a "${logfile}"; then
            echo "ERROR: rbio:cpu 构建失败"
            return 1
        fi
        echo "[OK] rbio:cpu 构建成功"
    fi

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 4: 最终镜像构建成功"
    echo ""
    echo "生成的镜像:"
    docker images | grep "rbio" || true
    return 0
}

# =============================================================================
# 主流程
# =============================================================================

# 保存配置到文件（供监控脚本使用）
CONFIG_FILE="${LOG_DIR}/build_config_${TIMESTAMP}.txt"
cat > "${CONFIG_FILE}" <<EOF
PROJECT_NAME=${PROJECT_NAME}
TIMESTAMP=${TIMESTAMP}
MIRROR=${MIRROR}
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
GITHUB_PROXY=${GITHUB_PROXY}
STAGE=${STAGE}
BUILD_GPU=${BUILD_GPU}
BUILD_FINAL=${BUILD_FINAL}
LOG_DIR=${LOG_DIR}
EOF

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 构建任务启动"
echo "配置文件: ${CONFIG_FILE}"

# 如果需要从头构建，清理旧镜像
if [[ "${FROM_SCRATCH}" == "true" ]]; then
    echo "清理旧镜像..."
    docker rmi rbio:gpu rbio:cpu rbio:gpubase rbio:cpubase r-bio:R r-bio:base 2>/dev/null || true
fi

# 根据阶段开始构建
BUILD_STATUS=0

# Stage 1
if [[ "${STAGE}" -le 1 ]]; then
    if ! build_base; then
        BUILD_STATUS=1
        exit 1
    fi
    [[ "${BUILD_FINAL}" != "true" ]] && exit 0
fi

# Stage 2
if [[ "${STAGE}" -le 2 ]]; then
    if ! build_R; then
        BUILD_STATUS=1
        exit 1
    fi
    [[ "${BUILD_FINAL}" != "true" ]] && exit 0
fi

# Stage 3
if [[ "${STAGE}" -le 3 ]]; then
    if [[ "${BUILD_GPU}" == "true" ]]; then
        if ! build_gpu; then
            BUILD_STATUS=1
            exit 1
        fi
    else
        if ! build_cpu; then
            BUILD_STATUS=1
            exit 1
        fi
    fi
    [[ "${BUILD_FINAL}" != "true" ]] && exit 0
fi

# Stage 4 (final)
if ! build_final; then
    BUILD_STATUS=1
    exit 1
fi

echo ""
echo "========================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 构建任务完成"
echo "========================================"
echo ""
echo "可用镜像:"
docker images | grep -E "r-bio|rbio" || true
echo ""
echo "运行示例:"
echo "  # CPU 版本"
echo "  docker run -d -p 8787:8787 -p 8888:8888 -v /path/to/data:/data rbio:cpu"
echo ""
echo "  # GPU 版本"
echo "  docker run --gpus all -d -p 8787:8787 -p 8888:8888 -v /path/to/data:/data rbio:gpu"
echo ""

exit ${BUILD_STATUS}