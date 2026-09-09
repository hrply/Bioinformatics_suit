# biolord

Disentangled representation learning for single-cell biology

## Environment

`import biolord`

## Quick Demo

```python
import scanpy as sc
import biolord
adata = sc.read_h5ad("data.h5ad")
model = biolord.BiolordAnnData(adata, attr_keys=["cell_type"])
model.train()
```

## Key Functions

- `BiolordAnnData`: Initialize a Biolord model from an AnnData object
- `train`: Train the disentangled representation model
- `get_latent_representation`: Extract learned latent representations
