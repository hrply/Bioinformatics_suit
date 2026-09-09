# squidpy

Spatial transcriptomics analysis and visualization

## Environment

`import squidpy as sq`

## Quick Demo

```python
import squidpy as sq
sq.gr.spatial_neighbors(adata)
sq.gr.spatial_autocorr(adata, mode="moran")
sq.pl.spatial_scatter(adata, color="gene1")
```

## Key Functions

- `gr.spatial_neighbors`: Compute spatial neighbor graph
- `gr.spatial_autocorr`: Compute spatial autocorrelation (Moran/Geary)
- `gr.co_occurrence`: Compute co-occurrence probability of cell types
- `pl.spatial_scatter`: Visualize spatial scatter plot
