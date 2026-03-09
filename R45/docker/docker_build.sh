#!/bin/bash
# =============================================================================
# Rbio Docker 交互式构建脚本
# Usage: bash docker_build.sh [options]
# Options:
#   --stage N     从指定阶段开始构建 (1=base, 2=cpu, 3=gpu, 4=final)
#   --gpu         构建 GPU 版本 (包含 CUDA)
#   --final       构建最终镜像 (Jupyter Lab + RStudio)
#   --from-scratch 从头开始构建（清理旧镜像）
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
            echo "Usage: bash docker_build.sh [options]"
            echo ""
            echo "Options:"
            echo "  --stage N       从指定阶段开始构建"
            echo "                  1=base, 2=cpu, 3=gpu, 4=final"
            echo "  --gpu           构建 GPU 版本 (包含 CUDA)"
            echo "  --final         构建最终镜像 (Jupyter Lab + RStudio)"
            echo "  --from-scratch  从头开始构建（清理旧镜像）"
            echo "  --mirror        镜像源 (china/default)"
            echo "  --http-proxy    HTTP 代理地址 (影响整个构建)"
            echo "  --https-proxy   HTTPS 代理地址"
            echo "  --github-proxy  GitHub 代理地址 (仅用于 GitHub 下载)"
            echo "  -y, --no-interactive  跳过交互提示，使用默认值"
            echo ""
            echo "构建顺序:"
            echo "  Stage 1: Rbio_base.dockerfile    → r-bio:base"
            echo "  Stage 2: Rbio_cpu.dockerfile     → r-bio:cpu"
            echo "  Stage 3: Rbio_cuda.dockerfile    → r-bio:gpu"
            echo "  Stage 4: Rbio_final.dockerfile   → r-bio:cpu-final / r-bio:gpu-final"
            echo ""
            echo "中间镜像 (用于恢复构建):"
            echo "  Stage 1: r-bio:base-sys, base-cran, base-bioc, base-ml"
            echo "  Stage 2: r-bio:cpu-python, cpu-annotation, cpu-core, cpu-giotto,"
            echo "           cpu-scripts, cpu-cran, cpu-bioc, cpu-spatial-deps,"
            echo "           cpu-cellchat, cpu-trajectory"
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
    echo "1) 完整构建 (base → cpu → gpu → final)"
    echo "2) 从 cpu 阶段开始"
    echo "3) 仅构建 gpu 阶段"
    echo "4) 仅构建 final 阶段"
    read -p "请选择 [1/2/3/4] (默认: 1): " stage_choice
    case "${stage_choice}" in
        2)
            STAGE=2
            ;;
        3)
            STAGE=3
            BUILD_GPU=true
            ;;
        4)
            STAGE=4
            BUILD_FINAL=true
            ;;
        *)
            STAGE=1
            BUILD_GPU=true
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
if [[ "${BUILD_GPU}" == "true" && "${BUILD_FINAL}" == "false" && -z "$1" ]]; then
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

# 仅在完全交互模式下要求确认
if [[ -z "$1" ]]; then
    read -p "确认开始构建? [Y/n]: " confirm
    if [[ "${confirm}" =~ ^[Nn]$ ]]; then
        echo "构建已取消"
        exit 0
    fi
else
    echo "命令行参数已指定，自动确认..."
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
        "base-sys:r-bio:base-sys"
        "base-cran:r-bio:base-cran"
        "base-bioc:r-bio:base-bioc"
        "base-ml:r-bio:base-ml"
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

# Stage 2: CPU 构建
build_cpu() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 2: r-bio:cpu (多阶段)"
    local logfile="${LOG_DIR}/Rbio_cpu_${TIMESTAMP}.log"
    
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
        "cpu-python:r-bio:cpu-python"
        "cpu-annotation:r-bio:cpu-annotation"
        "cpu-core:r-bio:cpu-core"
        "cpu-giotto:r-bio:cpu-giotto"
        "cpu-scripts:r-bio:cpu-scripts"
        "cpu-cran:r-bio:cpu-cran"
        "cpu-bioc:r-bio:cpu-bioc"
        "cpu-spatial-deps:r-bio:cpu-spatial-deps"
        "cpu-cellchat:r-bio:cpu-cellchat"
        "cpu-trajectory:r-bio:cpu-trajectory"
        "cpu-final:r-bio:cpu"
    )
    
    for stage_info in "${stages[@]}"; do
        IFS=':' read -r target image_name <<< "${stage_info}"
        echo ""
        echo "构建 ${target}..."
        
        if ! docker build -f "${SCRIPT_DIR}/Rbio_cpu.dockerfile" \
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
    docker images | grep "r-bio.*cpu" || true
    return 0
}

