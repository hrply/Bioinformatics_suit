# cellphonedb

Cell-cell communication analysis from single-cell data

## Environment

`from cellphonedb.src.core.methods import cpdb_statistical_analysis_method`

## Quick Demo

```python
from cellphonedb.src.core.methods import cpdb_statistical_analysis_method
cpdb_results = cpdb_statistical_analysis_method(
    cpdb_file_path="cellphonedb.zip",
    meta_file_path="meta.tsv",
    counts_file_path="counts.tsv",
    counts_data="hgnc_symbol")
```

## Key Functions

- `cpdb_statistical_analysis_method`: Run statistical cell-cell communication analysis
- `cpdb_method`: Run basic CellPhoneDB analysis
