# Signac

Single-cell ATAC-seq and chromatin accessibility analysis

## Environment

`library(Signac)`

## Quick Demo

```r
library(Signac)
chromatin <- CreateChromatinAssay(counts = peak_counts, fragments = frags)
obj <- CreateSeuratObject(chromatin)
obj <- RunTFIDF(obj)
obj <- FindTopFeatures(obj)
obj <- RunSVD(obj)
```

## Key Functions

- `CreateChromatinAssay`: Create a ChromatinAssay for ATAC-seq data
- `RunTFIDF`: Run TF-IDF normalization on peak counts
- `FindTopFeatures`: Identify top accessible peaks
- `RunSVD`: Run latent semantic indexing (LSI)
