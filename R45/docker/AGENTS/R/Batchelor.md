# Batchelor

Batch correction methods for single-cell data

## Environment

`library(Batchelor)`

## Quick Demo

```r
library(Batchelor)
corrected <- fastMNN(batch1, batch2, k = 20)
reducedDim(corrected, "corrected")
```

## Key Functions

- `fastMNN`: Fast mutual nearest neighbors batch correction
- `batchCorrect`: Generic batch correction dispatcher
- `reducedMNN`: MNN correction on low-dimensional representations
