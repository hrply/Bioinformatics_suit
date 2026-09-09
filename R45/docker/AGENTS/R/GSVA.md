# GSVA

Gene set variation analysis for single-sample pathway scoring

## Environment

`library(GSVA)`

## Quick Demo

```r
library(GSVA)
gsva_scores <- gsva(expr_matrix, gene_sets, method = "gsva")
```

## Key Functions

- `gsva`: Compute gene set variation analysis scores per sample
- `filterGenes`: Filter genes in gene sets to those present in data
- `igsvaParam`: Create GSVA parameter object for Iris integration
