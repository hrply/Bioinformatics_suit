# Nebulosa

Gene expression density visualization on UMAP/tSNE

## Environment

`library(Nebulosa)`

## Quick Demo

```r
library(Nebulosa)
plot_density(seurat_obj, features = c("CD3E", "CD4"))
```

## Key Functions

- `plot_density`: Plot gene expression as a density estimate on embeddings
