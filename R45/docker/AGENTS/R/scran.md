# scran

Normalization, clustering and differential expression for scRNA-seq

## Environment

`library(scran)`

## Quick Demo

```r
library(scran)
clusters <- quickCluster(sce)
sce <- computeSumFactors(sce, clusters = clusters)
sce <- logNormCounts(sce)
markers <- findMarkers(sce, groups = sce$label)
```

## Key Functions

- `computeSumFactors`: Compute size factors for normalization using pooling
- `quickCluster`: Quick clustering for normalization
- `findMarkers`: Find marker genes between groups of cells
- `logNormCounts`: Apply log-normalization using computed size factors
