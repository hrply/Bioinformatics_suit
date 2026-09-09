# symphonypy

Reference-based cell type mapping using Harmony

## Environment

`import symphonypy`

## Quick Demo

```python
import symphonypy
adata_ref = symphonypy.load_reference("ref.h5ad")
adata_query = symphonypy.map_embedding(adata_query, adata_ref)
adata_query.obs["predicted_cell_type"]
```

## Key Functions

- `load_reference`: Load a Harmony-based reference object
- `map_embedding`: Map query data onto reference embedding
