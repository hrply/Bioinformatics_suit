# cell2location

Spatial transcriptomics cell type deconvolution

## Environment

`import cell2location as c2l`

## Quick Demo

```python
import scanpy as sc
import cell2location as c2l
adata_sc = sc.read_h5ad("sc.h5ad")
adata_sp = sc.read_h5ad("spatial.h5ad")
model = c2l.models.ReferencesModel(adata_sc)
model.train()
adata_sp = c2l.models.Cell2location(adata_sp, model).train()
```

## Key Functions

- `ReferencesModel`: Train a reference model from single-cell data
- `Cell2location`: Deconvolve spatial data using trained reference
- `plot_cell_density`: Visualize estimated cell type densities
