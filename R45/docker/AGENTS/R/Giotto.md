# Giotto

Spatial transcriptomics analysis toolkit

## Environment

`library(Giotto)`

## Quick Demo

```r
library(Giotto)
giotto <- createGiottoObject(raw_exprs = expr, spatial_locs = locs)
giotto <- normalizeGiotto(giotto)
giotto <- runPCA(giotto)
giotto <- createSpatialNetwork(giotto)
```

## Key Functions

- `createGiottoObject`: Initialize a Giotto object with expression and spatial data
- `runPCA`: Run principal component analysis
- `createSpatialNetwork`: Build a spatial neighbor network
- `doSpatialFeaturePlot`: Visualize spatial feature expression
