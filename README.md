# Seurat+Signac(ArchR)+Azimuth+Giotto+Scanpy+Pytorch生信集合环境一键安装脚本

**该项目是一个基于Ubuntu 24.04的下列常用生信软件包集成环境的构建项目**

由于AI尤其是CLI工具的不断进步，生信分析门槛越来越低，利用CLI工具进行自动化分析的价值日益升高。但是CLI工具需要依赖于本地/远程有可访问的数据处理环境，因此需要先部署常用的生信分析环境。

思路一：分别创建独立的conda环境/docker环境/Renv/Python环境，然后把名称及调用方法写入CLI工具的知识库，让其自动调用。这样的优点是部署简单，尤其是docker构建，基本上直接拉官方镜像，然后分别设置不同的端口，结合Rstudio/Python的API或者通过docker run传入的方式调用运行即可。但这样的缺点是，若使用conda/renv/python venv，则同一个CLI需要频繁的激活/切换不同的环境，而且renv很难通过命令行进行激活；若使用docker，多个容器间沟通和目录挂载存在一定的限制，并且多容器的资源消耗较大。

思路二：部署一个包含可能共存的常用工具包的集成环境，然后让CLI进行调用。优点是非常适合CLI工具，缺点就是部署非常麻烦，需要解决各种依赖问题。

这里提供了一个包括以下经典软件的集成环境部署方法，由IFLOW/Qwen-code工具结合我3个月的反复调试，提供了DOCKER和Conda两种部署方式，均在Ubuntu 24.04 + RTX5060ti环境下部署成功。

**Docker环境**: 部署文件位于docker文件夹内，参考其说明进行安装（构建R44的时候不了解，实际上基于rocker/geospatial系列镜像进行构建最省事）

**Conda环境**: 部署文件位于conda文件夹内，参考其说明进行安装

