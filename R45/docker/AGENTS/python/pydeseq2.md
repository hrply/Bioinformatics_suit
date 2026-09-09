# pydeseq2

Differential expression using DESeq2 method in Python

## Environment

`from pydeseq2 import DESeq2`

## Quick Demo

```python
from pydeseq2 import DESeq2
dds = DESeq2(counts_df, clinical_df, design_factors="condition")
dds.deseq2()
res = dds.results_df
```

## Key Functions

- `DESeq2`: Initialize DESeq2 analysis with counts and metadata
- `deseq2`: Run the full DESeq2 pipeline
- `results_df`: Get differential expression results as a DataFrame
- `plot_MA`: Generate an MA plot of results
