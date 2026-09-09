# mowgli

Single-cell integration and alignment using optimal transport

## Environment

`import mowgli`

Python: `/opt/scverse-incompat-incompat/mowgli/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/mowgli/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import mowgli as mg
model = mg.Model()
model.integrate(adata_list)
```

## Notes

- Requires Python 3.11, torch<2, anndata<0.9
- Dependencies: torch, scanpy, matplotlib, mudata, scikit-learn, tqdm
