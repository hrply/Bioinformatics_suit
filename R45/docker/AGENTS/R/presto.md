# presto

Fast differential expression testing for Seurat objects

## Environment

`library(presto)`

## Quick Demo

```r
library(presto)
markers <- wilcoxauc(seurat_obj, group_by = "seurat_clusters")
head(markers)
```

## Key Functions

- `wilcoxauc`: Fast Wilcoxon rank-sum test for marker gene detection
- `glmde`: Fast GLM-based differential expression testing