**建议提前下载BSgenome.Hsapiens.UCSC.hg38源码包至本地，否则容易出现网络错误**：可访问[Bioconductor](https://bioconductor.org/packages//release/data/annotation/html/BSgenome.Hsapiens.UCSC.hg38.html)获取当前版本的文件，然后先用下载软件高速下载。其中BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz是确认支持R4.4.3的。

## ArchR推荐使用官方docker镜像部署

R44文件夹内提供了包含Seurat+Signac+ArchR++Azimuth+Giotto+Scanpy+Pytorch的构建文件，由于ArchR在4.5版构建的依赖及其难以解决，这里提供R4.4.3环境下的构建文件，同样docker和conda各一份，但其他额外软件未经测试，需要的可以自行添加，国内只剩西湖大学镜像还有R 4.4匹配的bioconductor镜像。
该版本包安装一些新软件，BiocManager需要添加update = FALSE，以避免更新包导致需要解决一堆依赖问题。若非必须，更推荐ArchR单独构建一个docker容器（也可以基于参考conda脚本，注释掉stage5脚本内seurat、signac和azimuth的主包安装命令然后依次单独运行脚本）

# QWEN.md - R-bio 生信环境部署项目

## 项目概述

**项目名称**: R-bio 生信环境自动化部署
**项目类型**: 生物信息学环境配置 / Shell脚本
**技术栈**: Bash + Conda + R + Python

本项目提供 **Seurat + Signac + ArchR + Azimuth + Giotto + Scanpy + PyTorch** 生信分析集成环境的一键安装脚本，支持 Docker 和 Conda 两种部署方式。

---

## 目录结构

```
R-bio/
├── R44/                          # R 4.4.x 版本（推荐用于 ArchR）
│   ├── conda/                    # Conda 部署脚本
│   │   ├── Rbio_install.sh      # 主安装脚本
│   │   ├── Rbio_common.sh       # 公共函数库
│   │   ├── Rbio_stage1.sh       # Stage 1: Conda 编译依赖
│   │   ├── Rbio_stage2.sh       # Stage 2: 预编译 R 包
│   │   ├── Rbio_stage3.sh       # Stage 3: Python 包
│   │   ├── Rbio_stage4.sh       # Stage 4: R 包 (CRAN + Bioc)
│   │   ├── Rbio_stage5.sh       # Stage 5: Seurat + Signac + Azimuth
│   │   ├── Rbio_stage6.sh       # Stage 6: ArchR
│   │   ├── Rbio_stage7.sh       # Stage 7: Giotto
│   │   ├── Rbio_stage8.sh       # Stage 8: 额外工具包
│   │   ├── Rbio_stage_gpu.sh    # GPU Stage: GPU Python 包
│   │   └── Rbio_download_bsgenome.sh  # 下载 BSgenome 离线包
│   └── docker/                   # Docker 部署文件
├── R45/                          # R 4.5.x 版本
│   ├── conda/                    # Conda 部署脚本（简化版）
│   │   ├── Rbio_install.sh      # 主安装脚本
│   │   ├── Rbio_1.sh ~ Rbio_4.sh # 分阶段安装脚本
│   │   ├── Rbio_python.sh       # Python 包安装
│   │   ├── RAPIDS/              # RAPIDS GPU 加速环境
│   │   └── AnalysisDemo.py      # GPU 分析测试脚本
│   └── docker/                   # Docker 部署文件
└── README.md                     # 项目说明
```

---

## 核心安装包

### R 包

| 包名 | 说明 | 安装阶段 |
|------|------|---------|
| Seurat | 单细胞分析 | Stage 5 |
| Signac | 单细胞染色质分析 | Stage 5 |
| Azimuth | 单细胞参考映射 | Stage 5 |
| presto | 快速差异表达 | Stage 5 |
| ArchR | 染色质可及性分析 | Stage 6 |
| Giotto | 空间转录组分析 | Stage 7 |
| monocle3 | 轨迹分析 | Stage 4 |

### Python 包

| 包名 | 说明 | 安装阶段 |
|------|------|---------|
| numpy | 数值计算 | Stage 3 |
| pandas | 数据处理 | Stage 3 |
| scanpy | 单细胞分析 | Stage 8 |
| umap | 降维 | Stage 3 |
| h5py | HDF5 文件 | Stage 3 |
| torch | 深度学习 | GPU Stage |

---

## 使用方法

### R44 版本（推荐用于 ArchR）

```bash
# 创建并激活 Conda 环境
conda create -n rbio -c conda-forge r-base=4.4.3 python=3.12 mamba -y
conda activate rbio

# 执行完整安装（CPU版本）
cd R44/conda
./Rbio_install.sh --cpu --china

# 或指定从某个 Stage 开始
./Rbio_install.sh --stage 5 --china

# GPU 版本
./Rbio_install.sh --gpu --china
```

### R45 版本

```bash
# 创建环境
conda create -n rbio45 -c conda-forge r-base=4.5 python=3.12 mamba -y
conda activate rbio45

# 执行安装
cd R45/conda
./Rbio_install.sh --china > Rbio.log 2>&1 &

# RAPIDS GPU 加速（单独构建）
cd RAPIDS
bash -x build_cu130.sh
```

### 单独执行某个 Stage

```bash
# R44 版本
./Rbio_stage5.sh --china
./Rbio_stage_gpu.sh --china

# R45 版本
./Rbio_3.sh --china
```

### 验证安装

```bash
# R 包验证
Rscript -e "library(Seurat); library(Signac); library(ArchR); library(Giotto)"

# Python 包验证
python3 -c "import scanpy; import torch; print('OK')"
```

---

## 关键配置

### 国内镜像源

| 类型 | 镜像地址 |
|------|----------|
| CRAN | `https://mirrors.tuna.tsinghua.edu.cn/CRAN/` |
| Bioconductor | `https://mirrors.westlake.edu.cn/bioconductor` |
| PyPI | `https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple` |

### GitHub Token

用于避免 GitHub API 限速，配置方式：

```bash
# 方式1: 环境变量
export GITHUB_TOKEN=your_token

# 方式2: 文件
echo 'your_token' > ~/.github_token
```

### 代理设置

```bash
export HTTP_PROXY=http://your-proxy:port
export HTTPS_PROXY=http://your-proxy:port
```

---

## 日志与调试

- **日志目录**: `.test/logs/`
- **日志格式**: `${ENV_NAME}_stage_${TIMESTAMP}.log`
- **锁定文件清理**: 脚本自动清理 `00LOCK-*` 遗留锁定文件

---

## 注意事项

### R44 vs R45 选择

- **R44**: 推荐，ArchR 兼容性最佳
- **R45**: 更新版本，ArchR 依赖问题较多

### BSgenome 离线安装

建议提前下载 BSgenome.Hsapiens.UCSC.hg38 源码包至本地：

```bash
./Rbio_download_bsgenome.sh
```

### RAPIDS 与 Scanpy 冲突

RAPIDS 最新版基于 numpy < 2.0，而 scanpy 新版基于 numpy 2.x，存在冲突。建议：
- 使用 Docker 容器单独运行 RAPIDS GPU 加速分析
- Conda 环境用于常规 R/Python 分析

---

## 相关项目

### CLI 环境

- **路径**: `/fast/@runtime/bio/conda/envs/cli/`
- **用途**: CLI 工具运行环境
- **配置**: `prompt_cli.md` 包含 Docker 应用开发规范

### 数据分析目录

- **路径**: `/ssd/bioraw/online/`
- **用途**: 生信数据存储与分析
- **子项目**:
  - `dss/`: DSS 结肠炎单细胞分析项目
  - `1/`: 其他分析项目

---

## 开发规范

### Shell 脚本

- 使用 `#!/bin/bash` shebang
- 使用 `set -e` 确保错误时退出
- 日志函数: `log_info`, `log_warn`, `log_error`, `log_stage`
- 参数解析: `--china`, `--password`, `--stage`, `--help`

### R 脚本

- 使用 `BiocManager::install(..., update = FALSE)` 避免依赖问题
- 设置镜像源到 `Rprofile.site`

### Python 脚本

- 使用 `pip install --no-cache-dir` 减少缓存
- GPU 检测使用 `cupy.is_available()`

---

## 故障排查

### 常见问题

1. **Conda 环境未激活**
   ```
   错误: 未检测到 Conda 环境！
   解决: conda activate <env_name>
   ```

2. **R 版本不匹配**
   ```
   脚本会自动重装 r-base=4.4.3
   ```

3. **GitHub API 限速**
   ```
   配置 GITHUB_TOKEN 环境变量
   ```

4. **Bioconductor 镜像问题**
   ```
   国内使用西湖大学镜像: mirrors.westlake.edu.cn
   ```

---

*最后更新: 2026-03-18*