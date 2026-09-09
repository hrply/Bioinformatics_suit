# sc2spa

Map single-cell RNA-seq to spatial transcriptomics

## Environment

`import sc2spa`

## Quick Demo

```python
import sc2spa as s2s
result = s2s.map_cells_to_space(adata_sc, adata_sp)
result.write("mapped.h5ad")
```

## Key Functions

- `map_cells_to_space`: Map single-cell data onto spatial coordinates
