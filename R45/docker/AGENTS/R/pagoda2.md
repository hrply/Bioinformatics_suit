# pagoda2

Differential expression and hierarchical clustering for scRNA-seq

## Environment

`library(pagoda2)`

## Quick Demo

```r
library(pagoda2)
p2 <- basicP2proc(counts, n.cores = 4)
p2$getHierarchicalDiffExpression()
```

## Key Functions

- `basicP2proc`: Run the standard pagoda2 preprocessing pipeline
- `getHierarchicalDiffExpression`: Get differential expression across hierarchical clusters
- `getClusters`: Get cluster assignments at a given resolution
