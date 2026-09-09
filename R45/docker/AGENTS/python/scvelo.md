# scvelo

RNA velocity estimation for single-cell RNA-seq

## Environment

`import scvelo as scv`

## Quick Demo

```python
import scvelo as scv
scv.pp.filter_and_normalize(adata)
scv.pp.moments(adata)
scv.tl.velocity(adata)
scv.tl.velocity_graph(adata)
scv.pl.velocity_embedding_stream(adata)
```

## Key Functions

- `pp.filter_and_normalize`: Filter and normalize data for velocity analysis
- `tl.velocity`: Estimate RNA velocity
- `tl.velocity_graph`: Compute velocity graph for trajectory inference
- `pl.velocity_embedding_stream`: Plot velocity as streamlines on embedding
