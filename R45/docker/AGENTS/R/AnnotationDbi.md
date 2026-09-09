# AnnotationDbi

Database interface for annotation data mapping

## Environment

`library(AnnotationDbi)`

## Quick Demo

```r
library(AnnotationDbi)
library(org.Hs.eg.db)
select(org.Hs.eg.db,
       keys = c("TP53", "BRCA1"),
       columns = c("ENTREZID", "GENENAME"),
       keytype = "SYMBOL")
```

## Key Functions

- `select`: Query annotation columns for given keys
- `keys`: List available keys in an annotation database
- `columns`: List available columns in an annotation database
- `mapIds`: Map identifiers between annotation types
