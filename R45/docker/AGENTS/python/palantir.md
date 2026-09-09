# palantir

Pseudotime trajectory inference using diffusion maps

## Environment

`import palantir`

## Quick Demo

```python
import palantir
palantir.run_palantir(adata, early_cell="cell_0")
palantir.plot.plot_trajectory(adata)
```

## Key Functions

- `run_palantir`: Run Palantir pseudotime and fate probability inference
- `plot.plot_trajectory`: Visualize inferred trajectories
- `utils.run_diffusion_maps`: Compute diffusion maps for Palantir input
