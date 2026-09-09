# cellxgene

Interactive single-cell data visualization server

## Environment

CLI: `pixi run cellxgene` (from `/opt/scverse-incompat-incompat-incompat/cellxgene/`)
Python: `/opt/scverse-incompat-incompat-incompat/cellxgene/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat-incompat/cellxgene/.pixi/envs/default/bin/python script.py`

## Quick Demo

```bash
cd /opt/scverse-incompat-incompat-incompat/cellxgene
pixi run cellxgene --help
pixi run cellxgene launch --anndata adata.h5ad
```

## Notes

- `cellxgene` CLI is the main interface, not `python -c "import cellxgene"`
- The Python module is imported as `server`, not `cellxgene`
- Version: 1.3.0
