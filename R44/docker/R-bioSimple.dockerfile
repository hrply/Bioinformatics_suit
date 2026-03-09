# R-bioSimple Dockerfile - 简化版单细胞分析环境
# 不包含stage1安装的系统依赖库，部分空间转录组分析工具（如spatialDE）需要这些库，使用时可根据需要安装
# 使用代理构建：docker build -t r-bio:simple_v1.0.1 -f R-bioSimple.dockerfile .
FROM rocker/tidyverse:4.4.3

# 设置环境变量
ENV PATH="/opt/venv/bin:/opt/r-miniconda/bin:${PATH}"
ENV RETICULATE_MINICONDA_ENABLED=FALSE
ENV RETICULATE_MINICONDA_PATH=/opt/r-miniconda
ENV HDF5_PLUGIN_PATH=/lzf
ENV PASSWORD=rstudio
ENV USER=rstudio

# 从已构建的stage直接复制内容
COPY --from=r-bio:stage5 /opt/venv /opt/venv
COPY --from=r-bio:stage1 /opt/r-miniconda /opt/r-miniconda
COPY --from=r-bio:stage1 /usr/bin/shiny-server /usr/bin/shiny-server
COPY --from=r-bio:stage1 /etc/shiny-server /etc/shiny-server
COPY --from=r-bio:stage1 /usr/bin/cmake /usr/bin/

# 复制所有stage1新增的系统库
COPY --from=r-bio:stage1 /usr/lib/x86_64-linux-gnu/libuv* /usr/lib/x86_64-linux-gnu/
COPY --from=r-bio:stage1 /usr/lib/x86_64-linux-gnu/libproj* /usr/lib/x86_64-linux-gnu/
COPY --from=r-bio:stage1 /usr/lib/x86_64-linux-gnu/libudunits* /usr/lib/x86_64-linux-gnu/
COPY --from=r-bio:stage1 /usr/lib/x86_64-linux-gnu/libgdal* /usr/lib/x86_64-linux-gnu/
# 复制GSL库（chromVARmotifs/DirichletMultinomial依赖）
COPY --from=r-bio:stage1 /usr/lib/x86_64-linux-gnu/libgsl* /usr/lib/x86_64-linux-gnu/
COPY --from=r-bio:stage1 /usr/lib/x86_64-linux-gnu/libgslcblas* /usr/lib/x86_64-linux-gnu/

COPY --from=r-bio:stage2 /lzf /lzf
COPY --from=r-bio:stage5 /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=r-bio:stage5 /usr/local/lib/R/etc/Rprofile.site /usr/local/lib/R/etc/Rprofile.site

# 创建用户
RUN (useradd -m -s /bin/bash rstudio || echo "User already exists") && \
    echo "rstudio:rstudio" | chpasswd

# 创建工作目录
RUN mkdir -p /home/rstudio /workspace
RUN chown -R rstudio:rstudio /home/rstudio /workspace

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
