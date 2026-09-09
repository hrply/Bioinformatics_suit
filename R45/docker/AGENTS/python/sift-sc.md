# sift-sc

Subcellular spatial imaging analysis toolkit

## Environment

`import sift`

## Quick Demo

```python
import sift
adata = sift.io.read("data.h5ad")
sift.tl.segment(adata)
sift.tl.quantify(adata)
```

## Key Functions

- `io.read`: Read spatial imaging data into AnnData
- `tl.segment`: Perform subcellular segmentation
- `tl.quantify`: Quantify subcellular features
