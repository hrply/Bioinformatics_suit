# gptbioinsightor

LLM-powered biological data interpretation

## Environment

`import gptbioinsightor as gbi`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import gptbioinsightor as gbi
result = gbi.analyze(adata, query="What cell types are present?")
print(result)
```

## Key Functions

- `analyze`: Use LLM to interpret single-cell data
- `summarize_markers`: Generate natural language summary of marker genes
