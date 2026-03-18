# =============================================================================
# Stage 3: Rbio_CPU (CPU-only version)
# Base: r-bio:R
# Purpose: 安装 CPU 版本的深度学习框架 + 生信 Python 包（无 GPU 支持）
# 使用方法:
#   docker build -f Rbio_cpu.dockerfile -t rbio:cpubase .
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
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

# -----------------------------------------------------------------------------
# Stage 3a: pip 升级
# Note: CPU 版本不需要版本约束（RAPIDS 的约束仅适用于 GPU 版本）
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir --upgrade setuptools pip wheel

# -----------------------------------------------------------------------------
# Stage 3b: PyTorch (CPU version)
# Note: 使用 --index-url 强制只使用 CPU wheel，避免安装 GPU 版本
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# -----------------------------------------------------------------------------
# Stage 3c: JAX (默认即 CPU 版本)
# Note: JAX 0.4+ 默认安装即为 CPU 版本，无需指定 [cpu] extra
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir jax

# -----------------------------------------------------------------------------
# Stage 3d: TensorFlow CPU
# -----------------------------------------------------------------------------
# TensorFlow is deprecated

# -----------------------------------------------------------------------------
# Stage 3e: PyTorch Geometric (CPU version)
# -----------------------------------------------------------------------------
RUN . /opt/venv/bin/activate && \
    pip install --no-cache-dir torch-geometric

# -----------------------------------------------------------------------------
# Stage 3f: 生信业务包
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
# Stage 3g: 环境变量 + 清理
# -----------------------------------------------------------------------------
ENV PYTHONIOENCODING=utf-8

WORKDIR /home/rstudio

# 清理临时文件
RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /var/lib/apt/lists/*

CMD ["R"]