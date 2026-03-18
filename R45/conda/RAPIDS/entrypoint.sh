#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 [System Check] 正在执行启动前环境审计...${NC}"

# ---------------------------------------------------------
# 1. 初始化高速缓存目录 (/tmp挂载至独立SSD)
# ---------------------------------------------------------
echo -e "${YELLOW}📂 初始化高速缓存目录...${NC}"
mkdir -p /tmp/numba_cache /tmp/cupy_cache /tmp/joblib_cache
chmod -R 777 /tmp/numba_cache /tmp/cupy_cache /tmp/joblib_cache

# ---------------------------------------------------------
# 2. 共享内存检查
# ---------------------------------------------------------
SHM_SIZE_MB=$(df -m /dev/shm | awk 'NR==2 {print $2}')
if [ "$SHM_SIZE_MB" -lt 2048 ]; then
    echo -e "${RED}⚠️ 警告: 共享内存较小 ($SHM_SIZE_MB MB)，建议在 Compose 中设为 2g 以上。${NC}"
fi

# ---------------------------------------------------------
# 3. GPU 与 PyTorch 识别检查
# ---------------------------------------------------------
if command -v nvidia-smi &> /dev/null; then
    GPU_STATUS=$(python3 -c "import torch; print(torch.cuda.is_available())" 2>/dev/null)
    if [ "$GPU_STATUS" == "True" ]; then
        VRAM_FREE=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits | awk '{s+=$1} END {print s}')
        echo -e "${GREEN}✅ [Pass] GPU 环境就绪。当前可用显存: ${VRAM_FREE}MB${NC}"
    else
        echo -e "${RED}❌ 错误: PyTorch 无法识别 GPU。${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 错误: 找不到 nvidia-smi，请检查宿主机驱动。${NC}"
    exit 1
fi

echo "----------------------------------------------------------------"
# 交出控制权，执行 Compose 中的 command
exec "$@"