# tradeSeq

Trajectory-based differential expression using GAMs

## Environment

`library(tradeSeq)`

## Quick Demo

```r
library(tradeSeq)
sce <- fitGAM(sce)
assoc_res <- associationTest(sce)
```

## Key Functions

- `fitGAM`: Fit generalized additive models along pseudotime
- `associationTest`: Test for association between expression and pseudotime
- `startVsEndTest`: Compare expression at start vs end of trajectory
- `diffEndTest`: Test for differential expression at trajectory endpoints
