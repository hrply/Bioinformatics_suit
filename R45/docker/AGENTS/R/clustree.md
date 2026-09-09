# clustree

Cluster resolution decision tree visualizations

## Environment

`library(clustree)`

## Quick Demo

```r
library(clustree)
clustree(seurat_obj, prefix = "RNA_snn_res.")
```

## Key Functions

- `clustree`: Plot a cluster tree showing relationships across resolutions
- `clustree_overlay`: Overlay cluster tree on a dimensionality reduction
