# ComplexHeatmap

Complex and customizable heatmap visualizations

## Environment

`library(ComplexHeatmap)`

## Quick Demo

```r
library(ComplexHeatmap)
Heatmap(matrix(rnorm(100), nrow = 10),
        name = "expr",
        top_annotation = HeatmapAnnotation(group = rep(c("A", "B"), each = 5)))
```

## Key Functions

- `Heatmap`: Create a heatmap from a matrix
- `HeatmapAnnotation`: Define row or column annotations for heatmaps
- `draw`: Draw a Heatmap or HeatmapList object
- `anno_simple`: Create simple annotation graphics
