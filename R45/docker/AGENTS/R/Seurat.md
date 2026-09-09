# Seurat

Comprehensive single-cell RNA-seq analysis toolkit

## Environment

`library(Seurat)`

## Quick Demo

```r
library(Seurat)
obj <- CreateSeuratObject(counts = counts)
obj <- NormalizeData(obj)
obj <- FindVariableFeatures(obj)
obj <- RunPCA(obj)
obj <- FindNeighbors(obj, dims = 1:30)
obj <- FindClusters(obj, resolution = 0.5)
obj <- RunUMAP(obj, dims = 1:30)
```

## Key Functions

- `CreateSeuratObject`: Create a Seurat object from a count matrix
- `NormalizeData`: Normalize count data by library size
- `RunPCA`: Run principal component analysis
- `FindClusters`: Cluster cells using shared nearest neighbor graph
- `RunUMAP`: Run UMAP dimensionality reduction
