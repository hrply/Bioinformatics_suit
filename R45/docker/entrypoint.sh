#!/bin/bash
set -e

echo "========================================"
echo "  R-bio Final Container (GPU)"
echo "========================================"

# GPU 环境检查
gpu_check() {
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    echo -e "${YELLOW}[GPU Check] 正在检测 GPU 环境...${NC}"

    # 检查共享内存
    local SHM_SIZE_MB=$(df -m /dev/shm 2>/dev/null | awk 'NR==2 {print $2}')
    if [ -n "$SHM_SIZE_MB" ] && [ "$SHM_SIZE_MB" -lt 2048 ]; then
        echo -e "${RED}⚠️ 警告: 共享内存较小 ($SHM_SIZE_MB MB)，建议在 Compose 中设为 2g 以上。${NC}"
    fi

    # 检查 nvidia-smi
    if ! command -v nvidia-smi &>/dev/null; then
        echo -e "${RED}❌ 错误: 找不到 nvidia-smi，请检查宿主机驱动。${NC}"
        return 1
    fi

    # 检查 PyTorch CUDA
    local GPU_STATUS=$(/opt/venv/bin/python3 -c "import torch; print(torch.cuda.is_available())" 2>/dev/null)
    if [ "$GPU_STATUS" == "True" ]; then
        local VRAM_FREE=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null | awk '{s+=$1} END {print s}')
        local GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n 1)
        echo -e "${GREEN}✅ GPU 环境就绪${NC}"
        echo -e "   GPU: ${GPU_NAME}"
        echo -e "   可用显存: ${VRAM_FREE}MB"
    else
        echo -e "${RED}❌ 错误: PyTorch 无法识别 GPU。${NC}"
        return 1
    fi
}

# 执行 GPU 检查 (允许失败但给出警告)
gpu_check || echo "⚠️ GPU 检查未通过，部分功能可能受限"

echo "========================================"

# PATH变量配置
export PYTHONPATH="${CUSTOM_PYTHON}${PYTHONPATH:+:$PYTHONPATH}"
export PATH="${CUSTOM_PYTHON}/bin:${PATH}"
export R_LIBS_USER="${CUSTOM_R}${R_LIBS_USER:+:$R_LIBS_USER}"
# 持久化目录
CUSTOM_DIRS=(
    "/custom/python"
    "/custom/r"
    "/custom/.cache/python"
    "/custom/.cache/r"
    "/custom/.config/python"
    "/custom/.config/r"
    "/custom/.cache/pip"
)

# 确保 rstudio 用户存在
if ! id "${RSTUDIO_USER}" &>/dev/null; then
    # 强制指定 UID 为 1000（通常是宿主机第一个用户的 UID），方便权限对齐
    useradd -m -u 1000 -s /bin/bash "${RSTUDIO_USER}"
fi

# 让用户文件在宿主机可访问
echo "umask 002" >> /home/${RSTUDIO_USER}/.bashrc

# 配置 RStudio 用户密码
RSTUDIO_USER=${RSTUDIO_USER:-rstudio}
RSTUDIO_PASS=${RSTUDIO_PASS:-rstudio}

# 设置密码
echo "${RSTUDIO_USER}:${RSTUDIO_PASS}" | chpasswd

# 设置目录权限
for dir in "$CUSTOM_PATH" "/home/${RSTUDIO_USER}"; do
    mkdir -p "$dir"
    chown -R ${RSTUDIO_USER}:${RSTUDIO_USER} "$dir"
done

# 配置Rstudio及R LIBRARY
{
    echo "R_LIBS_USER=${R_LIBS_USER}"
    echo "R_USER_CACHE_DIR=${R_USER_CACHE_DIR}"
    echo "RETICULATE_PYTHON=/opt/venv/bin/python"
} >> /usr/local/lib/R/etc/Renviron.site

echo "RStudio Server:"
echo "  - URL: http://localhost:8787"
echo "  - User: ${RSTUDIO_USER}"
echo "  - Password: ${RSTUDIO_PASS}"

# 配置 Jupyter Token
JUPYTER_TOKEN=${JUPYTER_TOKEN:-}
if [ -z "${JUPYTER_TOKEN}" ]; then
    # 自动生成 token
    JUPYTER_TOKEN=$(openssl rand -hex 16)
fi

# 更新 Jupyter 配置
mkdir -p /home/${RSTUDIO_USER}/.jupyter
cat > /home/${RSTUDIO_USER}/.jupyter/jupyter_server_config.py <<JUPYTER_CONF
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.root_dir = '/data'
c.ServerApp.token = '${JUPYTER_TOKEN}'
c.IdentityProvider.token = '${JUPYTER_TOKEN}'
JUPYTER_CONF

chown -R ${RSTUDIO_USER}:${RSTUDIO_USER} /home/${RSTUDIO_USER}/.jupyter

echo "Jupyter Lab:"
echo "  - URL: http://localhost:8888"
echo "  - Token: ${JUPYTER_TOKEN}"
echo "========================================"

# 创建数据目录
mkdir -p /data
chown -R ${RSTUDIO_USER}:${RSTUDIO_USER} /data

# 启动 RStudio Server
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --www-port=8787 &

# 转到数据目录
cd /data
echo "Starting Jupyter Lab as foreground process..."

exec "$@"