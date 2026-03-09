# R-bio 安装顺序详细文档

## 概述

本文档定义了 R-bio Docker 镜像的包安装顺序，基于依赖关系分析。

---

## 1. Dockerfile 层级结构

```
rocker/r-geospatial:4.5 (官方基础镜像)
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ Stage 1: Rbio_base.dockerfile                      │
│ 镜像: r-bio:base                                   │
│ - 系统依赖扩展                                     │
│ - pak 包管理器                                     │
│ - 核心 CRAN 包 (tidyverse, ggplot2 等)             │
│ - Bioconductor 基础设施                             │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ Stage 2: Rbio_r.dockerfile (需创建)                 │
│ 镜像: r-bio:r                                       │
│ - Seurat, Signac, SingleR                           │
│ - Giotto, GiottoClass                              │
│ - scran, scater, edgeR                              │
│ - limma, DESeq2, GSVA                              │
│ - 注释数据库 (org.*.db)                             │
│ - 基因组数据库 (BSgenome.*)                          │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ Stage 3: Rbio_python.dockerfile                    │
│ 镜像: r-bio:python                                  │
│ - Python 3.12 虚拟环境                              │
│ - numpy, scipy, pandas, matplotlib                 │
│ - scanpy, anndata, h5py                            │
│ - reticulate + Giotto Python 环境                  │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│ Stage 4: Rbio_cuda.dockerfile (可选)               │
│ 镜像: r-bio:gpu                                      │
│ - CUDA Toolkit 12.4/13.0                           │
│ - cuDNN                                             │
│ - PyTorch with CUDA                                 │
│ - scvi-tools, RAPIDS (可选)                         │
└─────────────────────────────────────────────────────┘
```

---

## 2. 系统依赖安装顺序

### 2.1 必须先安装 (Rbio_base)

```bash
# 构建工具
build-essential cmake curl wget git libtool pkg-config

# R 开发库
libcurl4-openssl-dev libssl-dev libxml2-dev libbz2-dev liblzma-dev zlib1g-dev
libhdf5-dev libglpk-dev libgit2-dev libffi-dev

# Python 开发库 (Rbio_python)
libncurses5-dev libreadline-dev libsqlite3-dev
```

### 2.2 CUDA 依赖 (Rbio_cuda, 可选)

```bash
# CUDA Toolkit
cuda-toolkit-12-4 或 cuda-toolkit-13-0

# cuDNN
libcudnn9-cuda-12 或 libcudnn9-cuda-13
```

---

## 3. R 包安装顺序

### 3.1 Level 0: 核心基础包 (Rbio_base)

```r
# 包管理器
pak

# Bioconductor 基础设施
BiocManager
BiocVersion

# S4 系统
S4Vectors
IRanges
GenomicRanges
GenomeInfoDb
Biobase
BiocGenerics
BiocParallel
```

### 3.2 Level 1: 数据结构包 (Rbio_base)

```r
# SingleCellExperiment 系统
SummarizedExperiment
SingleCellExperiment

# 延迟数组
DelayedArray
DelayedMatrixStats
HDF5Array
MatrixGenerics

# HDF5 支持
rhdf5
rhdf5filters
```

### 3.3 Level 2: 注释数据库 (Rbio_r)

```r
# 注释基础设施
AnnotationDbi

# 物种注释
org.Hs.eg.db
org.Mm.eg.db

# 基因组
BSgenome
BSgenome.Hsapiens.UCSC.hg38
BSgenome.Mmusculus.UCSC.mm39
```

### 3.4 Level 3: 分析工具基础 (Rbio_r)

```r
# 差异分析
limma
edgeR
DESeq2

# 单细胞分析
scran
scater

# 可视化
ggplot2
patchwork
cowplot
```

### 3.5 Level 4: 单细胞核心包 (Rbio_r)

```r
# Seurat 依赖
SeuratObject
spatstat
spatstat.explore
spatstat.geom
Rcpp
RcppRoll
irlba
uwot
FNN
MASS

# 核心单细胞包
Seurat
Signac
SingleR
Azimuth
```

### 3.6 Level 5: 空间转录组 (Rbio_r)

```r
# Giotto
GiottoClass
Giotto

# 轨迹分析
monocle3
destiny
slingshot
```

### 3.7 Level 6: 高级分析 (Rbio_r)

```r
# 细胞通讯
CellChat
cellchat

# 深度分析
GSVA
GSEABase
AUCell
decoupleR

# 轨迹
RaceID
SCENIC
```

---

## 4. Python 包安装顺序

### 4.1 Level 0: 核心库 (Rbio_python)

```bash
numpy
scipy
pandas
matplotlib
seaborn
```

### 4.2 Level 1: 文件格式和工具 (Rbio_python)

```bash
h5py
tables
zarr
anndata
scanpy
```

### 4.3 Level 2: 机器学习和可视化 (Rbio_python)

```bash
scikit-learn
numba
umap-learn
leidenalg
python-igraph
squidpy
scvelo
```

### 4.4 Level 3: 深度学习 (Rbio_cuda, 可选)

```bash
torch
scvi-tools
cell2location
```

### 4.5 Level 4: GPU 加速 (Rbio_cuda, 可选)

```bash
cupy-cuda12x
cudf-cu12
cuml-cu12
rapids-singlecell
```

---

## 5. 特殊处理

### 5.1 reticulate 环境

```r
# 在 Rbio_python 中创建
reticulate::install_miniconda()
reticulate::conda_create("r-reticulate", python_version = "3.12")
reticulate::conda_create("giotto_env", python_version = "3.12")
```

### 5.2 BSgenome 离线安装

```bash
# 如果有离线包
R CMD INSTALL BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz
```

### 5.3 presto 安装

```r
# 从 GitHub 安装
remotes::install_github("immunogenomics/presto")
```

---

## 6. 构建命令

```bash
# Stage 1: 基础镜像
docker build -f Rbio_base.dockerfile -t r-bio:base .

# Stage 2: R 包镜像
docker build -f Rbio_r.dockerfile -t r-bio:r .

# Stage 3: Python 镜像
docker build -f Rbio_python.dockerfile -t r-bio:python .

# Stage 4: GPU 镜像 (可选)
docker build -f Rbio_cuda.dockerfile -t r-bio:gpu .
```

---

## 7. 验证命令

```bash
# 验证 R 包
docker run --rm -it r-bio:r R -e "
library(Seurat);
library(Signac);
library(Giotto);
library(SingleR);
library(org.Hs.eg.db);
library(BSgenome.Hsapiens.UCSC.hg38);
"

# 验证 Python 包
docker run --rm -it r-bio:python python3 -c "
import scanpy
import anndata
import numpy
import pandas
"
```

---

*生成时间: 2026-03-06*
