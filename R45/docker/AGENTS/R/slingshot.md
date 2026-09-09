# slingshot

Lineage inference and pseudotime ordering of single cells

## Environment

`library(slingshot)`

## Quick Demo

```r
library(slingshot)
sce <- slingshot(sce, clusterLabels = "cluster", reducedDim = "PCA")
slingPseudotime(sce)
```

## Key Functions

- `slingshot`: Infer developmental lineages and assign pseudotime
- `getLineages`: Identify global lineage structure from clusters
- `getCurves`: Fit smooth curves to lineages
- `slingPseudotime`: Extract pseudotime values from slingshot output
