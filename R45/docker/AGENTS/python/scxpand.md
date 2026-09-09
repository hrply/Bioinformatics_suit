# scxpand

TCR repertoire expansion analysis

## Environment

`import scxpand as sx`

## Quick Demo

```python
import scxpand as sx
result = sx.run(adata, clone_key="clone_id")
result.summary()
```

## Key Functions

- `run`: Analyze TCR clonal expansion from single-cell data
- `summary`: Summarize expansion results
