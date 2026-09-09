# dotools-py

Dropout gene expression recovery for scRNA-seq

## Environment

`import dotools`

## Quick Demo

```python
import dotools
adata_imputed = dotools.recover(adata)
adata_imputed.write("imputed.h5ad")
```

## Key Functions

- `recover`: Recover dropout events in single-cell expression data
