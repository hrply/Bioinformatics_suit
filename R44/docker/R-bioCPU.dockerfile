# R-bioCPU Dockerfile - 完整CPU版单细胞分析环境
# 基于 stage1 保留所有系统依赖，复制 stage5 的包，从而精简镜像大小，同时保留完整的系统依赖库。
# 构建命令: docker build -t r-bio:cpu_v1.0.1 -f R-bioCPU.dockerfile .

FROM r-bio:stage1

# 设置环境变量
ENV PATH="/opt/venv/bin:/opt/r-miniconda/bin:${PATH}"
ENV RETICULATE_MINICONDA_ENABLED=FALSE
ENV RETICULATE_MINICONDA_PATH=/opt/r-miniconda
ENV HDF5_PLUGIN_PATH=/lzf
ENV PASSWORD=rstudio
ENV USER=rstudio

# 从 stage5 复制 R 包（418个包，包含 stage1 的 339 个 + 新增）
# 这会覆盖 stage1 的 site-library，但 stage5 是完整的超集
COPY --from=r-bio:stage5 /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=r-bio:stage5 /usr/local/lib/R/etc/Rprofile.site /usr/local/lib/R/etc/Rprofile.site
COPY --from=r-bio:stage5 /opt/venv /opt/venv

# 从 stage2 复制 HDF5 LZF 插件
COPY --from=r-bio:stage2 /lzf /lzf

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
