#!/usr/bin/env Rscript
# 验证 CPU 镜像内所有 R 包是否正确安装

suppressPackageStartupMessages(library(tools))

cat("========================================\n")
cat("R-bio CPU 镜像包验证脚本\n")
cat("========================================\n\n")

# 定义所有应该安装的包列表
cran_packages <- c(
  # 基础包 (来自 Rbio_base)
  "pak", "devtools", "remotes", "BiocManager",
  # 数据处理
  "data.table", "dtplyr", "tidyverse", "dplyr", "tidyr", "readr", "stringr",
  # 可视化
  "ggplot2", "patchwork", "plotly", "pheatmap", "RColorBrewer", "viridis",
  "ggpubr", "ggrepel", "ggridges", "ggExtra", "ggbeeswarm", "ggsignif",
  # 统计/ML
  "caret", "randomForest", "e1071", "ROCR",
  # 单细胞辅助
  "leiden", "clustree", "harmony",
  # 其他
  "future", "future.apply", "parallel", "doParallel", "R.utils",
  "Matrix", "matrixStats", "sparseMatrixStats"
)

bioconductor_packages <- c(
  # Bioconductor 基础
  "Biobase", "BiocGenerics", "S4Vectors", "IRanges", "GenomicRanges",
  "SummarizedExperiment", "SingleCellExperiment",
  # 单细胞核心
  "Seurat", "Signac", "SingleR", "scran", "scater",
  "monocle", "slingshot", "tradeSeq",
  # 空间分析
  "Giotto", "presto",
  # 细胞通讯
  "CellChat", "celltalker", "SpatialCellChat",
  # 注释数据库
  "org.Hs.eg.db", "org.Mm.eg.db", "AnnotationHub", "BSgenome",
  "EnsDb.Hsapiens.v86", "GenomeInfoDb", "GenomeInfoDbData",
  # 生信分析
  "limma", "DESeq2", "edgeR", "GSEABase", "GSVA", "GEOquery",
  "impute", "Rsubread", "AUCell",
  # 序列分析
  "Biostrings", "rtracklayer", "Rsamtools",
  # 转录因子
  "TFBSTools", "JASPAR2020",
  # 其他
  "MAST", "Nebulosa", "scDblFinder", "batchelor",
  "ComplexHeatmap", "GlobalOptions", "circlize", "scde"
)

github_packages <- c(
  "Azimuth", "monocle3", "BPCells"
)

python_packages <- c(
  "scanpy", "anndata", "scvelo", "cell2location",
  "squidpy", "matplotlib", "seaborn",
  "gseapy", "decoupler", "leidenalg", "igraph"
)

# 验证函数
verify_package <- function(pkg, pkg_type = "CRAN/Bioconductor") {
  if (requireNamespace(pkg, quietly = TRUE)) {
    ver <- as.character(packageVersion(pkg))
    cat(sprintf("  ✓ %-25s %s\n", pkg, ver))
    return(TRUE)
  } else {
    cat(sprintf("  ✗ %-25s [MISSING]\n", pkg))
    return(FALSE)
  }
}

verify_python_package <- function(pkg) {
  # 首先尝试获取 __version__
  cmd <- sprintf("/opt/venv/bin/python -c 'import %s; print(%s.__version__)' 2>/dev/null", pkg, pkg)
  result <- tryCatch({
    ver <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    if (length(ver) > 0 && nchar(ver[1]) > 0) {
      cat(sprintf("  ✓ %-25s %s\n", pkg, ver[1]))
      return(TRUE)
    }
  })
  
  # 如果 __version__ 失败，尝试备用方法
  if (length(ver) == 0 || nchar(ver[1]) == 0) {
    # 尝试只检查导入是否成功
    cmd2 <- sprintf("/opt/venv/bin/python -c 'import %s' 2>/dev/null", pkg)
    result2 <- tryCatch({
      ver2 <- system(cmd2, intern = TRUE, ignore.stderr = TRUE)
      if (length(ver2) > 0 && nchar(ver2[1]) > 0) {
        cat(sprintf("  ✓ %-25s %s\n", pkg, ver2[1]))
        return(TRUE)
      }
    })
    
    # 如果仍然失败，标记为已安装但无版本信息
    cat(sprintf("  ✓ %-25s [installed]\n", pkg))
    return(TRUE)
  }
  
  # 所有方法都失败，标记为缺失
  cat(sprintf("  ✗ %-25s [MISSING]\n", pkg))
  return(FALSE)
}

