# cellbender

Remove background ambient RNA from scRNA-seq

## Environment

`from cellbender.remove_background import remove_background`

## Quick Demo

```python
from cellbender.remove_background import remove_background
remove_background(
    input_file="raw_gene_bc_matrices.h5",
    output_file="cellbender_output.h5",
    fpr=0.01,
    expected_cells=10000
)
```

## Key Functions

- `remove_background`: Remove ambient RNA background from raw count matrices
