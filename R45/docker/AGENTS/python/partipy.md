# partipy

Partition-based clustering for single-cell data

## Environment

`import partipy as pt`

## Quick Demo

```python
import partipy as pt
pt.tl.archetype(adata, n_archetypes=3)
pt.pl.archetype_plot(adata)
```

## Key Functions

- `tl.archetype`: Find archetypal cells using archetypal analysis
- `pl.archetype_plot`: Visualize archetypes in a 2D embedding
