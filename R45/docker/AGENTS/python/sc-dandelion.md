# sc-dandelion

BCR/TCR repertoire analysis for single-cell data

## Environment

`import dandelion as ddl`

## Quick Demo

```python
import dandelion as ddl
adata = ddl.read_10x_airr("filtered_contig_annotations.csv")
ddl.tl.chain_qc(adata)
ddl.tl.define_clones(adata)
```

## Key Functions

- `read_10x_airr`: Read 10x VDJ annotation files
- `tl.chain_qc`: Quality control on BCR/TCR chains
- `tl.define_clones`: Define clonotypes from VDJ sequences
- `pl.clone_overlap`: Visualize clonotype overlap between groups
