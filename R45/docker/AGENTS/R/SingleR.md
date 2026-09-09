# SingleR

Automated cell type annotation using reference transcriptomes

## Environment

`library(SingleR)`

## Quick Demo

```r
library(SingleR)
pred <- SingleR(test = sce, ref = ref_data, labels = ref_labels)
table(pred$labels)
```

## Key Functions

- `SingleR`: Annotate cells by comparing to reference expression profiles
- `trainSingleR`: Train a reference classifier for cell type annotation
- `plotScoreHeatmap`: Visualize annotation scores across cell types
