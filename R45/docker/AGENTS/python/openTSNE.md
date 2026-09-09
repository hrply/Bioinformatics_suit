# openTSNE

Fast t-SNE implementation with optimization improvements

## Environment

`import openTSNE`

## Quick Demo

```python
import openTSNE
tsne = openTSNE.TSNE(n_jobs=8, perplexity=30)
embedding = tsne.fit(adata.X)
adata.obsm["X_tsne"] = embedding
```

## Key Functions

- `TSNE`: Initialize and run t-SNE embedding
- `fit`: Compute t-SNE embedding from data matrix
- `transform`: Project new data into existing t-SNE embedding
