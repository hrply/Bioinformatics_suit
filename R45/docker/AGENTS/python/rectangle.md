# rectangle

Rectangular data embedding for single-cell analysis

## Environment

`import rectangle as rc`

## Quick Demo

```python
import rectangle as rc
result = rc.embed(adata, n_dims=2)
adata.obsm["X_rect"] = result
```

## Key Functions

- `embed`: Compute rectangular data embedding
