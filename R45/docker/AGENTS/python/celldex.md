# celldex

Reference datasets for cell type annotation

## Environment

`import celldex`

## Quick Demo

```python
import celldex
ref = celldex.fetch_reference("hpca")
print(ref.shape)
```

## Key Functions

- `fetch_reference`: Download a reference dataset for cell annotation
- `list_references`: List available reference datasets
