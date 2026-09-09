# pcdl

PhysiCell digital biology data loader and visualizer

## Environment

`import pcdl`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import pcdl
mcds = pcdl.load("output/")
df = mcds.get_cell_df()
```

## Key Functions

- `load`: Load PhysiCell simulation output
- `get_cell_df`: Extract cell data as a DataFrame
- `plot_timeseries`: Plot time series data from simulation
