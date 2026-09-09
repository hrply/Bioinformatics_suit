# celltalker

Cell-cell communication from ligand-receptor interactions

## Environment

`library(celltalker)`

## Quick Demo

```r
library(celltalker)
ct <- create_celltalker(counts, meta, lr_pairs, group_by = "cell_type")
ct <- find_communications(ct)
ct <- plot_communications(ct)
```

## Key Functions

- `create_celltalker`: Initialize a celltalker object from expression data
- `find_communications`: Identify significant ligand-receptor interactions
- `plot_communications`: Visualize cell-cell communication networks
