# diffcyt

Differential testing for high-dimensional cytometry data

## Environment

`library(diffcyt)`

## Quick Demo

```r
library(diffcyt)
da_res <- diffcyt(d_input, design = design,
                  contrast = contrast, test = testDA_voom)
```

## Key Functions

- `diffcyt`: Run differential testing pipeline for cytometry data
- `prepareData`: Prepare input data for diffcyt analysis
- `testDA_voom`: Test for differential abundance using voom
- `testDS_limma`: Test for differential states using limma
