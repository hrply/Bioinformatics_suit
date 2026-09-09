# snapatac2

Single-cell ATAC-seq analysis toolkit

## Environment

`import snapatac2 as snap`

## Quick Demo

```python
import snapatac2 as snap
adata = snap.pp.import_data("fragments.tsv.gz", chrom_sizes)
snap.pp.filter_cells(adata)
snap.tl.spectral(adata)
snap.tl.umap(adata)
snap.pp.call_peaks(adata)
```

## Key Functions

- `pp.import_data`: Import ATAC-seq fragment data
- `pp.filter_cells`: Filter cells by quality metrics
- `tl.spectral`: Compute spectral embedding
- `pp.call_peaks`: Call peaks from aggregated fragments
