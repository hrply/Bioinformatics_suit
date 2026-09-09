# pegasuspy

Demultiplexing, preprocessing and analysis of scRNA-seq

## Environment

`import pegasus as pg`

## Quick Demo

```python
import pegasus as pg
adata = pg.read_input("data.h5ad")
pg.filter_data(adata)
pg.highly_variable_features(adata)
pg.pca(adata)
pg.neighbors(adata)
pg.umap(adata)
pg.clustering(adata)
```

## Key Functions

- `read_input`: Read single-cell data from various formats
- `filter_data`: Filter cells and genes by quality metrics
- `highly_variable_features`: Identify highly variable features
- `clustering`: Cluster cells using Leiden or Louvain
