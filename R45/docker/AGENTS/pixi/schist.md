# schist

Stochastic block model clustering for single-cell data

## Environment

`import schist`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import schist
schist.tl.nested_model(adata)
adata.obs["schist_clusters"]
```

## Key Functions

- `tl.nested_model`: Fit nested stochastic block model for clustering
- `tl.overlapping_model`: Fit overlapping community detection model
