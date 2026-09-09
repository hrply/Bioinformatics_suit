# SpatialCellChat

Spatially-resolved cell-cell communication analysis

## Environment

`library(SpatialCellChat)`

## Quick Demo

```r
library(SpatialCellChat)
scellchat <- createSpatialCellChat(object = cellchat_obj, spatial = coords)
scellchat <- computeSpatialComm(scellchat)
scellchat <- aggregateSpatialNet(scellchat)
```

## Key Functions

- `createSpatialCellChat`: Initialize a spatial CellChat object with spatial coordinates
- `computeSpatialComm`: Compute spatially-resolved communication probabilities
- `aggregateSpatialNet`: Aggregate spatial communication network