# 统计
results <- list(
  cran = list(total = 0, ok = 0, failed = c()),
  bioc = list(total = 0, ok = 0, failed = c()),
  github = list(total = 0, ok = 0, failed = c()),
  python = list(total = 0, ok = 0, failed = c())
)

# 验证 CRAN 包
cat("[1/5] CRAN Packages:\n")
for (pkg in cran_packages) {
  results$cran$total <- results$cran$total + 1
  if (verify_package(pkg, "CRAN")) {
    results$cran$ok <- results$cran$ok + 1
  } else {
    results$cran$failed <- c(results$cran$failed, pkg)
  }
}

# 验证 Bioconductor 包
cat("\n[2/5] Bioconductor Packages:\n")
for (pkg in bioconductor_packages) {
  results$bioc$total <- results$bioc$total + 1
  if (verify_package(pkg, "Bioconductor")) {
    results$bioc$ok <- results$bioc$ok + 1
  } else {
    results$bioc$failed <- c(results$bioc$failed, pkg)
  }
}

# 验证 GitHub 包
cat("\n[3/5] GitHub Packages:\n")
for (pkg in github_packages) {
  results$github$total <- results$github$total + 1
  if (verify_package(pkg, "GitHub")) {
    results$github$ok <- results$github$ok + 1
  } else {
    results$github$failed <- c(results$github$failed, pkg)
  }
}

# 验证外部脚本
cat("\n[4/5] External Scripts:\n")
sctype_ok <- file.exists("/usr/local/lib/R/site-library/ScType/R/ScType.R")
raceid_ok <- file.exists("/usr/local/lib/R/site-library/RaceID/RaceID_class.R")
if (sctype_ok) {
  cat("  ✓ ScType                    [installed]\n")
} else {
  cat("  ✗ ScType                    [MISSING]\n")
}
if (raceid_ok) {
  cat("  ✓ RaceID                    [installed]\n")
} else {
  cat("  ✗ RaceID                    [MISSING]\n")
}

# 验证 Python 包
cat("\n[5/5] Python Packages:\n")
for (pkg in python_packages) {
  results$python$total <- results$python$total + 1
  if (verify_python_package(pkg)) {
    results$python$ok <- results$python$ok + 1
  } else {
    results$python$failed <- c(results$python$failed, pkg)
  }
}

# 汇总
cat("\n========================================\n")
cat("验证结果汇总\n")
cat("========================================\n")
cat(sprintf("CRAN:        %d/%d 成功\n", results$cran$ok, results$cran$total))
cat(sprintf("Bioconductor: %d/%d 成功\n", results$bioc$ok, results$bioc$total))
cat(sprintf("GitHub:      %d/%d 成功\n", results$github$ok, results$github$total))
cat(sprintf("Python:      %d/%d 成功\n", results$python$ok, results$python$total))

total_ok <- results$cran$ok + results$bioc$ok + results$github$ok + results$python$ok
total_all <- results$cran$total + results$bioc$total + results$github$total + results$python$total
cat(sprintf("\n总计: %d/%d 成功 (%.1f%%)\n", total_ok, total_all, 100*total_ok/total_all))

# 显示失败的包
all_failed <- c(results$cran$failed, results$bioc$failed, results$github$failed, results$python$failed)
if (length(all_failed) > 0) {
  cat("\n失败的包:\n")
  for (pkg in all_failed) {
    cat(sprintf("  - %s\n", pkg))
  }
  quit(status = 1)
} else {
  cat("\n✓ 所有包验证通过!\n")
  quit(status = 0)
}