# Stage 3: GPU 构建
build_gpu() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始构建 Stage 3: r-bio:gpu"
    local logfile="${LOG_DIR}/Rbio_gpu_${TIMESTAMP}.log"
    
    # 检查依赖镜像是否存在
    if ! docker images | grep -q "r-bio.*cpu"; then
        echo "ERROR: 依赖镜像 r-bio:cpu 不存在"
        return 1
    fi
    
    local build_args=$(generate_build_args)
    echo "日志文件: ${logfile}"
    echo "构建参数: ${build_args}"
    
    if ! docker build -f "${SCRIPT_DIR}/Rbio_cuda.dockerfile" \
        -t r-bio:gpu \
        ${build_args} \
        "${SCRIPT_DIR}" 2>&1 | tee "${logfile}"; then
        echo "ERROR: Stage 3 (gpu) 构建失败"
        return 1
    fi
    
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 3: r-bio:gpu 构建成功"
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
    
    # 构建 CPU Final
    if docker images | grep -q "r-bio.*cpu" && ! docker images | grep -q "r-bio:cpu-final"; then
        echo ""
        echo "构建 cpu-final (基于 r-bio:cpu)..."
        if ! docker build -f "${SCRIPT_DIR}/Rbio_final.dockerfile" \
            --target cpu-final \
            -t r-bio:cpu-final \
            ${build_args} \
            "${SCRIPT_DIR}" 2>&1 | tee -a "${logfile}"; then
            echo "ERROR: cpu-final 构建失败"
            return 1
        fi
        echo "[OK] r-bio:cpu-final 构建成功"
    fi
    
    # 构建 GPU Final
    if docker images | grep -q "r-bio.*gpu" && ! docker images | grep -q "r-bio:gpu-final"; then
        echo ""
        echo "构建 gpu-final (基于 r-bio:gpu)..."
        if ! docker build -f "${SCRIPT_DIR}/Rbio_final.dockerfile" \
            --target gpu-final \
            -t r-bio:gpu-final \
            ${build_args} \
            "${SCRIPT_DIR}" 2>&1 | tee -a "${logfile}"; then
            echo "ERROR: gpu-final 构建失败"
            return 1
        fi
        echo "[OK] r-bio:gpu-final 构建成功"
    fi
    
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stage 4: 最终镜像构建成功"
    echo ""
    echo "生成的镜像:"
    docker images | grep "r-bio.*final" || true
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
    docker rmi r-bio:gpu-final r-bio:cpu-final r-bio:gpu r-bio:cpu r-bio:base 2>/dev/null || true
fi

# 根据阶段开始构建
BUILD_STATUS=0

if [[ "${STAGE}" -le 1 ]]; then
    if ! build_base; then
        BUILD_STATUS=1
        exit 1
    fi
fi

if [[ "${STAGE}" -le 2 ]]; then
    if ! build_cpu; then
        BUILD_STATUS=1
        exit 1
    fi
fi

if [[ "${BUILD_GPU}" == "true" ]] || [[ "${STAGE}" -eq 3 ]]; then
    if ! build_gpu; then
        BUILD_STATUS=1
        exit 1
    fi
fi

if [[ "${BUILD_FINAL}" == "true" ]] || [[ "${STAGE}" -eq 4 ]]; then
    if ! build_final; then
        BUILD_STATUS=1
        exit 1
    fi
fi

echo ""
echo "========================================"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 构建任务完成"
echo "========================================"
echo ""
echo "可用镜像:"
docker images | grep "r-bio" || true
echo ""
echo "运行示例:"
echo "  # CPU 版本"
echo "  docker run -d -p 8787:8787 -p 8888:8888 -v /path/to/data:/data r-bio:cpu-final"
echo ""
echo "  # GPU 版本"
echo "  docker run --gpus all -d -p 8787:8787 -p 8888:8888 -v /path/to/data:/data r-bio:gpu-final"
echo ""

exit ${BUILD_STATUS}