# muon

Multi-modal single-cell data analysis framework

## Environment

`import muon as mu`

## Quick Demo

```python
import muon as mu
mdata = mu.read_10x_h5("multiome.h5")
mu.pp.filter_obs(mdata, "rna:n_genes_by_counts", lambda x: x > 100)
mu.pl.embedding(mdata, basis="X_umap", color="cell_type")
```

## Key Functions

- `read_10x_h5`: Read 10x multiome HDF5 file as MuData
- `pp.filter_obs`: Filter observations across modalities
- `pp.intersect_obs`: Intersect observations across modalities
- `pl.embedding`: Plot embeddings colored by metadata
