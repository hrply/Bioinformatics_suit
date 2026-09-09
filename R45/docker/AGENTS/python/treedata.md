# treedata

Tree data structure for hierarchical single-cell analysis

## Environment

`import treedata as td`

## Quick Demo

```python
import treedata as td
tdata = td.TreeData(obs=obs_df, var=var_df)
tdata.obst["lineage"] = tree
tdata.write("output.tdata")
```

## Key Functions

- `TreeData`: Create a TreeData object combining observation data and trees
- `obst`: Store tree structures associated with observations
- `write`: Write TreeData to disk
