# iFlow 项目记忆 - R-bio 自动化安装

## 项目目的

**R-bio 环境自动化安装**：通过多阶段（Stage 1-8 + GPU）顺序安装 R 和 Python 生物信息学包

**env要求**：需要预先配置`http_proxy`, `GITHUB_TOKEN`（或.github_token文件）避免部分下载问题

---

## 项目结构

| 文件 | 说明 |
|------|------|
| `Rbio_install.sh` | 主安装脚本，按顺序执行所有 Stage |
| `Rbio_common.sh` | 公共函数库（日志、镜像配置、环境检查） |
| `Rbio_stage1.sh` | Stage 1: Conda 编译依赖 |
| `Rbio_stage2.sh` | Stage 2: 预编译 R 包 (conda-forge) |
| `Rbio_stage3.sh` | Stage 3: Python 包 (含可视化) |
| `Rbio_stage4.sh` | Stage 4: R 包 (CRAN + Bioconductor) |
| `Rbio_stage5.sh` | Stage 5: Seurat + Signac + Azimuth |
| `Rbio_stage6.sh` | Stage 6: ArchR |
| `Rbio_stage7.sh` | Stage 7: Giotto |
| `Rbio_stage8.sh` | Stage 8: 额外工具包 (scanpy) |
| `Rbio_stage_gpu.sh` | GPU Stage: GPU Python 包 |
| `Rbio_download_bsgenome.sh` | 下载 BSgenome 离线包 |

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

---

## 使用方法

### 快速开始

```bash
# 创建并激活 Conda 环境
conda create -n rbio -c conda-forge r-base=4.4.3 python=3.12 mamba -y
conda activate rbio

# 执行完整安装
./Rbio_install.sh --cpu --china

# 或指定 Stage
./Rbio_install.sh --stage 5 --china
```

### 单独执行某个 Stage

```bash
./Rbio_stage5.sh --china
./Rbio_stage_gpu.sh --china
```

### 验证安装

```bash
Rscript -e "library(Seurat); library(Signac); library(ArchR); library(Giotto)"
```

---

## 关键配置

### 国内镜像源
- CRAN: `https://mirrors.tuna.tsinghua.edu.cn/CRAN/`
- Bioconductor: `https://mirrors.westlake.edu.cn/bioconductor` #目前R4.4最高支持Bioconductor 3.20，只有西湖大学还有archive
- PyPI: `https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple`

### GitHub Token
- 已在 `Rbio_common.sh` 中配置
- 用于加速 GitHub 包安装

### R 版本
- 要求: R 4.4.x
- Conda 环境变量: `CONDA_PREFIX`, `CONDA_DEFAULT_ENV`

---

## 日志目录

- 位置: `.test/logs/`
- 日志文件: `${ENV_NAME}_stage_${TIMESTAMP}.log`

---

*最后更新: 2026-03-05*
