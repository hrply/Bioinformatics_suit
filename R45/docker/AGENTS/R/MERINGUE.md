# MERINGUE

Spatial gene expression pattern analysis

## Environment

`library(MERINGUE)`

## Quick Demo

```r
library(MERINGUE)
results <- getSpatialPatterns(counts, coords)
sig_genes <- filterSpatialPatterns(results, alpha = 0.05)
spatialCrossCor(results["GENE1",], counts["GENE2",], coords)
```

## Key Functions

- `getSpatialPatterns`: Detect genes with spatially variable expression
- `filterSpatialPatterns`: Filter spatial patterns by significance
- `spatialCrossCor`: Compute spatial cross-correlation between genes
