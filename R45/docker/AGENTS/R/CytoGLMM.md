# CytoGLMM

Differential analysis of cytometry data using GLMM

## Environment

`library(CytoGLMM)`

## Quick Demo

```r
library(CytoGLMM)
fit <- cytoglm(df,
               protein_names = markers,
               condition = "treatment",
               group = "donor")
summary(fit)
```

## Key Functions

- `cytoglm`: Fit a generalized linear mixed model for cytometry data
- `cytoglance`: Quick GLMM-based differential analysis
- `plot.cytoglm`: Plot GLMM results with confidence intervals
