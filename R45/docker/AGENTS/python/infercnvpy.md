# infercnvpy

Infer copy number variation from single-cell RNA-seq

## Environment

`import infercnvpy as cnv`

## Quick Demo

```python
import infercnvpy as cnv
cnv.tl.infercnv(adata, reference_key="cell_type", reference_cat=["normal"])
cnv.pl.chromosome_heatmap(adata)
```

## Key Functions

- `tl.infercnv`: Infer copy number variation from expression data
- `pl.chromosome_heatmap`: Plot CNV heatmap across chromosomes
- `tl.cnv_score`: Compute per-cell CNV deviation score
