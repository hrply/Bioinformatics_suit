# pertpy

Perturbation analysis toolkit for single-cell data

## Environment

`import pertpy as pt`

## Quick Demo

```python
import pertpy as pt
milo = pt.tl.Milo(adata)
milo.load(adata)
result = milo.da()
```

## Key Functions

- `tl.Milo`: Differential abundance analysis using Milo
- `tl.Coda`: Compositional differential analysis
- `tl.Mixscape`: Perturbation effect classification
- `dt.sc_sim_adata`: Load simulated perturbation dataset
