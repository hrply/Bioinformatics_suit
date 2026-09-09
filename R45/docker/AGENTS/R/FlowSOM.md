# FlowSOM

Self-organizing map clustering for flow/mass cytometry

## Environment

`library(FlowSOM)`

## Quick Demo

```r
library(FlowSOM)
fSOM <- ReadInput(flowFrame, transform = TRUE, scale = TRUE)
fSOM <- BuildSOM(fSOM, colsToUse = marker_cols)
fSOM <- BuildMST(fSOM)
PlotStars(fSOM)
```

## Key Functions

- `ReadInput`: Read flow cytometry data into a FlowSOM object
- `BuildSOM`: Build a self-organizing map from input data
- `BuildMST`: Build a minimum spanning tree from SOM nodes
- `PlotStars`: Visualize marker expression on the MST
