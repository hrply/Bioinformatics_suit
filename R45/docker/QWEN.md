# R-bio Docker Project - QWEN.md

## Project Overview

**R-bio Docker** is a multi-stage Docker build system for creating comprehensive R + Bioconductor environments tailored for single-cell sequencing data analysis. The project produces GPU-accelerated and CPU-only container images with pre-installed bioinformatics tools.

### Core Technologies

| Component | Version | Description |
|-----------|---------|-------------|
| **R** | 4.5.2 | Base R environment (from `rocker/geospatial:4.5.2`) |
| **Bioconductor** | 3.22 | R package manager for bioinformatics |
| **Python** | 3.12 | Virtual environment for single-cell analysis |
| **CUDA** | 13.0 | GPU acceleration support (GPU image only) |
| **GDAL/GEOS/PROJ** | - | Geospatial libraries (pre-installed in base) |

### Key Analysis Packages

| Package | Purpose |
|---------|---------|
| **Seurat** | Single-cell RNA-seq analysis |
| **Signac** | Single-cell ATAC-seq analysis |
| **Giotto** | Spatial transcriptomics analysis |
| **Azimuth** | Single-cell reference mapping |
| **SingleR** | Automated cell type annotation |
| **CellChat** | Cell-cell communication analysis |
| **monocle3** | Trajectory analysis |
| **scanpy** | Python single-cell analysis |
| **scvi-tools** | Deep learning for single-cell |

---

## Directory Structure

```
/home/hrply/software/sh/R-bio/R45/docker/
├── AGENTS.md                      # Project documentation (Chinese)
├── QWEN.md                        # This file
├── .env.example                   # Environment variable template
├── .github_token                  # GitHub token for API rate limits
├── docker-compose.yml             # Docker Compose configuration
├── docker_build.sh                # Interactive build script
├── Rbio_base.dockerfile           # Stage 1: Base R + Bioconductor
├── Rbio_cpu.dockerfile            # Stage 2: CPU analysis packages
├── Rbio_cuda.dockerfile           # Stage 3: GPU/CUDA support
├── Rbio_final.dockerfile          # Stage 4: Jupyter + RStudio services
├── verify_cpu_packages.R          # R package verification script
├── verify_gpu_packages.py         # Python GPU package verification
└── external_files/
    ├── BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz
    ├── BSgenome.Mmusculus.UCSC.mm39_1.4.3.tar.gz
    ├── Rbio_download_bsgenome.sh
    ├── RaceID/                    # RaceID package files
    └── ScType/                    # ScType package files
```

---

## Build Architecture

### Multi-Stage Build Flow

```
Stage 1 (Rbio_base.dockerfile):
  rocker/geospatial:4.5.2
    → base-sys (system deps + pak/devtools)
    → base-cran (CRAN core packages)
    → base-bioc (Bioconductor infrastructure)
    → base-ml (ML/statistics + Seurat deps)
    → r-bio:base (final base image)

Stage 2 (Rbio_cpu.dockerfile):
  r-bio:base
    → cpu-python (Python 3.12 + scanpy/scvelo)
    → cpu-annotation (annotation databases)
    → cpu-core (Seurat/Signac/SingleR)
    → cpu-giotto (Giotto package)
    → ... (intermediate stages)
    → r-bio:cpu (final CPU image)

Stage 3 (Rbio_cuda.dockerfile):
  r-bio:cpu
    → CUDA 13.0 + cuDNN 9
    → PyTorch/JAX/TensorFlow GPU
    → RAPIDS (cudf, cuml)
    → r-bio:gpu (GPU-accelerated image)

Stage 4 (Rbio_final.dockerfile):
  r-bio:cpu or r-bio:gpu
    → Jupyter Lab + R kernel
    → RStudio Server configuration
    → r-bio:cpu-final or r-bio:gpu-final
```

### Intermediate Images

| Image | Stage | Purpose |
|-------|-------|---------|
| `r-bio:base-sys` | 1a | System deps + R package managers |
| `r-bio:base-cran` | 1b | CRAN core packages |
| `r-bio:base-bioc` | 1c | Bioconductor infrastructure |
| `r-bio:base-ml` | 1d | ML/statistics foundation |
| `r-bio:cpu-python` | 2a-2c | Python environment |
| `r-bio:cpu-annotation` | 2d-2e | Annotation databases |
| `r-bio:cpu-core` | 2f-2j | Core analysis tools |
| `r-bio:cpu-giotto` | 2l | Giotto package |

---

## Building and Running

### Quick Start

```bash
# Navigate to project directory
cd /home/hrply/software/sh/R-bio/R45/docker

# Interactive build (recommended)
bash docker_build.sh

# Build with options
bash docker_build.sh --stage 1 --gpu --final --mirror china
```

### Build Script Options

| Option | Description |
|--------|-------------|
| `--stage N` | Start from stage N (1=base, 2=cpu, 3=gpu, 4=final) |
| `--gpu` | Build GPU version with CUDA |
| `--final` | Build final image with Jupyter + RStudio |
| `--from-scratch` | Clean old images before building |
| `--mirror china` | Use Chinese mirrors (Tsinghua) |
| `--http-proxy URL` | HTTP proxy for all network requests |
| `--github-proxy URL` | Proxy for GitHub downloads only |
| `-y, --no-interactive` | Skip interactive prompts |

