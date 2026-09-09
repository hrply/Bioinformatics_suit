# episcanpy

Single-cell epigenomics analysis toolkit

## Environment

`import episcanpy as epi`

## Quick Demo

```python
import episcanpy as epi
adata = epi.pp.read_atac("fragments.tsv")
epi.pp.filter_cells(adata, min_features=100)
epi.pp.calVar(adata)
epi.tl.lsi(adata)
```

## Key Functions

- `pp.read_atac`: Read ATAC-seq fragment data
- `pp.filter_cells`: Filter cells by feature counts
- `tl.lsi`: Run latent semantic indexing
- `pp.calVar`: Calculate variable features
