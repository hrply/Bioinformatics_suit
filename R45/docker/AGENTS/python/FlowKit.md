# FlowKit

Flow cytometry data analysis and visualization

## Environment

`import flowkit as fk`

## Quick Demo

```python
import flowkit as fk
sample = fk.Sample("sample.fcs")
events = sample.get_events(source="raw")
gating_strategy = fk.GatingStrategy("gates.xml")
results = gating_strategy.gate_sample(sample)
```

## Key Functions

- `Sample`: Load and represent a flow cytometry sample
- `GatingStrategy`: Define and apply a gating hierarchy
- `get_events`: Extract event data from a sample
- `gate_sample`: Apply gating strategy to a sample
