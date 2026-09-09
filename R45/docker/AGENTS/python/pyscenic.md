# pyscenic

Gene regulatory network inference using SCENIC

## Environment

`from pyscenic import aucell, grnboost`

## Quick Demo

```python
from pyscenic import grnboost, aucell
adjacencies = grnboost(expression_matrix, tf_names=tf_list)
auc_mtx = aucell(expression_matrix, regulons)
```

## Key Functions

- `grnboost`: Infer gene regulatory network using gradient boosting
- `aucell`: Score regulon activity per cell using AUC
- `prune2df`: Prune modules to identify regulons
