# ConsensusClusterPlus

Consensus clustering for subtype discovery

## Environment

`library(ConsensusClusterPlus)`

## Quick Demo

```r
library(ConsensusClusterPlus)
results <- ConsensusClusterPlus(
  as.matrix(t(expr)), maxK = 6, reps = 50,
  pItem = 0.8, pFeature = 1, clusterAlg = "hc", distance = "pearson")
```

## Key Functions

- `ConsensusClusterPlus`: Run consensus clustering across k values
