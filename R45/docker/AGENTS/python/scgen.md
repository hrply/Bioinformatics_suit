# scgen

Batch correction and perturbation prediction using VAE

## Environment

`import scgen`

## Quick Demo

```python
import scanpy as sc
import scgen
adata = sc.read_h5ad("data.h5ad")
model = scgen.SCGEN(adata)
model.train(batch_key="batch", cell_type_key="cell_type")
pred = model.predict(batch_key="batch")
```

## Key Functions

- `SCGEN`: Initialize SCGEN VAE model
- `train`: Train the model on multi-batch data
- `predict`: Predict perturbation response or correct batch effects
