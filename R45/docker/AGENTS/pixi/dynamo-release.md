# dynamo-release

RNA velocity and vector field analysis for single cells

## Environment

`import dynamo as dyn`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import dynamo as dyn
adata = dyn.sample_data.zebrafish()
dyn.pp.recipe_monocle(adata)
dyn.tl.dynamics(adata)
dyn.pl.streamline_plot(adata)
```

## Key Functions

- `pp.recipe_monocle`: Preprocess data for dynamo analysis
- `tl.dynamics`: Estimate RNA dynamics and velocity
- `tl.cell_velocities`: Compute cell transition probabilities
- `pl.streamline_plot`: Plot velocity streamlines on embedding
