# ALRA

Matrix imputation and completion for scRNA-seq data

## Environment

`library(ALRA)`

## Quick Demo

```r
library(ALRA)
result <- alra(normalized_matrix, k = 10)
imputed_matrix <- result[[3]]
```

## Key Functions

- `alra`: Perform ALRA imputation on a normalized count matrix
- `choose_k`: Determine optimal rank-k for low-rank approximation
