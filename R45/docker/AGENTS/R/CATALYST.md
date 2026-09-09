# CATALYST

Analysis of cytometry data with mass cytometry tools

## Environment

`library(CATALYST)`

## Quick Demo

```r
library(CATALYST)
sce <- prepData(fs, panel, md, features = "type")
sce <- cluster(sce)
plotMedExprs(sce)
```

## Key Functions

- `prepData`: Prepare a SingleCellExperiment from flowSet and metadata
- `cluster`: Cluster cells using FlowSOM or other methods
- `plotMedExprs`: Plot median marker expression across clusters
- `diffcyt`: Differential testing for cytometry clusters
