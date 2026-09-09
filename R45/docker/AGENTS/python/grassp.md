# grassp

Graph-based spatial pattern recognition for spatial omics

## Environment

`import grassp`

## Quick Demo

```python
import grassp as gp
gp.tl.spatial_patterns(adata, spatial_key="spatial")
gp.pl.spatial_pattern(adata, pattern=0)
```

## Key Functions

- `tl.spatial_patterns`: Detect spatial gene expression patterns
- `pl.spatial_pattern`: Visualize detected spatial patterns
