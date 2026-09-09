# scirpy

BCR/TCR immune repertoire analysis for single-cell data

## Environment

`import scirpy as ir`

## Quick Demo

```python
import scirpy as ir
ir.pp.ir_dist(adata, metric="alignment")
ir.tl.define_clonotypes(adata)
ir.pl.clonotype_network(adata)
```

## Key Functions

- `pp.ir_dist`: Compute distance between immune receptor sequences
- `tl.define_clonotypes`: Define clonotypes based on receptor similarity
- `pl.clonotype_network`: Visualize clonotype network graph
- `tl.clonal_expansion`: Quantify clonal expansion per group
