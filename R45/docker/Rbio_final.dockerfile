# =============================================================================
# Rbio_final.dockerfile - 最终镜像构建
# =============================================================================
# 
# 两层构建:
#   1. cpu-final: 基于 r-bio:cpu，安装 Jupyter Lab + 配置服务
#   2. gpu-final: 基于 r-bio:gpu，安装 Jupyter Lab + 配置服务
#
# 用户认证环境变量:
#   RSTUDIO_USER    - RStudio 用户名 (默认: rstudio)
#   RSTUDIO_PASS    - RStudio 密码 (默认: rstudio，强烈建议修改)
#   JUPYTER_TOKEN   - Jupyter Lab Token (默认: 无，未设置时自动生成)
#
# 使用方法:
#   docker build -f Rbio_final.dockerfile --target cpu-final -t r-bio:cpu-final .
#   docker build -f Rbio_final.dockerfile --target gpu-final -t r-bio:gpu-final .
#
#   docker run -d -p 8787:8787 -p 8888:8888 \
#     -e RSTUDIO_USER=myuser \
#     -e RSTUDIO_PASS=mypassword \
#     -e JUPYTER_TOKEN=mytoken \
#     -v /path/to/data:/data r-bio:cpu-final
#
# =============================================================================

# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# Stage 1: CPU 最终镜像
# Base: r-bio:cpu
# 继承环境变量: CRAN_URL, BIOC_URL, GITHUB_PROXY, http_proxy, https_proxy, 
#               PIP_INDEX_URL, PIP_TRUSTED_HOST, PATH, VIRTUAL_ENV
# -----------------------------------------------------------------------------
FROM r-bio:cpu AS cpu-final

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
# RStudio 认证 (默认值仅用于构建时提示，运行时通过 -e 覆盖)
ENV RSTUDIO_USER=rstudio
ENV RSTUDIO_PASS=rstudio
# Jupyter 认证 (空表示自动生成 token)
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
    notebook==7.3.2 \
    ipykernel==6.29.5 \
    ipywidgets==8.1.5 \
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
COPY --chmod=755 <<'EOF' /init.sh
#!/bin/bash
set -e

echo "========================================"
echo "  R-bio Final Container"
echo "========================================"

# 配置 RStudio 用户密码
RSTUDIO_USER=${RSTUDIO_USER:-rstudio}
RSTUDIO_PASS=${RSTUDIO_PASS:-rstudio}

# 确保 rstudio 用户存在
if ! id "${RSTUDIO_USER}" &>/dev/null; then
    useradd -m -s /bin/bash "${RSTUDIO_USER}"
fi

# 设置密码
echo "${RSTUDIO_USER}:${RSTUDIO_PASS}" | chpasswd

# 设置 home 目录权限
mkdir -p /home/${RSTUDIO_USER}
chown -R ${RSTUDIO_USER}:${RSTUDIO_USER} /home/${RSTUDIO_USER}

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

# 启动 Jupyter Lab
cd /data
/opt/venv/bin/jupyter lab --config=/home/${RSTUDIO_USER}/.jupyter/jupyter_server_config.py &

# 保持容器前台运行
sleep infinity
EOF

EXPOSE 8787 8888
VOLUME ["/data", "/home/rstudio"]
WORKDIR /data

CMD ["/init.sh"]

# =============================================================================
# Stage 2: GPU 最终镜像
# Base: r-bio:gpu (已包含 CUDA + GPU Python 包)
# 继承环境变量同上
# -----------------------------------------------------------------------------
FROM r-bio:gpu AS gpu-final

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
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/opt/venv/bin:${PATH}"

# -----------------------------------------------------------------------------
# 2a: 安装 Jupyter Lab + R kernel
# -----------------------------------------------------------------------------
RUN /opt/venv/bin/pip install --no-cache-dir \
    jupyterlab==${JUPYTERLAB_VERSION} \
    notebook==7.3.2 \
    ipykernel==6.29.5 \
    ipywidgets==8.1.5 \
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
# 2e: 启动脚本 (支持环境变量配置认证)
# -----------------------------------------------------------------------------
COPY --chmod=755 <<'EOF' /init.sh
#!/bin/bash
set -e

echo "========================================"
echo "  R-bio Final Container (GPU)"
echo "========================================"

# 配置 RStudio 用户密码
RSTUDIO_USER=${RSTUDIO_USER:-rstudio}
RSTUDIO_PASS=${RSTUDIO_PASS:-rstudio}

# 确保 rstudio 用户存在
if ! id "${RSTUDIO_USER}" &>/dev/null; then
    useradd -m -s /bin/bash "${RSTUDIO_USER}"
fi

# 设置密码
echo "${RSTUDIO_USER}:${RSTUDIO_PASS}" | chpasswd

# 设置 home 目录权限
mkdir -p /home/${RSTUDIO_USER}
chown -R ${RSTUDIO_USER}:${RSTUDIO_USER} /home/${RSTUDIO_USER}

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

# 启动 Jupyter Lab
cd /data
/opt/venv/bin/jupyter lab --config=/home/${RSTUDIO_USER}/.jupyter/jupyter_server_config.py &

# 保持容器前台运行
sleep infinity
EOF

EXPOSE 8787 8888
VOLUME ["/data", "/home/rstudio"]
WORKDIR /data

CMD ["/init.sh"]
