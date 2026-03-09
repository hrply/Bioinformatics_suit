# =============================================================================
# Stage 4: Rbio_cuda
# Base: r-bio:cpu
# Purpose: 安装 CUDA 13.0 和 GPU 加速包
# =============================================================================

# syntax=docker/dockerfile:1

FROM r-bio:cpu

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
ENV http_proxy=${http_proxy:-}
ENV https_proxy=${https_proxy:-}
ENV GITHUB_PROXY=${github_proxy:-}
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}
ENV PIP_INDEX_URL=${PIP_INDEX_URL:-}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST:-}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

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
    && rm -rf /var/lib/apt/lists/*

# 设置 CUDA 环境变量
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64

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
# Stage 4d: PyTorch with CUDA 13.0 (cu130)
# Note: PyTorch 2.10.0 only supports cu130, not cu131
# Install first, scvi-tools/cellbender will use existing torch
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    torch torchvision --index-url https://download.pytorch.org/whl/cu130

# -----------------------------------------------------------------------------
# Stage 4e: JAX with CUDA 13
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir "jax[cuda13]"

# -----------------------------------------------------------------------------
# Stage 4f: TensorFlow GPU
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir tensorflow

# -----------------------------------------------------------------------------
# Stage 4g: CuPy for CUDA 13
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir cupy-cuda13x

# -----------------------------------------------------------------------------
# Stage 4h: GPU 加速单细胞包 (在 RAPIDS 之前安装)
# Note: 此时 torch 已安装，scvi-tools/cellbender 不会触发降级 cuda-bindings
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    scvi-tools \
    cellbender

# -----------------------------------------------------------------------------
# Stage 4i: CUDA Python bindings (升级前为 RAPIDS 准备)
# Upgrade cuda-bindings to 13.1.1 for RAPIDS compatibility
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    cuda-python==13.1.1 \
    cuda-bindings==13.1.1

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
# Stage 4k: rapids-singlecell (在 RAPIDS 之后安装)
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir rapids-singlecell

# -----------------------------------------------------------------------------
# Stage 4l: PyTorch Geometric
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir torch-geometric

# 清理临时文件
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip

WORKDIR /home/rstudio

CMD ["R"]