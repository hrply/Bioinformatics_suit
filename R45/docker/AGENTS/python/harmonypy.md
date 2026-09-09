# harmonypy

Harmony batch correction algorithm Python port

## Environment

`import harmonypy`

## Quick Demo

```python
import harmonypy as hm
ho = hm.run_harmony(adata.obsm["X_pca"], adata.obs, "batch")
adata.obsm["X_harmony"] = ho.Z_corr.T
```

## Key Functions

- `run_harmony`: Run Harmony batch correction on an embedding matrix
