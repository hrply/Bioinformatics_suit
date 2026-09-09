# spatialproteomics

Spatial protein expression analysis toolkit

## Environment

`import spatialproteomics as sp`

## Quick Demo

```python
import spatialproteomics as sp
adata = sp.io.read("data.h5ad")
sp.tl.neighborhood(adata, method="knn")
sp.pl.spatial(adata, color="protein1")
```

## Key Functions

- `io.read`: Read spatial proteomics data
- `tl.neighborhood`: Compute cellular neighborhood composition
- `pl.spatial`: Visualize spatial protein expression
