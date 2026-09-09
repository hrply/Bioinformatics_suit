# spatiomic

Spatial omics data analysis and visualization

## Environment

`import spatiomic as so`

## Quick Demo

```python
import spatiomic as so
so.spatial.autocorrelation(adata, spatial_key="spatial")
so.pl.spatial(adata, color="gene1")
```

## Key Functions

- `spatial.autocorrelation`: Compute spatial autocorrelation statistics
- `pl.spatial`: Visualize spatial omics data
