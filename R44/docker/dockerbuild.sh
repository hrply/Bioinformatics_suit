#!/bin/bash
# R-bio Docker镜像构建脚本
# 交互式选择镜像类型和代理配置
# 支持自动构建依赖镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认值
DEFAULT_PROXY="http://127.0.0.1:7890"
TEST_MODE=false
IMAGE_PREFIX="r-bio"

# 日志目录
LOG_DIR=".test/logs"
mkdir -p "$LOG_DIR"

# 构建日志文件名生成函数
generate_log_name() {
    local image_type=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "${LOG_DIR}/docker_build_rbio_${image_type}_${timestamp}.log"
}

# 检查镜像是否存在
check_image_exists() {
    local tag=$1
    docker image inspect "$tag" &>/dev/null
}

# 构建函数
build_image() {
    local dockerfile=$1
    local tag=$2
    local target=$3
    local proxy_args=$4
    local log_file=$5
    
    local build_cmd="docker build -t ${tag} -f ${dockerfile}"
    
    if [ -n "$target" ]; then
        build_cmd="${build_cmd} --target ${target}"
    fi
    
    if [ -n "$proxy_args" ]; then
        build_cmd="${build_cmd} ${proxy_args}"
    fi
    
    build_cmd="${build_cmd} ."
    
    echo -e "${CYAN}构建命令: ${build_cmd}${NC}"
    echo -e "${CYAN}日志文件: ${log_file}${NC}"
    echo ""
    
    if eval "$build_cmd 2>&1 | tee $log_file"; then
        echo -e "${GREEN}✓ ${tag} 构建成功${NC}"
        return 0
    else
        echo -e "${RED}✗ ${tag} 构建失败，请查看日志: ${log_file}${NC}"
        return 1
    fi
}

# 构建R-bioBase（生成stage1, stage2, stage5）
build_base_stages() {
    local proxy_args=$1
    local stages=("stage1" "stage2" "stage5")
    
    echo -e "${CYAN}======================================"
    echo "构建 R-bioBase 基础镜像阶段"
    echo "======================================${NC}"
    
    for stage in "${stages[@]}"; do
        local tag="${IMAGE_PREFIX}:${stage}"
        local log_file=$(generate_log_name "${stage}")
        
        if check_image_exists "$tag"; then
            echo -e "${YELLOW}镜像 ${tag} 已存在，跳过构建${NC}"
            echo -e "${YELLOW}如需重新构建，请先删除: docker rmi ${tag}${NC}"
        else
            echo ""
            echo -e "${GREEN}>>> 构建 ${stage}...${NC}"
            build_image "R-bioBase.dockerfile" "$tag" "$stage" "$proxy_args" "$log_file" || return 1
        fi
    done
    
    return 0
}

# 构建CPU镜像
build_cpu_image() {
    local proxy_args=$1
    local tag="${IMAGE_PREFIX}:cpu_v1.0.0"
    local log_file=$(generate_log_name "cpu")
    
    # 检查依赖
    echo -e "${CYAN}检查 CPU 镜像依赖...${NC}"
    local missing_deps=()
    for dep in "stage1" "stage2" "stage5"; do
        if ! check_image_exists "${IMAGE_PREFIX}:${dep}"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}缺少依赖镜像: ${missing_deps[*]}${NC}"
        echo -n -e "${BLUE}是否构建缺失的依赖? [Y/n]: ${NC}"
        read -r confirm
        confirm=${confirm:-Y}
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            build_base_stages "$proxy_args" || return 1
        else
            echo -e "${RED}缺少依赖，无法构建 CPU 镜像${NC}"
            return 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}>>> 构建 CPU 镜像...${NC}"
    build_image "R-bioCPU.dockerfile" "$tag" "" "$proxy_args" "$log_file" || return 1
    
    return 0
}

# 构建Simple镜像
build_simple_image() {
    local proxy_args=$1
    local tag="${IMAGE_PREFIX}:simple"
    local log_file=$(generate_log_name "simple")
    
    # 检查依赖
    echo -e "${CYAN}检查 Simple 镜像依赖...${NC}"
    local missing_deps=()
    for dep in "stage1" "stage2" "stage5"; do
        if ! check_image_exists "${IMAGE_PREFIX}:${dep}"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}缺少依赖镜像: ${missing_deps[*]}${NC}"
        echo -n -e "${BLUE}是否构建缺失的依赖? [Y/n]: ${NC}"
        read -r confirm
        confirm=${confirm:-Y}
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            build_base_stages "$proxy_args" || return 1
        else
            echo -e "${RED}缺少依赖，无法构建 Simple 镜像${NC}"
            return 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}>>> 构建 Simple 镜像...${NC}"
    build_image "R-bioSimple.dockerfile" "$tag" "" "$proxy_args" "$log_file" || return 1
    
    return 0
}

