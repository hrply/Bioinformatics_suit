# gseapy

Gene set enrichment analysis in Python

## Environment

`import gseapy as gp`

## Quick Demo

```python
import gseapy as gp
result = gp.enrichr(
    gene_list=gene_list,
    gene_sets="KEGG_2021_Human",
    organism="human"
)
```

## Key Functions

- `enrichr`: Run Enrichr gene set enrichment analysis
- `gsea`: Run gene set enrichment analysis with rank-based method
- `barplot`: Generate enrichment result bar plots
- `dotplot`: Generate enrichment result dot plots
