# novae

Neural variational autoencoder for spatial transcriptomics

## Environment

`import novae`

## Quick Demo

```python
import novae
model = novae.Novae()
model.fit(adata)
adata = model.predict(adata)
```

## Key Functions

- `Novae`: Initialize the spatial variational autoencoder model
- `fit`: Train the model on spatial transcriptomics data
- `predict`: Predict spatial domains
