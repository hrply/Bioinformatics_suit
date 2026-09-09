# MAST

Model-based analysis of single-cell transcriptomics

## Environment

`library(MAST)`

## Quick Demo

```r
library(MAST)
sca <- FromMatrix(expr_matrix, cData = cell_data, fData = gene_data)
fit <- zlm(~ condition, sca)
summary_dt <- summary(fit, doLRT = "conditiontreated")
```

## Key Functions

- `FromMatrix`: Create a SingleCellAssay from expression and metadata
- `zlm`: Fit a hurdle model (logistic + Gaussian) to single-cell data
- `summary`: Summarize hurdle model fit results
- `lrTest`: Perform likelihood ratio test on fitted model
