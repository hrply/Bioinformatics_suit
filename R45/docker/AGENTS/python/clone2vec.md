# clone2vec

Clonal lineage embedding from VDJ sequencing data

## Environment

`import clone2vec as c2v`

## Quick Demo

```python
import clone2vec as c2v
model = c2v.Clone2Vec(adata)
model.train()
embeddings = model.get_embeddings()
```

## Key Functions

- `Clone2Vec`: Initialize clone2vec model from VDJ data
- `train`: Train the clonal embedding model
- `get_embeddings`: Extract learned clonal embeddings
