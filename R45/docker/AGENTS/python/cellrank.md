# cellrank

Fate mapping and trajectory inference using RNA velocity

## Environment

`import cellrank as cr`

## Quick Demo

```python
import scanpy as sc
import cellrank as cr
adata = sc.read_h5ad("data.h5ad")
kernel = cr.kernels.VelocityKernel(adata)
estimator = cr.estimators.GPCCA(kernel)
estimator.fit()
estimator.predict()
```

## Key Functions

- `VelocityKernel`: Compute transition matrix from RNA velocity
- `GPCCA`: Generalized Perron cluster analysis for fate mapping
- `predict`: Predict terminal states and fate probabilities
- `plot_macrostates`: Visualize identified macrostates
