# pychromvar

Chromatin variability analysis for scATAC-seq

## Environment

`import pychromvar as pcv`

## Quick Demo

```python
import pychromvar as pcv
motif_matrix = pcv.get_jaspar_motifs()
deviations = pcv.compute_deviations(adata, motif_matrix)
```

## Key Functions

- `compute_deviations`: Compute chromatin deviation scores per motif
- `get_jaspar_motifs`: Retrieve JASPAR motif position weight matrices
- `compute_gc_bias`: Compute GC bias for background correction
