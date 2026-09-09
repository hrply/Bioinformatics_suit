# BPCells

Ultra-fast single-cell RNA-seq matrix operations on disk

## Environment

`library(BPCells)`

## Quick Demo

```r
library(BPCells)
mat <- open_matrix_10x_hdf5("filtered_feature_bc_matrix.h5")
mat_norm <- normalize_matrix(mat, scale_factor = 10000)
stats <- matrix_stats(mat)
```

## Key Functions

- `open_matrix_10x_hdf5`: Open a 10x HDF5 matrix for on-disk access
- `open_matrix_10x_mtx`: Open a 10x MTX matrix directory
- `normalize_matrix`: Normalize counts by library size
- `matrix_stats`: Compute summary statistics for a matrix
