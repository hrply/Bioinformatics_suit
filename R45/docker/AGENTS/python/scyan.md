# scyan

Cell type annotation using probabilistic models

## Environment

`import scyan`

## Quick Demo

```python
import scyan
model = scyan.Scyan(adata, marker_pop_matrix)
model.train()
adata.obs["scyan_labels"] = model.predict()
```

## Key Functions

- `Scyan`: Initialize Scyan model with data and marker-population matrix
- `train`: Train the probabilistic annotation model
- `predict`: Predict cell type labels