### Direct Docker Build

```bash
# Base image
docker build -f Rbio_base.dockerfile \
  --build-arg mirror=China \
  -t r-bio:base .

# CPU image
docker build -f Rbio_cpu.dockerfile \
  --build-arg mirror=China \
  -t r-bio:cpu .

# GPU image
docker build -f Rbio_cuda.dockerfile \
  -t r-bio:gpu .

# Final image (CPU)
docker build -f Rbio_final.dockerfile \
  --target cpu-final \
  -t r-bio:cpu-final .

# Final image (GPU)
docker build -f Rbio_final.dockerfile \
  --target gpu-final \
  -t r-bio:gpu-final .
```

### Running Containers

```bash
# CPU version with RStudio + Jupyter
docker run -d \
  -p 8787:8787 -p 8888:8888 \
  -e RSTUDIO_USER=rstudio \
  -e RSTUDIO_PASS=YourPassword123! \
  -v /path/to/data:/data \
  r-bio:cpu-final

# GPU version (requires NVIDIA Container Toolkit)
docker run --gpus all -d \
  -p 8787:8787 -p 8888:8888 \
  -e RSTUDIO_USER=rstudio \
  -e RSTUDIO_PASS=YourPassword123! \
  -v /path/to/data:/data \
  r-bio:gpu-final
```

### Using Docker Compose

```bash
# Edit .env file first
cp .env.example .env
# Edit .env with your settings

# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

---

## Development Conventions

### Build Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mirror` | default | Set to `China` for Tsinghua mirrors |
| `CRAN_URL` | cloud.r-project.org | CRAN mirror URL |
| `BIOC_URL` | bioconductor.org | Bioconductor mirror URL |
| `PIP_INDEX_URL` | - | PyPI mirror URL |
| `http_proxy` | - | HTTP proxy (affects all network) |
| `github_proxy` | - | GitHub-only proxy |
| `GITHUB_TOKEN` | - | GitHub token for API rate limits |

### Mirror Configuration

When using `--mirror china`:

| Service | URL |
|---------|-----|
| CRAN | `https://mirrors.tuna.tsinghua.edu.cn/CRAN` |
| Bioconductor | `https://mirrors.tuna.tsinghua.edu.cn/bioconductor` |
| PyPI | `https://pypi.tuna.tsinghua.edu.cn/simple` |
| Ubuntu APT | `https://mirrors.tuna.tsinghua.edu.cn/ubuntu` |

### GitHub Token Setup

To avoid GitHub API rate limits:

```bash
# Option 1: Environment variable
export GITHUB_TOKEN=your_token

# Option 2: File-based (project reads .github_token)
echo 'your_token' > .github_token
```

### Logging

Build logs are stored in:
```
.test/logs/docker_build/
├── Rbio_base_YYYYMMDD_HHMMSS.log
├── Rbio_cpu_YYYYMMDD_HHMMSS.log
├── Rbio_gpu_YYYYMMDD_HHMMSS.log
├── Rbio_final_YYYYMMDD_HHMMSS.log
└── build_config_YYYYMMDD_HHMMSS.txt
```

---

## Testing and Verification

### Verify CPU Packages

```bash
# Run verification script in container
docker run r-bio:cpu Rscript /path/to/verify_cpu_packages.R
```

### Verify GPU Packages

```bash
# Run GPU verification (requires GPU)
docker run --gpus all r-bio:gpu \
  python3 /path/to/verify_gpu_packages.py
```

### Manual Package Verification

```bash
# R packages
docker run -it r-bio:cpu R
> library(Seurat)
> library(Signac)
> library(Giotto)
> library(SingleR)

# Python packages
docker run -it r-bio:cpu bash
# source /opt/venv/bin/activate
# python3 -c "import scanpy; import scvelo"
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `docker_build.sh` | Main build orchestration script |
| `Rbio_base.dockerfile` | Stage 1: Base R + Bioconductor (5 sub-stages) |
| `Rbio_cpu.dockerfile` | Stage 2: CPU analysis packages (12+ sub-stages) |
| `Rbio_cuda.dockerfile` | Stage 3: CUDA 13.0 + GPU libraries |
| `Rbio_final.dockerfile` | Stage 4: Jupyter Lab + RStudio Server |
| `docker-compose.yml` | Production deployment configuration |
| `.env.example` | Environment variable template |
| `verify_cpu_packages.R` | R package verification (200+ packages) |
| `verify_gpu_packages.py` | Python GPU package verification |

---

## Troubleshooting

### Common Issues

1. **GitHub API Rate Limiting**
   - Set `GITHUB_TOKEN` environment variable or create `.github_token` file

2. **Bioconductor Package Failures**
   - Use `--mirror china` for Tsinghua mirror
   - Check `BIOC_URL` is correct

3. **Azimuth/Giotto Installation Failures**
   - These packages are prone to failure
   - Build uses intermediate images for recovery points
   - Resume from `r-bio:cpu-core` if needed

4. **GPU Build Failures**
   - Ensure NVIDIA drivers are installed on host
   - Verify CUDA version compatibility

5. **Slow Downloads**
   - Use `--http-proxy` or `--github-proxy` options
   - Use `--mirror china` for Chinese users

---

