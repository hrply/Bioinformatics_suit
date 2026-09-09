# kompot

Differential abundance and expression analysis for multi-ome data

## Environment

`import kompot as kp`

## Quick Demo

```python
import kompot as kp
result = kp.differential(adata, condition_key="condition")
result.plot_volcano()
```

## Key Functions

- `differential`: Run differential abundance and expression analysis
- `plot_volcano`: Visualize differential results as a volcano plot
