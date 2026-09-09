# pytometry

Flow and mass cytometry data analysis in Python

## Environment

`import pytometry as pm`

## Quick Demo

```python
import pytometry as pm
adata = pm.io.read_fcs("sample.fcs")
pm.pp.compensate(adata)
pm.pp.transform(adata, method="asinh", cofactor=5)
```

## Key Functions

- `io.read_fcs`: Read an FCS cytometry file into AnnData
- `pp.compensate`: Apply fluorescence compensation
- `pp.transform`: Apply transformation (e.g., arcsinh) to channels
