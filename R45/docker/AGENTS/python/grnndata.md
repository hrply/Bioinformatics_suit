# grnndata

Gene regulatory network data structure and utilities

## Environment

`import grnndata as grn`

## Quick Demo

```python
import grnndata as grn
grn_adata = grn.GRNAnnData(adata)
grn_adata.varp["grn"] = adjacency_matrix
```

## Key Functions

- `GRNAnnData`: Create a GRN AnnData container for gene regulatory networks
- `from_pyscenic`: Import SCENIC results into GRNAnnData format
