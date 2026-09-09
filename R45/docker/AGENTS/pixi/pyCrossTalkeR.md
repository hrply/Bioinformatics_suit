# pyCrossTalkeR

Ligand-receptor interaction analysis for single-cell data

## Environment

`import pycrosstalker`


Python: `/opt/scverse-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import pycrosstalker as pct
result = pct.run(adata, cell_type_key="cell_type")
result.plot_interactions()
```

## Key Functions

- `run`: Run ligand-receptor interaction analysis
- `plot_interactions`: Visualize significant cell-cell interactions
