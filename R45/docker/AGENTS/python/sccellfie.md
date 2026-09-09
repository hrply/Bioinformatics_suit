# sccellfie

Single-cell metabolic activity scoring

## Environment

`import sccellfie as sf`

## Quick Demo

```python
import sccellfie as sf
sf.tl.compute_metabolic_tasks(adata)
sf.pl.heatmap(adata, groupby="cell_type")
```

## Key Functions

- `tl.compute_metabolic_tasks`: Score metabolic activity per cell
- `pl.heatmap`: Visualize metabolic scores as a heatmap
