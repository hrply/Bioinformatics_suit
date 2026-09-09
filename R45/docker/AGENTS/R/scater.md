# scater

Pre-processing, quality control and visualization for scRNA-seq

## Environment

`library(scater)`

## Quick Demo

```r
library(scater)
sce <- calculateQCMetrics(sce)
sce <- runPCA(sce)
plotPCA(sce, colour_by = "batch")
```

## Key Functions

- `calculateQCMetrics`: Compute quality control metrics per cell and gene
- `runPCA`: Run PCA on an SingleCellExperiment object
- `isOutlier`: Identify outlier cells based on QC metrics
- `plotPCA`: Plot cells on PCA coordinates
