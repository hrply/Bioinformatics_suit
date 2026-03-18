# =============================================================================
# Rbio_final.dockerfile - 最终镜像构建
# =============================================================================
#
# 两层构建:
#   1. cpu: 基于 r-bio:cpubase，安装 Jupyter Lab + 配置服务
#   2. gpu: 基于 r-bio:gpubase，安装 Jupyter Lab + 配置服务
#
# 构建流程:
#   CPU: base → R → CPU → final
#   GPU: base → R → RAPIDS → final
#
# 用户认证环境变量:
#   RSTUDIO_USER    - RStudio 用户名 (默认: rstudio)
#   RSTUDIO_PASS    - RStudio 密码 (默认: rstudio，强烈建议修改)
#   JUPYTER_TOKEN   - Jupyter Lab Token (默认: 无，未设置时自动生成)
#
# 使用方法:
#   docker build -f Rbio_final.dockerfile --target cpu -t rbio:cpu .
#   docker build -f Rbio_final.dockerfile --target gpu -t rbio:gpu .
#
#   docker run -d -p 8787:8787 -p 8888:8888 \
#     -e RSTUDIO_USER=myuser \
#     -e RSTUDIO_PASS=mypassword \
#     -e JUPYTER_TOKEN=mytoken \
#     -v /path/to/data:/data rbio:cpu
#
# =============================================================================

# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# Stage 1: CPU 最终镜像
# Base: rbio:cpubase (已包含 CPU 版本的 PyTorch/JAX/TensorFlow + 生信 Python 包)
# 继承环境变量: CRAN_URL, BIOC_URL, GITHUB_PROXY, http_proxy, https_proxy,
#               PIP_INDEX_URL, PIP_TRUSTED_HOST, PATH, VIRTUAL_ENV
# -----------------------------------------------------------------------------
FROM rbio:cpubase AS cpu

ARG JUPYTERLAB_VERSION=4.3.5

# 重新声明 ARG 以便在 RUN 中使用
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG CRAN_URL
ARG BIOC_URL
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST

# -----------------------------------------------------------------------------
# 用户认证环境变量 (运行时可覆盖)
# -----------------------------------------------------------------------------
ENV RSTUDIO_USER=rstudio
ENV RSTUDIO_PASS=rstudio
ENV JUPYTER_TOKEN=

# 其他环境变量
ENV JUPYTERLAB_VERSION=${JUPYTERLAB_VERSION}
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV GITHUB_PROXY=${github_proxy}
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

# -----------------------------------------------------------------------------
# 1a: 安装 Jupyter Lab + R kernel
# -----------------------------------------------------------------------------
RUN /opt/venv/bin/pip install --no-cache-dir \
    jupyterlab==${JUPYTERLAB_VERSION} \
    "notebook<7.0.0" \
    ipykernel \
    ipywidgets \
    jupyter-client

# R kernel for Jupyter
RUN echo "PATH=/opt/venv/bin:${PATH}" >> /usr/local/lib/R/etc/Renviron.site && \
    Rscript -e "install.packages('IRkernel', repos = Sys.getenv('CRAN_URL'))" && \
    Rscript -e "IRkernel::installspec(user = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

# Jupyter 配置 (运行时由启动脚本处理认证)
RUN mkdir -p /home/rstudio/.jupyter \
    && printf '%s\n' \
    "c.ServerApp.ip = '0.0.0.0'" \
    "c.ServerApp.port = 8888" \
    "c.ServerApp.open_browser = False" \
    "c.ServerApp.allow_root = True" \
    "c.ServerApp.root_dir = '/data'" > /home/rstudio/.jupyter/jupyter_server_config.py \
    && chown -R rstudio:rstudio /home/rstudio/.jupyter

# -----------------------------------------------------------------------------
# 1b: Shiny 扩展 R 包 (shiny 已安装)
# -----------------------------------------------------------------------------
RUN Rscript -e "options(repos = c(CRAN = Sys.getenv('CRAN_URL'))); install.packages(c('shinydashboard', 'shinythemes', 'shinyjs', 'shinyWidgets'), Ncpus = 4)" \
    && rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# 1c: 配置 RStudio Server
# -----------------------------------------------------------------------------
RUN echo "www-port=8787" >> /etc/rstudio/rserver.conf \
    && echo "auth-minimum-user-id=1000" >> /etc/rstudio/rserver.conf \
    && echo "session-default-working-dir=/data" >> /etc/rstudio/rsession.conf \
    && echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site

# -----------------------------------------------------------------------------
# 1d: 复制外部脚本并清除缓存
# -----------------------------------------------------------------------------
COPY external_files/ScType /usr/local/lib/R/site-library/ScType
COPY external_files/RaceID /usr/local/lib/R/site-library/RaceID

RUN echo '# ScType entry point' > /usr/local/lib/R/site-library/ScType/R/ScType.R \
    && echo 'source("/usr/local/lib/R/site-library/ScType/R/sctype_wrapper.R")' >> /usr/local/lib/R/site-library/ScType/R/ScType.R

