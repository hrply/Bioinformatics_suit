# circlize

Circular visualization for genomic data

## Environment

`library(circlize)`

## Quick Demo

```r
library(circlize)
circos.initialize(factors = chr, xlim = as.matrix(chr_ranges))
circos.track(ylim = c(0, 1), panel.fun = function(x, y) {
  circos.text(CELL_META$xcenter, CELL_META$ycenter, CELL_META$sector.index)
})
circos.link("chr1", c(100, 200), "chr2", c(300, 400))
circos.clear()
```

## Key Functions

- `circos.initialize`: Initialize a circular plot with sectors
- `circos.track`: Add a track to the circular plot
- `circos.link`: Draw a link between two sectors
- `circos.clear`: Clear the circular plot parameters
