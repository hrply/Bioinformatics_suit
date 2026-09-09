# scde

Bayesian differential expression for single-cell data

## Environment

`library(scde)`

## Quick Demo

```r
library(scde)
models <- scde.error.models(counts, groups = group_labels)
prior <- scde.expression.prior(models, counts)
diff <- scde.test.gene.expression.difference("GENE1", models, prior)
```

## Key Functions

- `scde.error.models`: Fit error models for each cell
- `scde.expression.prior`: Compute gene expression prior
- `scde.test.gene.expression.difference`: Test for differential expression between groups
