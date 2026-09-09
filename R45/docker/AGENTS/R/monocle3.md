# monocle3

Modern trajectory analysis for single-cell data

## Environment

`library(monocle3)`

## Quick Demo

```r
library(monocle3)
cds <- learn_graph(cds)
cds <- order_cells(cds, root_cells = root_cells)
plot_cells(cds, color_cells_by = "pseudotime")
```

## Key Functions

- `learn_graph`: Learn the principal graph for trajectory inference
- `order_cells`: Assign pseudotime values to cells
- `plot_cells`: Visualize cells colored by metadata or pseudotime
- `fit_models`: Fit models for trajectory-based differential expression
