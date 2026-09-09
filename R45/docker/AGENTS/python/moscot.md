# moscot

Multi-omic single-cell optimal transport analysis

## Environment

`import moscot as mc`

## Quick Demo

```python
import moscot as mc
problem = mc.problems.TemporalProblem(adata)
problem = problem.prepare(time_key="timepoint").solve()
result = problem.compute_interpolated_distance()
```

## Key Functions

- `TemporalProblem`: Define a temporal optimal transport problem
- `SpatialProblem`: Define a spatial alignment problem
- `prepare`: Prepare the OT problem for solving
- `solve`: Solve the optimal transport problem
