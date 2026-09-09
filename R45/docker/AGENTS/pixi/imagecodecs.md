# imagecodecs

Image encoding/decoding codecs (conda)

## Environment

`import imagecodecs`


Python: `/opt/scverse-incompat-incompat/.pixi/envs/default/bin/python`
Docker: `docker exec rbio /opt/scverse-incompat-incompat/.pixi/envs/default/bin/python script.py`

## Quick Demo

```python
import imagecodecs
img = imagecodecs.imread("image.tif")
imagecodecs.imwrite(img, "output.png")
```

## Key Functions

- `imread`: Read an image file using appropriate codec
- `imwrite`: Write an image to file
- `check_decode`: Check if a codec is available for decoding
