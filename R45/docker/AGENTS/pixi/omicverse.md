# omicverse

Multi-omic single-cell analysis platform

## Environment

`import omicverse as ov`


Python: `/opt/scverse-incompat-incompat-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import omicverse as ov
ov.single.batch_correction(adata, batch_key="batch")
ov.single.celltype_annotation(adata)
```

## Key Functions

- `single.batch_correction`: Integrate data across batches
- `single.celltype_annotation`: Annotate cell types automatically
- `single.get_neighbor`: Compute neighbor graph
