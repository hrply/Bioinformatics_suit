# harmony

Fast batch correction using PCA-based integration

## Environment

`library(harmony)`

## Quick Demo

```r
library(harmony)
seurat_obj <- RunHarmony(seurat_obj, group.by.vars = "batch")
harmony_embeddings <- Embeddings(seurat_obj, "harmony")
```

## Key Functions

- `RunHarmony`: Run Harmony integration on a Seurat object
- `HarmonyMatrix`: Run Harmony on an arbitrary embedding matrix
