# AUCell

Identify cells with active gene sets using area-under-the-curve

## Environment

`library(AUCell)`

## Quick Demo

```r
library(AUCell)
rankings <- AUCell_buildRankings(exprMatrix)
geneSets <- list(markers = c("CD3E", "CD4", "IL7R"))
cells_auc <- AUCell_calcAUC(geneSets, rankings)
```

## Key Functions

- `AUCell_buildRankings`: Build cell-level gene expression rankings
- `AUCell_calcAUC`: Calculate AUC scores for gene sets per cell
- `getAUC`: Extract AUC score matrix
- `getTopCells`: Get top-scoring cells for a gene set
