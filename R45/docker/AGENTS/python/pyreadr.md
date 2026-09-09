# pyreadr

Read R data files (.rds, .rda) in Python

## Environment

`import pyreadr`

## Quick Demo

```python
import pyreadr
result = pyreadr.read_r("data.rds")
df = result[None]
pyreadr.save(df, "output.rds")
```

## Key Functions

- `read_r`: Read an RDS or RData file into Python objects
- `save`: Save a DataFrame to an RDS file
