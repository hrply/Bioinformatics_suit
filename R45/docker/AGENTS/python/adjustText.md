# adjustText

Automatic text label placement to avoid overlaps in matplotlib

## Environment

`from adjustText import adjust_text`

## Quick Demo

```python
import matplotlib.pyplot as plt
from adjustText import adjust_text
fig, ax = plt.subplots()
ax.scatter(x, y)
texts = [ax.text(xi, yi, label) for xi, yi, label in zip(x, y, labels)]
adjust_text(texts)
```

## Key Functions

- `adjust_text`: Automatically adjust text positions to minimize overlaps
