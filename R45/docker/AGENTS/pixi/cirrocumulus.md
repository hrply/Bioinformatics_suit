# cirrocumulus

Interactive visualization of large-scale single-cell data

## Environment

`import cirrocumulus`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import cirrocumulus as cc
cc.plot(adata)
```

## Key Functions

- `plot`: Launch interactive visualization for AnnData
- `add_data`: Add dataset to the visualization session
