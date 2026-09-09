# DESeq2

Differential gene expression analysis with negative binomial models

## Environment

`library(DESeq2)`

## Quick Demo

```r
library(DESeq2)
dds <- DESeqDataSetFromMatrix(countData, colData, design = ~ condition)
dds <- DESeq(dds)
res <- results(dds, contrast = c("condition", "treated", "control"))
```

## Key Functions

- `DESeqDataSetFromMatrix`: Create a DESeqDataSet from a count matrix
- `DESeq`: Run the full DESeq2 differential expression pipeline
- `results`: Extract results table from a DESeq2 analysis
- `lfcShrink`: Shrink log2 fold changes for visualization
