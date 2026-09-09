# gssnng

Gene set scoring for nearest neighbor graphs

## Environment

`import gssnng`

## Quick Demo

```python
import gssnng as gs
scores = gs.score_genes(adata, gene_sets, groupby="cell_type")
adata.obs["gene_set_score"] = scores
```

## Key Functions

- `score_genes`: Score gene sets using nearest neighbor graph smoothing
