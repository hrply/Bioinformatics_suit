# bengrn

Gene regulatory network benchmarking toolkit

## Environment

`import bengrn`


Python: `/opt/scverse-incompat-incompat-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import bengrn as bg
net = bg.generate_benchmark_network(n_genes=100)
bg.evaluate(grn_inferred, net)
```

## Key Functions

- `generate_benchmark_network`: Generate a ground-truth GRN for benchmarking
- `evaluate`: Evaluate an inferred GRN against ground truth
- `compute_metrics`: Compute AUROC and AUPRC metrics
