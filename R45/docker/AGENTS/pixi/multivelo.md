# multivelo

Multi-omic RNA velocity integration

## Environment

`import multivelo as mv`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import multivelo as mv
adata_rna, adata_atac = mv.pp.filter_multiome(adata_rna, adata_atac)
mv.tl.velocity(adata_rna, adata_atac)
mv.pl.velocity_plot(adata_rna)
```

## Key Functions

- `pp.filter_multiome`: Filter paired RNA and ATAC data
- `tl.velocity`: Estimate multi-omic velocity
- `pl.velocity_plot`: Visualize multi-omic velocity results
