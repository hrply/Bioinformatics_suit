# vitessce

Interactive visualization of spatial omics data

## Environment

`from vitessce import VitessceConfig, DataType, FileType`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
from vitessce import VitessceConfig, DataType as dt, FileType as ft
vc = VitessceConfig(name="My visualization")
vc.add_dataset(name="Data").add_object(adata)
widget = vc.widget()
```

## Key Functions

- `VitessceConfig`: Configure a Vitessce visualization session
- `add_dataset`: Add a dataset to the visualization
- `widget`: Render the interactive visualization widget
