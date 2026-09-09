# tangram-sc

Deep learning spatial transcriptomics deconvolution

## Environment

`import tangram_sc as tg`

## Quick Demo

```python
import tangram_sc as tg
adata_map = tg.map_cells_to_space(adata_sc, adata_sp)
tg.project_genes(adata_map, adata_sc)
```

## Key Functions

- `map_cells_to_space`: Map single-cell data onto spatial coordinates
- `project_genes`: Project gene expression from mapped cells to space