RUN rm -rf /tmp/* /var/tmp/* /root/.cache/R /root/.cache/pip

# -----------------------------------------------------------------------------
# 1e: 启动脚本 (支持环境变量配置认证)
# -----------------------------------------------------------------------------
COPY --chmod=755 <<'EOF' /usr/local/bin/entrypoint.sh
#!/bin/bash
set -e

echo "========================================"
echo "  R-bio Final Container (CPU)"
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
for dir in "${CUSTOM_DIRS[@]}" "/home/${RSTUDIO_USER}"; do
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
EOF

EXPOSE 8787 8888
VOLUME ["/data", "/home/rstudio"]
WORKDIR /data

ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]

# =============================================================================
# Stage 2: GPU 最终镜像
# Base: rbio:gpubase (已包含 CUDA + GPU Python 包)
# 继承环境变量同上
# -----------------------------------------------------------------------------
FROM r-bio:gpubase AS gpu

ARG JUPYTERLAB_VERSION=4.3.5

# 重新声明 ARG
ARG http_proxy
ARG https_proxy
ARG github_proxy
ARG CRAN_URL
ARG BIOC_URL
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST

# -----------------------------------------------------------------------------
# 用户认证环境变量 (运行时可覆盖)
# -----------------------------------------------------------------------------
ENV RSTUDIO_USER=rstudio
ENV RSTUDIO_PASS=rstudio
ENV JUPYTER_TOKEN=

# 其他环境变量
ENV JUPYTERLAB_VERSION=${JUPYTERLAB_VERSION}
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV GITHUB_PROXY=${github_proxy}
ENV CRAN_URL=${CRAN_URL}
ENV BIOC_URL=${BIOC_URL}
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/opt/venv/bin:${PATH:-}"
# 防止GPUbase镜像内的PIP_CONSTRAINT继续生效
ENV PIP_CONSTRAINT=

# -----------------------------------------------------------------------------
# 2a: 安装 Jupyter Lab + R kernel
# -----------------------------------------------------------------------------
RUN /opt/venv/bin/pip install --no-cache-dir \
    jupyterlab==${JUPYTERLAB_VERSION} \
    "notebook<7.0.0" \
    ipykernel \
    ipywidgets \
    jupyter-client

# R kernel for Jupyter
RUN echo "PATH=/opt/venv/bin:${PATH}" >> /usr/local/lib/R/etc/Renviron.site && \
    Rscript -e "install.packages('IRkernel', repos = Sys.getenv('CRAN_URL'))" && \
    Rscript -e "IRkernel::installspec(user = FALSE)" && \
    rm -rf /root/.cache/R /tmp/*

RUN mkdir -p /home/rstudio/.jupyter \
    && printf '%s\n' \
    "c.ServerApp.ip = '0.0.0.0'" \
    "c.ServerApp.port = 8888" \
    "c.ServerApp.open_browser = False" \
    "c.ServerApp.allow_root = True" \
    "c.ServerApp.root_dir = '/data'" > /home/rstudio/.jupyter/jupyter_server_config.py \
    && chown -R rstudio:rstudio /home/rstudio/.jupyter

# -----------------------------------------------------------------------------
# 2b: Shiny 扩展 R 包
# -----------------------------------------------------------------------------
RUN Rscript -e "options(repos = c(CRAN = Sys.getenv('CRAN_URL'))); install.packages(c('shinydashboard', 'shinythemes', 'shinyjs', 'shinyWidgets'), Ncpus = 4)" \
    && rm -rf /root/.cache/R /tmp/*

# -----------------------------------------------------------------------------
# 2c: 配置 RStudio Server
# -----------------------------------------------------------------------------
RUN echo "www-port=8787" >> /etc/rstudio/rserver.conf \
    && echo "auth-minimum-user-id=1000" >> /etc/rstudio/rserver.conf \
    && echo "session-default-working-dir=/data" >> /etc/rstudio/rsession.conf \
    && echo "RETICULATE_PYTHON=/opt/venv/bin/python" >> /usr/local/lib/R/etc/Renviron.site

# -----------------------------------------------------------------------------
# 2d: 复制外部脚本并清除缓存
# -----------------------------------------------------------------------------
COPY external_files/ScType /usr/local/lib/R/site-library/ScType
COPY external_files/RaceID /usr/local/lib/R/site-library/RaceID

RUN echo '# ScType entry point' > /usr/local/lib/R/site-library/ScType/R/ScType.R \
    && echo 'source("/usr/local/lib/R/site-library/ScType/R/sctype_wrapper.R")' >> /usr/local/lib/R/site-library/ScType/R/ScType.R

RUN rm -rf /tmp/* /var/tmp/* /root/.cache/R /root/.cache/pip

# -----------------------------------------------------------------------------
# 2e: 复制 GPU 启动脚本
# -----------------------------------------------------------------------------
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 8787 8888
VOLUME ["/data", "/home/rstudio"]
WORKDIR /data

ENTRYPOINT ["/bin/bash", "/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]