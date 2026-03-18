# =============================================================================
# Stage 3: Rbio_RAPIDS (GPU version)
# Base: r-bio:R
# Purpose: 安装 CUDA 13.0 + RAPIDS + GPU 加速包
# 使用方法:
#   docker build -f Rbio_gpu.dockerfile -t rbio:gpubase .
# =============================================================================

# syntax=docker/dockerfile:1

FROM r-bio:R

# 确保以 root 用户运行，避免权限问题
USER root

# -----------------------------------------------------------------------------
# Build Arguments
# 注意：PIP_INDEX_URL 等参数继承自 base 镜像，此处声明以支持 build-arg 传递
# -----------------------------------------------------------------------------
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG GITHUB_TOKEN
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------
ENV TZ="Etc/UTC"
ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}
ENV PIP_INDEX_URL=${PIP_INDEX_URL:-}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST:-}
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
# NVIDIA PyPI 源，用于 RAPIDS 底层 C++ 依赖
ENV PIP_EXTRA_INDEX_URL=https://pypi.nvidia.com
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

# -----------------------------------------------------------------------------
# Stage 4a: CUDA 仓库设置
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 添加 NVIDIA CUDA 仓库
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    rm cuda-keyring_1.1-1_all.deb

# -----------------------------------------------------------------------------
# Stage 4b: CUDA Toolkit 13.0
# -----------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cuda-toolkit-13-0 \
    locales && \
    locale-gen en_US.UTF-8

# 设置 CUDA 环境变量
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH:-}
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# 创建符号链接
RUN ln -s /usr/local/cuda-13.0 /usr/local/cuda

# -----------------------------------------------------------------------------
# Stage 4c: CUDA 13 核心库 (cuDNN, cuSPARSE, cuBLAS, cuRAND, cuFFT)
# -----------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcudnn9-cuda-13 \
    libcudnn9-dev-cuda-13 \
    libcusparse-dev-13-0 \
    libcublas-dev-13-0 \
    libcurand-dev-13-0 \
    libcufft-dev-13-0 \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Stage 4d: 版本约束 + pip 升级 + 预降级冲突包
# -----------------------------------------------------------------------------
# 创建版本约束文件，避免 RAPIDS 依赖冲突
RUN echo "bokeh<=3.6.3" > /tmp/constraints.txt && \
    echo "holoviews<1.21.0" >> /tmp/constraints.txt && \
    echo "scikit-image<0.26.0,>=0.25.0" >> /tmp/constraints.txt && \
    echo "cupy-cuda13x>=13.6.0" >> /tmp/constraints.txt && \
    echo "shapely<2.1.0" >> /tmp/constraints.txt && \
    echo "nvidia-nvimgcodec-cu13<0.8.0,>=0.7.0" >> /tmp/constraints.txt
ENV PIP_CONSTRAINT=/tmp/constraints.txt

# 升级 pip 工具链
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade setuptools pip wheel

# 预降级冲突包，为后续依赖提供干净环境
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    "bokeh<=3.6.3" \
    "holoviews<1.21.0" \
    "scikit-image<0.26.0,>=0.25.0" \
    "shapely<2.1.0" \
    "nvidia-nvimgcodec-cu13<0.8.0,>=0.7.0"

# -----------------------------------------------------------------------------
# Stage 4e: PyTorch with CUDA 13.0 (cu130)
# Note: 使用 --extra-index-url 而非 --index-url，避免覆盖国内源和 NVIDIA 源
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    torch torchvision torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu130

# -----------------------------------------------------------------------------
# Stage 4f: JAX with CUDA 13
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir "jax[cuda13]"

# -----------------------------------------------------------------------------
# Stage 4g: TensorFlow GPU
# -----------------------------------------------------------------------------
# TensorFlow is deprecated

# -----------------------------------------------------------------------------
# Stage 4h: CuPy for CUDA 13
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir cupy-cuda13x

# -----------------------------------------------------------------------------
# Stage 4i: CUDA Python bindings (升级前为 RAPIDS 准备)
# Upgrade cuda-bindings to 13.0.3 for RAPIDS compatibility
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    cuda-python==13.0.3 \
    cuda-bindings==13.0.3

# -----------------------------------------------------------------------------
# Stage 4j: RAPIDS for CUDA 13
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    cudf-cu13 \
    cuml-cu13 \
    cugraph-cu13 \
    rapids

# -----------------------------------------------------------------------------
# Stage 4k: rapids-singlecell + PyTorch Geometric
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    rapids-singlecell \
    torch-geometric

# -----------------------------------------------------------------------------
# Stage 4l: 补充生信业务包
# Note: 包含已有包的版本约束，让 pip 进行全局版本校验，防止隐式降级
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    "scanpy>=1.12" \
    "anndata>=0.10" \
    scipy pandas numpy matplotlib seaborn \
    h5py tables zarr pyarrow scrublet \
    adjustText joblib pydot python-igraph \
    leidenalg louvain umap-learn phate \
    "scvi-tools>=1.2.0" \
    cellbender cell2location \
    muon flowio FlowKit \
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
# Stage 4m: 环境变量 + 清理
# -----------------------------------------------------------------------------
ENV RMM_ALLOCATOR=managed
ENV PYTHONIOENCODING=utf-8
ENV PIP_CONSTRAINT=

WORKDIR /home/rstudio

# 清理临时文件
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /var/lib/apt/lists/*

CMD ["R"]