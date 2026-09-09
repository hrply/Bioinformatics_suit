# monocle

Single-cell trajectory and pseudotime analysis

## Environment

`library(monocle)`

## Quick Demo

```r
library(monocle)
cds <- newCellDataSet(counts, phenoData = pd, featureData = fd)
cds <- reduceDimension(cds, method = "DDRTree")
cds <- orderCells(cds)
plot_cell_trajectory(cds, color_by = "State")
```

## Key Functions

- `newCellDataSet`: Create a CellDataSet object
- `reduceDimension`: Reduce dimensionality for trajectory inference
- `orderCells`: Order cells along a learned trajectory
- `plot_cell_trajectory`: Visualize cells on a trajectory plot
