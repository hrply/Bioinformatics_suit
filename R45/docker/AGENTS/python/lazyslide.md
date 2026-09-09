# lazyslide

Lazy evaluation-based whole slide image analysis

## Environment

`import lazyslide as ls`

## Quick Demo

```python
import lazyslide as ls
wsi = ls.read_slide("slide.svs")
tiles = ls.tile(wsi, tile_size=256)
features = ls.extract_features(tiles)
```

## Key Functions

- `read_slide`: Load a whole slide image
- `tile`: Extract tiles from a slide image
- `extract_features`: Extract features from tiles using a model