# 构建GPU镜像
build_gpu_image() {
    local proxy_args=$1
    local tag="${IMAGE_PREFIX}:gpu_v1.0.0"
    local log_file=$(generate_log_name "gpu")
    
    # 检查依赖 - GPU需要CPU镜像
    echo -e "${CYAN}检查 GPU 镜像依赖...${NC}"
    if ! check_image_exists "${IMAGE_PREFIX}:cpu_v1.0.0"; then
        echo -e "${YELLOW}缺少依赖镜像: cpu_v1.0.0${NC}"
        echo -n -e "${BLUE}是否构建 CPU 镜像? [Y/n]: ${NC}"
        read -r confirm
        confirm=${confirm:-Y}
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            build_cpu_image "$proxy_args" || return 1
        else
            echo -e "${RED}缺少依赖，无法构建 GPU 镜像${NC}"
            return 1
        fi
    fi
    
    # GPU还需要stage5用于构建stage6
    if ! check_image_exists "${IMAGE_PREFIX}:stage5"; then
        echo -e "${YELLOW}缺少依赖镜像: stage5${NC}"
        echo -n -e "${BLUE}是否构建缺失的依赖? [Y/n]: ${NC}"
        read -r confirm
        confirm=${confirm:-Y}
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            build_base_stages "$proxy_args" || return 1
        else
            echo -e "${RED}缺少依赖，无法构建 GPU 镜像${NC}"
            return 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}>>> 构建 GPU 镜像...${NC}"
    build_image "R-bioGPU.dockerfile" "$tag" "" "$proxy_args" "$log_file" || return 1
    
    return 0
}

# 构建GPUfull镜像
build_gpufull_image() {
    local proxy_args=$1
    local tag="${IMAGE_PREFIX}:gpufull"
    local log_file=$(generate_log_name "gpufull")
    
    # 检查依赖 - GPUfull需要CPU镜像
    echo -e "${CYAN}检查 GPUfull 镜像依赖...${NC}"
    if ! check_image_exists "${IMAGE_PREFIX}:cpu_v1.0.0"; then
        echo -e "${YELLOW}缺少依赖镜像: cpu_v1.0.0${NC}"
        echo -n -e "${BLUE}是否构建 CPU 镜像? [Y/n]: ${NC}"
        read -r confirm
        confirm=${confirm:-Y}
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            build_cpu_image "$proxy_args" || return 1
        else
            echo -e "${RED}缺少依赖，无法构建 GPUfull 镜像${NC}"
            return 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}>>> 构建 GPUfull 镜像...${NC}"
    build_image "R-bioGPUfull.dockerfile" "$tag" "" "$proxy_args" "$log_file" || return 1
    
    return 0
}

# 主程序
echo -e "${CYAN}"
echo "======================================================"
echo "            R-bio Docker 镜像构建工具"
echo "请务必确认已经设置GITHUB_PAT环境变量以避免GitHub API限制"
echo "======================================================"
echo -e "${NC}"

# 询问是否为测试模式
echo -e "${YELLOW}是否使用测试模式（使用新镜像名避免覆盖）?${NC}"
echo -n -e "${BLUE}[y/N]: ${NC}"
read -r test_mode_input
if [[ "$test_mode_input" =~ ^[Yy]$ ]]; then
    TEST_MODE=true
    IMAGE_PREFIX="r-bio-test"
    echo -e "${GREEN}测试模式已启用，镜像前缀: ${IMAGE_PREFIX}${NC}"
fi
echo ""

