# doubletdetection

Doublet detection in scRNA-seq count matrices

## Environment

`import doubletdetection`

## Quick Demo

```python
import doubletdetection as dd
clf = dd.BoostClassifier()
labels = clf.fit(adata.X).predict()
adata.obs["doublet"] = labels
```

## Key Functions

- `BoostClassifier`: Gradient boosted classifier for doublet detection
- `fit`: Fit the doublet classifier on count data
- `predict`: Predict doublet labels for cells
