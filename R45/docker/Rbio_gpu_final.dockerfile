# =============================================================================
# pixi 环境说明:
#   default: zarr<3, pandas==2.2.2, graph-tool (无 numpy 限制)
#     -> pegasuspy, vitessce, cirrocumulus, omicverse,
#        dynamo-release, pyCrossTalkeR, bengrn, multivelo, gptbioinsightor, schist
#   pyucell: numpy<2
#   cellxgene: numpy==2.0.1
#   scarf: numpy==1.26.4
#   mowgli: Python 3.11 + numpy<2
#   sctriangulate: squidpy==1.2.0 + gseapy==0.10.4 冲突隔离
#   sopa: anndata>=0.11.0
#   pcdl: spatialdata(zarr>=3)
#   delnx: scipy<1.16
# 使用方式: /opt/scverse/.pixi/envs/<env-name>/bin/python
# =============================================================================
FROM ghcr.io/prefix-dev/pixi:latest AS pixi-bin
FROM rbio:gpubase AS pixi

COPY --from=pixi-bin /usr/local/bin/pixi /usr/local/bin/pixi
WORKDIR /opt/scverse
COPY external_files/pixi_env/pixi_solvegroup.toml pixi.toml

RUN pixi install --all && pixi clean cache -y || true

FROM rbio:gpubase AS final

COPY --from=pixi /opt/scverse/.pixi /opt/scverse/.pixi
COPY --from=pixi /opt/scverse/pixi.toml /opt/scverse/pixi.toml

RUN rm -rf /tmp/* /var/tmp/* /root/.cache/pip /root/.cache/uv /root/.local/share/uv /root/.cache/rattler /var/lib/apt/lists/*
