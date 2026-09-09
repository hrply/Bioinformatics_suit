# scib

Benchmarking framework for single-cell integration methods

## Environment

`import scib`

## Quick Demo

```python
import scib
metrics = scib.metrics(
    adata_int, adata,
    batch_key="batch",
    label_key="cell_type"
)
metrics.head()
```

## Key Functions

- `metrics`: Compute comprehensive integration benchmark metrics
- `metrics.silhouette`: Compute silhouette score
- `metrics.nmi`: Compute normalized mutual information
- `metrics.kBET`: Compute kBET batch mixing metric
