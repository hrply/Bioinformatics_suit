# cellmapper

Cell type mapping and label transfer for single-cell data

## Environment

`import cellmapper as cm`

## Quick Demo

```python
import cellmapper as cm
result = cm.map_cells(query_adata, reference_adata, annotation="cell_type")
```

## Key Functions

- `map_cells`: Map query cells to a reference and transfer labels
- `compute_similarity`: Compute cell-to-cell similarity between datasets
