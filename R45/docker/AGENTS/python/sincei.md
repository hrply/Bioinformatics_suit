# sincei

Single-cell epigenomics clustering and inference

## Environment

`import sincei as si`

## Quick Demo

```python
import sincei as si
si.count_matrix("fragments.tsv", "regions.bed", output="matrix.h5ad")
adata = si.read("matrix.h5ad")
si.cluster(adata)
```

## Key Functions

- `count_matrix`: Count fragments per region from a fragments file
- `cluster`: Cluster cells from epigenomic count data
- `read`: Read epigenomic count matrix
