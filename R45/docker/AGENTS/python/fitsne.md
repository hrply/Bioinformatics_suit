# fitsne

Fast t-SNE implementation using FFT-accelerated interpolation

## Environment

`from fitsne import FTSNE`

## Quick Demo

```python
from fitsne import FTSNE
embedding = FTSNE(adata.X, n_threads=8)
adata.obsm["X_fitsne"] = embedding
```

## Key Functions

- `FTSNE`: Compute FFT-accelerated t-SNE embedding
