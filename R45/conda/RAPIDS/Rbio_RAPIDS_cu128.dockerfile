# 选用官方 RAPIDS 25.06 (CUDA 12.8 + Python 3.12)
FROM rapidsai/base:25.06-cuda12.8-py3.12

USER root

# -----------------------------------------------------------------------------
# 1. 基础环境配置与源设置
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
# 主力使用清华源加速
ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
# 增加 NVIDIA 官方源，防止 RAPIDS 底层 C++ 依赖丢失
ENV PIP_EXTRA_INDEX_URL=https://pypi.nvidia.com

# Build Arguments
ARG mirror=default
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN
ARG APT_MIRROR

# Environment Variables
ENV TZ="Etc/UTC"
ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}

# 设置 apt-get 国内镜像逻辑
RUN if [ "${mirror}" = "china" ] || [ "${mirror}" = "China" ] || [ -n "${APT_MIRROR}" ]; then \
        APT_MIRROR_URL="${APT_MIRROR:-https://mirrors.tuna.tsinghua.edu.cn/ubuntu}"; \
        if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
            sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list.d/ubuntu.sources && \
            sed -i "s|http://security.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list.d/ubuntu.sources; \
        elif [ -f /etc/apt/sources.list ]; then \
            sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list && \
            sed -i "s|http://security.ubuntu.com/ubuntu|${APT_MIRROR_URL}|g" /etc/apt/sources.list; \
        fi; \
    fi

RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# -----------------------------------------------------------------------------
# 2. 补齐系统级依赖 & R 语言环境 (整合 GDAL 路径与 R 编译库)
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential python3-dev wget curl git tmux \
    cmake gfortran libopenblas-dev liblapack-dev \
    libxml2-dev zlib1g-dev libbz2-dev liblzma-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libgl1 \
    libproj-dev libgeos-dev libgdal-dev gdal-bin \
    libgmp3-dev graphviz \
    r-base r-base-dev \
    libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ENV R_HOME=/usr/lib/R
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

# -----------------------------------------------------------------------------
# 3. 确立“全局环境天条” & 基础算力层 (严格锁死 RAPIDS 25.06 的上限)
# -----------------------------------------------------------------------------
# 将越界的 UI库、数据分析库以及 Python 绑定库全部限制在 RAPIDS 25.06 的要求内
RUN echo "bokeh<=3.6.3" > /tmp/constraints.txt && \
    echo "shapely<2.1.0" >> /tmp/constraints.txt && \
    echo "scikit-image<0.26.0" >> /tmp/constraints.txt && \
    echo "pandas<2.2.4" >> /tmp/constraints.txt && \
    echo "cuda-python<12.0" >> /tmp/constraints.txt
ENV PIP_CONSTRAINT=/tmp/constraints.txt

RUN pip install --no-cache-dir --upgrade setuptools pip wheel

# 先行主动降级这些容易被下游生信包带偏的依赖
RUN pip install --no-cache-dir \
    "bokeh<=3.6.3" \
    "shapely<2.1.0" \
    "scikit-image<0.26.0" \
    "pandas<2.2.4"

# 补齐 cucim 虚假报错所需的 12x 图像编解码器
RUN pip install --no-cache-dir nvidia-nvimgcodec-cu12

# 使用 cu124 源安装 PyTorch (CUDA 12.8 兼容最好的预编译版本)
RUN pip install --no-cache-dir \
    torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu124

RUN pip install --no-cache-dir \
    torch-geometric \
    rapids-singlecell \
    "jax[cuda13]"

# -----------------------------------------------------------------------------
# 4. 常规依赖与生信业务全家桶 (55个核心包无损保留)
# -----------------------------------------------------------------------------
RUN pip install --no-cache-dir \
    scipy pandas numpy matplotlib seaborn \
    h5py tables zarr pyarrow scrublet \
    adjustText joblib pydot python-igraph \
    leidenalg umap-learn phate \
    "scanpy>=1.12" "scvi-tools>=1.2.0" cellbender \
    "anndata>=0.10" muon flowio FlowKit \
    PyCytoData PhenoGraph \
    harmonypy bbknn scirpy pertpy cellrank liana \
    snapatac2 ktplotspy cellphonedb \
    scvelo squidpy gseapy decoupler \
    rpy2 anndata2ri \
    pydeseq2 pybiomart diffxpy \
    statsmodels statannotations pingouin \
    pynndescent scikit-network scikit-learn \
    scikit-misc scikit-survival \
    google-generativeai python-dotenv \
    ipykernel ipywidgets jupyterlab \
    nbformat nbconvert

# -----------------------------------------------------------------------------
# 5. 运行环境调优
# -----------------------------------------------------------------------------
ENV RMM_ALLOCATOR=managed
ENV PYTHONIOENCODING=utf-8
ENV PATH=/root/.local/bin:$PATH
ENV PIP_CONSTRAINT=
WORKDIR /data

RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /var/lib/apt/lists/*

# 采用 umask 000 解决容器内外读写权限隔离问题
RUN echo "umask 000" >> /root/.bashrc && \
    echo 'echo "--- [Rbio AI-GPU Ultimate 2026] ---"' >> /root/.bashrc && \
    echo 'echo "GPU 状态: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)"' >> /root/.bashrc

# -----------------------------------------------------------------------------
# 6. 自动化启动检查 (Entrypoint)
# -----------------------------------------------------------------------------
RUN cat << 'EOF' > /usr/local/bin/init.sh
#!/bin/bash
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 [System Check] 正在执行启动前环境审计 (Root Mode)...${NC}"

SHM_SIZE_MB=$(df -m /dev/shm | awk 'NR==2 {print $2}')
if [ "$SHM_SIZE_MB" -lt 2048 ]; then
    echo -e "${RED}⚠️ 警告: 共享内存较小 ($SHM_SIZE_MB MB)，建议在 Compose 中设为 2g 以上。${NC}"
fi

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
exec "$@"
EOF

RUN chmod +x /usr/local/bin/init.sh
ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["/bin/bash"]