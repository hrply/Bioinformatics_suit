# cell-blast

Cell type annotation via transcriptome reference mapping

## Environment

`import cellblast as cb`

## Quick Demo

```python
import cellblast as cb
ref = cb.data.RefData.load("reference.cblast")
query = cb.data.AnnData.load("query.h5ad")
result = ref.annotate(query)
```

## Key Functions

- `RefData.load`: Load a reference transcriptome database
- `annotate`: Annotate query cells by mapping to reference
- `build_reference`: Build a reference from annotated data
