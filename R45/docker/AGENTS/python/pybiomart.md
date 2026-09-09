# pybiomart

Python client for BioMart database queries

## Environment

`import pybiomart`

## Quick Demo

```python
import pybiomart
server = pybiomart.Server(host="http://www.ensembl.org")
dataset = server.marts["ENSEMBL_MART_ENSEMBL"].datasets["hsapiens_gene_ensembl"]
result = dataset.query(attributes=["ensembl_gene_id", "external_gene_name"])
```

## Key Functions

- `Server`: Connect to a BioMart server
- `query`: Query a BioMart dataset for specified attributes
- `list_attributes`: List available attributes for a dataset
