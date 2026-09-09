# scalex

Cross-species single-cell data integration using deep learning

## Environment

`import scalex as sx`

## Quick Demo

```python
import scalex as sx
adata_integrated = sx.SCALEX(adata, batch_key="species")
adata_integrated.write("integrated.h5ad")
```

## Key Functions

- `SCALEX`: Run SCALEX integration across batches or species