# 选择镜像类型
echo -e "${YELLOW}请选择要构建的镜像类型:${NC}"
echo ""
echo "  1) Base   - 基础镜像 (构建 stage1, stage2, stage5)"
echo "  2) Simple - 精简版 (基于rocker/tidyverse + 复制stage文件)"
echo "  3) CPU    - CPU版本 (基于stage1 + 复制stage文件)"
echo "  4) GPU    - GPU版本 (基于CPU + stage5构建CUDA)"
echo "  5) GPUfull- GPU完整版 (基于CPU直接安装CUDA)"
echo "  6) 全部   - 按依赖顺序构建所有镜像"
echo ""
echo -n -e "${BLUE}请输入选项 [1-6]: ${NC}"
read -r image_choice

# 询问代理配置
echo ""
echo -e "${YELLOW}是否使用代理?${NC}"
echo ""
echo "  1) 是，使用代理"
echo "  2) 否，不使用代理"
echo "  3) 使用默认代理 (${DEFAULT_PROXY})"
echo ""
echo -n -e "${BLUE}请输入选项 [1-3, 默认3]: ${NC}"
read -r proxy_choice
proxy_choice=${proxy_choice:-3}

case $proxy_choice in
    1)
        echo -n -e "${BLUE}请输入代理地址 (如 http://192.168.3.147:7890): ${NC}"
        read -r proxy_address
        if [ -z "$proxy_address" ]; then
            echo -e "${RED}代理地址不能为空，退出。${NC}"
            exit 1
        fi
        PROXY_ARGS="--build-arg HTTP_PROXY=${proxy_address} --build-arg HTTPS_PROXY=${proxy_address}"
        echo -e "${GREEN}将使用代理: ${proxy_address}${NC}"
        ;;
    2)
        PROXY_ARGS=""
        echo -e "${GREEN}不使用代理${NC}"
        ;;
    3|*)
        PROXY_ARGS="--build-arg HTTP_PROXY=${DEFAULT_PROXY} --build-arg HTTPS_PROXY=${DEFAULT_PROXY}"
        echo -e "${GREEN}将使用默认代理: ${DEFAULT_PROXY}${NC}"
        ;;
esac

echo ""

# 确认构建
echo -e "${CYAN}======================================"
echo "构建配置确认:"
echo "======================================${NC}"
echo -e "  镜像前缀:   ${GREEN}${IMAGE_PREFIX}${NC}"
if [ -n "$PROXY_ARGS" ]; then
    echo -e "  代理设置:   ${GREEN}已配置${NC}"
else
    echo -e "  代理设置:   ${YELLOW}未配置${NC}"
fi
echo ""

echo -n -e "${BLUE}确认开始构建? [Y/n]: ${NC}"
read -r confirm
confirm=${confirm:-Y}

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}已取消构建。${NC}"
    exit 0
fi

echo ""

# 执行构建
case $image_choice in
    1)
        build_base_stages "$PROXY_ARGS" || exit 1
        ;;
    2)
        build_simple_image "$PROXY_ARGS" || exit 1
        ;;
    3)
        build_cpu_image "$PROXY_ARGS" || exit 1
        ;;
    4)
        build_gpu_image "$PROXY_ARGS" || exit 1
        ;;
    5)
        build_gpufull_image "$PROXY_ARGS" || exit 1
        ;;
    6)
        echo -e "${CYAN}======================================"
        echo "按依赖顺序构建所有镜像"
        echo "======================================${NC}"
        echo ""
        
        # 1. 构建Base阶段
        build_base_stages "$PROXY_ARGS" || exit 1
        
        # 2. 构建Simple和CPU（可并行，但这里顺序执行）
        echo ""
        build_simple_image "$PROXY_ARGS" || exit 1
        echo ""
        build_cpu_image "$PROXY_ARGS" || exit 1
        
        # 3. 构建GPU和GPUfull
        echo ""
        build_gpu_image "$PROXY_ARGS" || exit 1
        echo ""
        build_gpufull_image "$PROXY_ARGS" || exit 1
        ;;
    *)
        echo -e "${RED}无效选项，退出。${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}======================================"
echo "所有构建任务完成!"
echo "======================================${NC}"
echo ""
echo -e "已构建镜像列表:"
docker images | grep -E "^${IMAGE_PREFIX}\s+" | head -20
echo ""
echo -e "运行示例:"
echo -e "  ${CYAN}docker run -d -p 8787:8787 -e PASSWORD=yourpassword ${IMAGE_PREFIX}:simple${NC}"
echo -e "  ${CYAN}docker run -d -p 8787:8787 -e PASSWORD=yourpassword ${IMAGE_PREFIX}:cpu_v1.0.0${NC}"