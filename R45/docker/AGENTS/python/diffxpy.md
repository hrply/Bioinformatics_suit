# diffxpy

Differential expression testing for single-cell data

## Environment

`import diffxpy as dx`

## Quick Demo

```python
import diffxpy as dx
result = dx.test.wald(
    data=adata,
    grouping="condition",
    formula_loc="~ 1 + condition"
)
```

## Key Functions

- `test.wald`: Wald test for differential expression
- `test.t_test`: T-test for differential expression
- `test.rank`: Rank-based test for differential expression
