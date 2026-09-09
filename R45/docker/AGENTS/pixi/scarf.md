# scarf

Scalable analysis of single-cell data with factor analysis

## Environment

`import scarf`

Python: `/opt/scverse-incompat-incompat/scarf/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/scarf/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import scarf
adata = scarf.read_csv("matrix.csv")
scarf.pp.cal_qc(adata)
scarf.tl.flow(adata)
```
