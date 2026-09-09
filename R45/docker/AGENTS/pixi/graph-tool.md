# graph-tool

Efficient network analysis and graph algorithms (conda)

## Environment

`import graph_tool as gt`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import graph_tool as gt
g = gt.Graph(directed=False)
v = g.add_vertex(100)
e = g.add_edge_list(edge_list)
pr = gt.centrality.pagerank(g)
```

## Key Functions

- `Graph`: Create a graph object
- `add_vertex`: Add vertices to the graph
- `add_edge_list`: Add edges from a list
- `centrality.pagerank`: Compute PageRank centrality
