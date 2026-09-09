# delnx

Neural network-based cell type classification for single cells

## Environment

`import delnx`

Python: `/opt/scverse-incompat-incompat/delnx/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/delnx/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import delnx
model = delnx.train(adata, label_col="cell_type")
predictions = delnx.predict(model, adata_query)
```
