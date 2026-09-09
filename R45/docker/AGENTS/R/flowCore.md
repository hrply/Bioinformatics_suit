# flowCore

Core infrastructure for flow cytometry data handling

## Environment

`library(flowCore)`

## Quick Demo

```r
library(flowCore)
fcs <- read.FCS("sample.fcs")
exprs_data <- exprs(fcs)
fs <- flowSet(list(fcs))
```

## Key Functions

- `read.FCS`: Read an FCS flow cytometry file
- `flowFrame`: Create a flow frame object from a matrix
- `flowSet`: Create a flow set from multiple flow frames
- `exprs`: Extract the expression matrix from a flow frame
