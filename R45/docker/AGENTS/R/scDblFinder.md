# scDblFinder

Doublet detection for single-cell RNA-seq data

## Environment

`library(scDblFinder)`

## Quick Demo

```r
library(scDblFinder)
sce <- scDblFinder(sce)
table(sce$scDblFinder.class)
```

## Key Functions

- `scDblFinder`: Detect doublets in single-cell data using a classifier
- `computeDoubletDensity`: Compute doublet density scores
