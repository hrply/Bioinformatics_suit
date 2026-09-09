# sopa

Spatial omics protein analysis and visualization

## Environment

`import sopa`

Python: `/opt/scverse-incompat-incompat-incompat/sopa/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat-incompat/sopa/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import sopa
sopa.pp.read_cohort("path/to/data")
sopa.tl.segment()
```
