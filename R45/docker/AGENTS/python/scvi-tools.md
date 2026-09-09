# scvi-tools

Deep generative models for single-cell transcriptomics

## Environment

`import scvi`

## Quick Demo

```python
import scvi
scvi.model.SCVI.setup_anndata(adata, batch_key="batch")
model = scvi.model.SCVI(adata)
model.train()
adata.obsm["X_scVI"] = model.get_latent_representation()
```

## Key Functions

- `model.SCVI`: Single-cell variational inference model
- `model.SCANVI`: Semi-supervised cell type annotation model
- `model.TOTALVI`: Joint RNA and protein expression model
- `train`: Train the selected model
