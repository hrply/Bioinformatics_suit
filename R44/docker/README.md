# 项目概述

本项目旨在构建一个完整的R语言单细胞基因组学分析Docker环境，整合Seurat、Signac、Azimuth、ArchR和Giotto等主流分析工具。采用模块化多阶段构建，支持Simple/CPU/GPU等多种镜像变体。

---

## Dockerfile架构

### 镜像构建依赖关系

```
R-bioBase.dockerfile
    ├── stage1 (系统依赖 + Python + 基础R包)
    ├── stage2 (Seurat + Signac + Azimuth)
    ├── stage3 (ArchR) [内部依赖]
    ├── stage4 (Giotto) [内部依赖]
    └── stage5 (RStudio配置 + 额外工具)
         ↓
    ┌────┴────┐
    ↓         ↓
R-bioSimple  R-bioCPU
    ↓         ↓
    └────┬────┘
         ↓
    ┌────┴────┐
    ↓         ↓
R-bioGPU   R-bioGPUfull
```

### 镜像类型说明

| 镜像 | Dockerfile | 基础 | 说明 |
|------|------------|------|------|
| stage1-5 | R-bioBase.dockerfile | rocker/tidyverse:4.4.3 | 构建阶段镜像 |
| simple | R-bioSimple.dockerfile | rocker/tidyverse:4.4.3 | 精简版，复制stage文件 |
| cpu_v1.0.0 | R-bioCPU.dockerfile | r-bio:stage1 | CPU完整版，保留系统依赖 |
| gpu_v1.0.0 | R-bioGPU.dockerfile | r-bio:cpu + r-bio:stage5 | GPU精简版，复制CUDA |
| gpufull | R-bioGPUfull.dockerfile | r-bio:cpu | GPU完整版，直接安装CUDA |

### 核心文件

| 文件 | 说明 |
|------|------|
| R-bioBase.dockerfile | 基础镜像多阶段构建（stage1-5） |
| R-bioSimple.dockerfile | 精简版镜像（无系统依赖库） |
| R-bioCPU.dockerfile | CPU完整版镜像 |
| R-bioGPU.dockerfile | GPU精简版（从stage5构建CUDA后复制） |
| R-bioGPUfull.dockerfile | GPU完整版（在CPU镜像上直接安装CUDA） |
| dockerbuild.sh | 交互式Docker构建脚本 |

---

## 构建流程

### 使用Docker构建脚本（推荐）

```bash
export GITHUB_TOKEN=xxxxx
./dockerbuild.sh
```

脚本功能：
- 交互式选择镜像类型（Base/Simple/CPU/GPU/GPUfull/全部）
- 自动检测依赖并询问是否构建
- 支持测试模式（使用r-bio-test前缀，不覆盖已有镜像）
- 代理配置（自定义/默认/禁用）
- 自动记录日志到 `.test/logs/`

### 手动构建Docker镜像

```bash
# 1. 构建基础镜像阶段
docker build --target stage1 -t r-bio:stage1 -f R-bioBase.dockerfile .
docker build --target stage2 -t r-bio:stage2 -f R-bioBase.dockerfile .
docker build --target stage5 -t r-bio:stage5 -f R-bioBase.dockerfile .

# 2. 构建最终镜像
docker build -t r-bio:simple -f R-bioSimple.dockerfile .
docker build -t r-bio:cpu_v1.0.0 -f R-bioCPU.dockerfile .
docker build -t r-bio:gpu_v1.0.0 -f R-bioGPU.dockerfile .
docker build -t r-bio:gpufull -f R-bioGPUfull.dockerfile .

# 使用代理构建
docker build -t r-bio:cpu_v1.0.0 -f R-bioCPU.dockerfile \
  --build-arg HTTP_PROXY=http://127.0.0.1:7890 \
  --build-arg HTTPS_PROXY=http://127.0.0.1:7890 .
```

### 运行Docker容器

```bash
# 运行RStudio Server (CPU版本)
docker run -d -p 8787:8787 -p 3838:3838 \
  -e PASSWORD=your_password \
  -v /path/to/data:/data \
  r-bio:cpu_v1.0.0

# GPU版本（需要nvidia-docker）
docker run --gpus all -d -p 8787:8787 -p 3838:3838 \
  -e PASSWORD=your_password \
  r-bio:gpu_v1.0.0

# 访问RStudio: http://localhost:8787
# 访问Shiny:  http://localhost:3838
```

---

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| VENV_PATH | /opt/venv | Python venv路径 |
| MINICONDA_PATH | /opt/r-miniconda | Miniconda路径 |
| R_LIB_PATH | /usr/local/lib/R/site-library | R库路径 |
| HTTP_PROXY | - | HTTP代理地址 |
| HTTPS_PROXY | - | HTTPS代理地址 |

---

## 技术栈

### 基础环境

- **R版本**: 4.4.3
- **基础镜像**: rocker/tidyverse:4.4.3
- **Python版本**: 3.10 (venv) + Miniconda
- **Java**: OpenJDK 17
- **CUDA**: 13.0 (GPU版本)

### 集成的分析工具

