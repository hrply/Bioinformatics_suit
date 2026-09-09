# AnnotationHub

Client for retrieving annotation resources from Bioconductor

## Environment

`library(AnnotationHub)`

## Quick Demo

```r
library(AnnotationHub)
ah <- AnnotationHub()
query(ah, c("Homo sapiens", "GTF"))
gr <- ah[["AH12345"]]
```

## Key Functions

- `AnnotationHub`: Create an AnnotationHub connection object
- `query`: Search for annotation resources by keywords
- `display`: Interactively browse available resources
