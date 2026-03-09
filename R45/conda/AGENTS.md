# R-bio 项目说明

## 顶层约束（iFlow 权限限制）

| 范围 | 路径 | 权限 |
|------|------|------|
| **项目目录** | `~/software/sh/R-bio/R45` | ✅ 允许访问和修改 |
| **Conda 环境** | `/fast/@runtime/bio/conda/envs/bio` | ✅ 允许访问和修改 |
| **其他目录** | 任何其他路径 | ❌ 禁止访问和修改 |

**重要**：iFlow 的所有操作必须限制在上述允许范围内，不得访问或修改任何其他目录或文件。

---

## 项目概述

**R-bio** 是一个用于在 Conda 环境中自动安装 R 4.5.2 + Bioconductor 3.22 生物信息学工具包的 Shell 脚本项目。该项目主要用于单细胞测序数据分析，核心目标包括安装 Seurat、Signac、Giotto 等主流分析工具。

### 核心技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| R | 4.5.2 | R 语言基础环境 |
| Bioconductor | 3.22 | R 生物信息学包管理器 |
| Python | 3.12 | 辅助脚本和可视化 |
| Conda/Mamba | - | 包管理工具 |

### 核心分析包

| 包名 | 用途 |
|------|------|
| **Seurat** | 单细胞 RNA-seq 分析 |
| **Signac** | 单细胞 ATAC-seq 分析 |
| **Azimuth** | 单细胞参考映射 |
| **Giotto** | 空间转录组分析 |
| **presto** | 快速单细胞差异分析 |

---

## 目录结构

```
/home/hrply/software/sh/R-bio/R45/
├── Rbio_install.sh              # 主安装脚本（按顺序执行所有 Stage）
├── Rbio_common.sh               # 公共函数库（所有 Stage 共享）
├── Rbio_download_bsgenome.sh    # 下载 BSgenome 离线包
│
├── Rbio_stage1_conda_deps.sh    # Stage 1: Conda 编译依赖
├── Rbio_stage2_prebuilt_r.sh    # Stage 2: 预编译 R 包
├── Rbio_stage3_python.sh        # Stage 3: Python 包
├── Rbio_stage4_r_packages.sh    # Stage 4: R 包 (CRAN + Bioconductor)
├── Rbio_stage5_seurat.sh        # Stage 5: Seurat + Signac + Azimuth
├── Rbio_stage7_giotto.sh        # Stage 7: Giotto
├── Rbio_stage8_extra.sh         # Stage 8: 额外工具包 (scanpy, SingleR)
└── Rbio_stage_gpu.sh            # GPU: GPU Python 包 + CUDA
```

**注意**: Stage 6 (ArchR) 已跳过，因为 ArchR 不适配 R 4.5

---

## 安装使用

### 前置条件

```bash
# 创建 Conda 环境
conda create -n bio r-base=4.5.2 python=3.12
conda activate bio
```

### 完整安装

```bash
# CPU 版本
./Rbio_install.sh --cpu [--china]

# GPU 版本
./Rbio_install.sh --gpu [--china]
```

### 分阶段安装

```bash
# 从指定阶段开始
./Rbio_install.sh --stage 5 --china

# 单独执行某个 Stage
./Rbio_stage5_seurat.sh --china
./Rbio_stage7_giotto.sh --china
```

### 下载离线基因组包

```bash
./Rbio_download_bsgenome.sh --china
```

---

## 脚本参数说明

| 参数 | 说明 |
|------|------|
| `--cpu` | 安装 CPU 版本（默认） |
| `--gpu` | 安装 GPU 版本（包含 GPU Python 包） |
| `--china` | 使用国内镜像源（清华源） |
| `--password PWD` | 提供 sudo 密码 |
| `--stage N` | 从指定阶段开始安装 (1-8, gpu) |
| `--help` | 显示帮助信息 |

---

## 安装阶段详解

| Stage | 脚本 | 主要内容 |
|-------|------|----------|
| Stage 1 | Rbio_stage1_conda_deps.sh | Conda 编译依赖、系统库 |
| Stage 2 | Rbio_stage2_prebuilt_r.sh | 预编译 R 包 |
| Stage 3 | Rbio_stage3_python.sh | Python 包（numpy, pandas, scanpy 等） |
| Stage 4 | Rbio_stage4_r_packages.sh | R 包（CRAN + Bioconductor 核心包） |
| Stage 5 | Rbio_stage5_seurat.sh | Seurat + Signac + Azimuth + presto |
| Stage 7 | Rbio_stage7_giotto.sh | Giotto 空间转录组分析 |
| Stage 8 | Rbio_stage8_extra.sh | 额外工具包（scanpy, SingleR 等） |
| GPU | Rbio_stage_gpu.sh | GPU Python 包、CUDA 13 |

---

## 验证安装

```bash
# 验证 R 包
Rscript -e "library(Seurat); library(Signac); library(Giotto)"

# 验证 Python 包
python3 -c "import scanpy; import umap"
```

---

## 注意事项

1. **镜像源**: 国内用户建议使用 `--china` 参数加速下载
2. **环境隔离**: 必须在 Conda 环境中运行，脚本会检查 `CONDA_PREFIX` 环境变量
3. **版本锁定**: 使用 `--freeze-installed` 防止 R 版本被意外升级
4. **离线包**: BSgenome.Hsapiens.UCSC.hg38 需要提前下载离线安装
5. **跳过 ArchR**: Stage 6 (ArchR) 不适配 R 4.5，已永久跳过

---

## 公共函数库 (Rbio_common.sh)

主要提供以下功能：

- `rbio_init`: 初始化环境（解析参数、检查环境）
- `setup_environment`: 配置 R 环境（写入 Rprofile.site）
- `verify_installation`: 验证安装结果
- 日志函数: `log_info`, `log_warn`, `log_error`, `log_stage`

---

## 日志输出

所有安装日志输出到 `.test/logs/` 目录：

```
.test/logs/
└── r45_stage_YYYYMMDD_HHMMSS.log
```

---

*最后更新: 2026-03-04*