| 工具 | 用途 |
|------|------|
| Seurat | 单细胞RNA-seq分析 |
| Signac | 单细胞ATAC-seq分析 |
| Azimuth | 自动单细胞分析流程 |
| ArchR | ATAC-seq分析框架 |
| Giotto | 空间转录组分析 |

### GPU包（GPU版本）

| 包名 | 用途 |
|------|------|
| PyTorch | 深度学习框架 |
| TensorFlow | 深度学习框架 |
| JAX | 高性能计算 |
| RAPIDS (cudf, cuml, cugraph) | GPU数据分析 |
| scvi-tools | 单细胞深度学习 |
| cellbender | 单细胞去噪 |
| PyTorch Geometric | 图神经网络 |

### Web服务

- **RStudio Server**: Ubuntu 24.04官方仓库
- **Shiny Server**: Ubuntu 24.04官方仓库

---

## Docker环境变量

| 变量 | 值 | 说明 |
|------|-----|------|
| PATH | /opt/venv/bin:/opt/r-miniconda/bin:... | Python优先级 |
| RETICULATE_MINICONDA_ENABLED | FALSE | 禁用reticulate自动Miniconda |
| RETICULATE_MINICONDA_PATH | /opt/r-miniconda | Miniconda路径 |
| HDF5_PLUGIN_PATH | /lzf | HDF5插件路径 |
| CUDA_HOME | /usr/local/cuda | CUDA路径（GPU版本） |

### 端口映射

| 端口 | 服务 |
|------|------|
| 8787 | RStudio Server |
| 3838 | Shiny Server |

---

## 项目状态

### 当前状态

- 状态: 模块化重构完成，构建脚本可用
- 更新时间: 2026-02-28

### 完成项

- [x] 模块化Dockerfile架构（Base/Simple/CPU/GPU/GPUfull）
- [x] 多阶段构建优化（stage1-5）
- [x] 交互式Docker构建脚本（dockerbuild.sh）
- [x] 本地安装脚本（Rbio_install.sh）
- [x] 依赖自动检测和构建
- [x] 测试模式支持
- [x] 代理配置（ARG方式，非硬编码）
- [x] 国内镜像源支持（清华/中科大）
- [x] Conda环境支持
- [x] RStudio Server集成
- [x] Shiny Server集成
- [x] CUDA 13.0 + cuDNN支持
- [x] GPU Python包（RAPIDS, PyTorch, TensorFlow等）
- [x] 镜像版本化标签（cpu_v1.0.0, gpu_v1.0.0）

---

## 验证结果 (2026-02-28)

### CPU镜像验证 (r-bio:cpu_v1.0.0)

| 包名 | 状态 | 版本 |
|------|------|------|
| Seurat | ✓ | 5.4.0 |
| Signac | ✓ | 1.16.0 |
| ArchR | ✓ | 1.0.3 |
| Giotto | ✓ | 4.2.2 |
| harmony | ✓ | 1.2.4 |
| presto | ✓ | 1.0.0 |
| leidenbase | ✓ | 0.1.36 |
| monocle | ✓ | 2.34.0 |
| Azimuth | ✓ | 5.0 |

**Seurat功能测试**: 通过 (CreateSeuratObject → NormalizeData → FindVariableFeatures → ScaleData)

### GPU镜像验证 (r-bio:gpu_v1.0.0)

**CUDA版本**: 13.0.88

| Python包 | 状态 | 版本 |
|----------|------|------|
| torch | ✓ | 2.10.0+cu130 |
| tensorflow | ✓ | 2.20.0 |
| jax | ✓ | 0.9.0.1 |
| cupy | ✓ | 14.0.1 |
| cudf | ✓ | 26.02.01 |
| cuml | ✓ | 26.02.000 |
| scanpy | ✓ | 1.12 |
| scvi | ✓ | 1.4.2 |

**GPU运行时测试**: ✓ 通过
- 显卡: NVIDIA GeForce RTX 5060 Ti (16GB)
- 驱动: 580.126.09
- PyTorch CUDA矩阵计算: 通过

---

## 全局原则

### 构建顺序

必须按依赖顺序构建：
1. R-bioBase（生成stage1, stage2, stage5）
2. Simple 或 CPU
3. GPU 或 GPUfull

### 代理配置

- Docker构建：使用ARG方式传递代理，不硬编码
- 本地安装：通过环境变量 `HTTP_PROXY` / `HTTPS_PROXY` 设置
- 默认代理: `http://192.168.3.147:7890`

### 镜像大小参考

| 镜像 | 大小 |
|------|------|
| simple | ~8GB |
| cpu_v1.0.1 | ~13GB |
| gpu_v1.0.1 | ~30GB |
| gpufull_v1.0.1 | ~35GB |

---

## 测试日志

日志目录: `.test/logs/`

| 文件 | 说明 |
|------|------|
| docker_build_rbio_*.log | Docker构建日志 |
| rbio_install_*.log | 本地安装日志 |

---

## 默认凭据

- **用户名**: rstudio
- **密码**: 由环境变量PASSWORD指定

---

*最后更新: 2026-02-28*
