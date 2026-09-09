# pyUCell

Single-cell gene signature scoring using UCell method

## Environment

`import pyucell`


Python: `/opt/scverse-incompat-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import pyucell as uc
scores = uc.score_genes(adata, gene_list=["CD3E", "CD4", "IL7R"])
```

## Key Functions

- `score_genes`: Score gene signatures per cell using the UCell method
