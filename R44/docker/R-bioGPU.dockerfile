# R-bioGPU Dockerfile - GPU支持-精简镜像
# 精简版镜像以CPU版为基础复制CUDA工具包和GPU相关库，避免重复安装和构建
# 使用代理构建：docker build -t r-bio:gpu_v1.0.1 -f R-bioGPU.dockerfile --build-arg HTTP_PROXY=http://192.168.3.147:7890 --build-arg HTTPS_PROXY=http://192.168.3.147:7890 .
# 不使用代理（默认）: docker build -t r-bio:gpu_v1.0.1 -f R-bioGPU.dockerfile .

# ========================================
# Stage6: CUDA配置 + 生信GPU补充包
# ========================================
FROM r-bio:stage5 AS stage6

# 代理设置（仅用于构建，不内置于最终镜像）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=${GITHUB_TOKEN:-}
ENV GITHUB_PAT=${GITHUB_TOKEN:-}
ENV http_proxy=${HTTP_PROXY:-}
ENV https_proxy=${HTTPS_PROXY:-}
ENV HTTP_PROXY=${HTTP_PROXY:-}
ENV HTTPS_PROXY=${HTTPS_PROXY:-}
ENV no_proxy=localhost,127.0.0.1

# 安装CUDA仓库
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 添加NVIDIA CUDA仓库
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    rm cuda-keyring_1.1-1_all.deb

# 更新并安装CUDA Toolkit 13.0.2
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cuda-toolkit-13-0 \
    && rm -rf /var/lib/apt/lists/*

# 设置CUDA环境变量
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# 安装cuDNN (使用cuda-13版本)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcudnn9-cuda-13 \
    libcudnn9-dev-cuda-13 \
    && rm -rf /var/lib/apt/lists/*

# 安装PyTorch with CUDA 13支持
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu130

# 安装GPU版本的Python包 (CUDA 13)
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir cupy-cuda13x

# 安装GPU版本的scanpy生态包
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir scanpy

# 在venv中安装RAPIDS (CUDA 13版本)
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    cudf-cu13 \
    cuml-cu13 \
    cugraph-cu13 \
    rapids

# ========================================
# 生信GPU加速补充包
# ========================================

# 安装 scvi-tools (单细胞深度学习)
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir scvi-tools

# 安装 cellbender (单细胞去噪)
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir cellbender

# 安装 JAX with CUDA支持
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir "jax[cuda13]"

# 安装 TensorFlow (GPU版本)
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir tensorflow

# 安装 PyTorch Geometric (图神经网络)
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir torch-geometric

# 清理临时文件
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/R /root/.cache/pip

# ========================================
# Final Stage: GPU运行时镜像
# ========================================
FROM r-bio:cpu_v1.0.1 AS gpu-runtime

# 设置环境变量
ENV PATH="/opt/venv/bin:/opt/r-miniconda/bin:/usr/local/cuda/bin:${PATH}"
ENV RETICULATE_MINICONDA_ENABLED=FALSE
ENV RETICULATE_MINICONDA_PATH=/opt/r-miniconda
ENV HDF5_PLUGIN_PATH=/lzf
ENV PASSWORD=rstudio
ENV USER=rstudio
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# 复制 CUDA Toolkit (只复制实际目录，避免符号链接解引用导致的重复)
COPY --from=stage6 /usr/local/cuda-13.0 /usr/local/cuda-13.0
# 创建符号链接
RUN ln -s /usr/local/cuda-13.0 /usr/local/cuda-13 && \
    ln -s /usr/local/cuda-13.0 /usr/local/cuda

# 复制 cuDNN 库
COPY --from=stage6 /usr/lib/x86_64-linux-gnu/libcudnn* /usr/lib/x86_64-linux-gnu/

# 复制更新后的 Python venv (含 GPU 包)
COPY --from=stage6 /opt/venv /opt/venv

# 确保 rstudio 用户存在并设置密码
RUN (useradd -m -s /bin/bash rstudio 2>/dev/null || echo "User already exists") && \
    echo "rstudio:rstudio" | chpasswd

# 创建工作目录
RUN mkdir -p /home/rstudio /workspace && \
    chown -R rstudio:rstudio /home/rstudio /workspace

# 暴露端口
EXPOSE 8787 3838

# 启动脚本
COPY --chmod=755 <<'EOF' /init.sh
#!/bin/bash
set -e
service rstudio-server start &
/usr/bin/shiny-server &
# 保持容器前台运行
sleep infinity
EOF

CMD ["/init.sh"]