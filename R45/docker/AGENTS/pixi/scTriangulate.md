# scTriangulate

Multi-view clustering ensemble for single-cell analysis

## Environment

`import sctriangulate`

Python: `/opt/scverse-incompat/scTriangulate/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat/scTriangulate/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import sctriangulate as sct
sct.run(adata, n_neighbors=30)
```

## Notes

- Import name is `sctriangulate` (lowercase), not `scTriangulate`
- Locked to squidpy==1.2.0 and gseapy==0.10.4
