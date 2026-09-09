# pytximport

Import transcript-level quantification to gene-level counts

## Environment

`import pytximport as txi`

## Quick Demo

```python
import pytximport as txi
result = txi.tximport(
    "quant.sf",
    type="salmon",
    tx2gene=tx2gene_df
)
```

## Key Functions

- `tximport`: Import and summarize transcript-level counts to gene-level
