# scfates

Fate mapping and lineage tree inference for single cells

## Environment

`import scFates as scf`

## Quick Demo

```python
import scFates as scf
adata = scf.tl.tree(adata, use_rep="X_pca", method="ppt")
scf.pl.graph(adata)
```

## Key Functions

- `tl.tree`: Infer a lineage tree using principal points or elpigraph
- `pl.graph`: Visualize the inferred lineage tree
- `tl.test_fork`: Test for differential expression at lineage forks
