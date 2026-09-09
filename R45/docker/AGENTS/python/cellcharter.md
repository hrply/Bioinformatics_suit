# cellcharter

Spatial clustering and analysis for spatial omics data

## Environment

`import cellcharter as cc`

## Quick Demo

```python
import scanpy as sc
import cellcharter as cc
adata = sc.read_h5ad("spatial.h5ad")
cc.gr.spatial_neighbors(adata)
cc.tl.clustering(adata, n_clusters=5)
```

## Key Functions

- `gr.spatial_neighbors`: Compute spatial neighbor graph
- `tl.clustering`: Cluster spatial domains
- `pl.plot_domains`: Visualize spatial domain clusters
