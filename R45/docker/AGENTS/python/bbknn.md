# bbknn

Batch-balanced k-nearest neighbor graph for batch correction

## Environment

`import bbknn`

## Quick Demo

```python
import scanpy as sc
import bbknn
adata = sc.read_h5ad("data.h5ad")
bbknn.bbknn(adata, batch_key="batch")
sc.tl.umap(adata)
```

## Key Functions

- `bbknn`: Compute batch-balanced k-nearest neighbor graph
