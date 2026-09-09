# CellChat

Cell-cell communication analysis from scRNA-seq

## Environment

`library(CellChat)`

## Quick Demo

```r
library(CellChat)
cellchat <- createCellChat(object = seurat_obj)
cellchat <- identifyOverExpressedGenes(cellchat)
cellchat <- computeCommProb(cellchat)
cellchat <- aggregateNet(cellchat)
```

## Key Functions

- `createCellChat`: Initialize a CellChat object from a Seurat object
- `identifyOverExpressedGenes`: Find over-expressed genes per cell group
- `computeCommProb`: Compute communication probabilities between cell pairs
- `aggregateNet`: Aggregate communication network by cell type
- `netVisual_circle`: Visualize cell-cell communication as a circle plot
