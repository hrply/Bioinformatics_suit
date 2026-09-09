# decoupler

Gene regulatory network and pathway activity inference

## Environment

`import decoupler as dc`

## Quick Demo

```python
import decoupler as dc
net = dc.get_progeny(organism="human")
dc.run_ulm(adata, net=net)
adata.obsm["ulm_estimate"]
```

## Key Functions

- `run_ulm`: Run univariate linear model for pathway activity
- `run_wsum`: Run weighted sum method for gene set scoring
- `get_progeny`: Retrieve PROGENy pathway gene sets
- `get_dorothea`: Retrieve DoRothEA gene regulatory networks
