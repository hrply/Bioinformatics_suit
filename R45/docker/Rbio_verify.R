#!/usr/bin/env Rscript

# =============================================================================
# Rbio_verify.R - 深度验证汇总版
# =============================================================================

# 1. 待验证完整包列表
raw_list <- c(
    "abind", "arrow", "bit", "bit64", "broom", "caTools", "Cairo", "car", "caret", 
    "cellranger", "checkmate", "circlize", "classInt", "cli", "clustree", "colorspace", 
    "commonmark", "conflicted", "cpp11", "crayon", "curl", "cachem", "data.table", 
    "desc", "devtools", "digest", "doParallel", "dplyr", "dqrng", "dtplyr", "effectsize", 
    "e1071", "ellipsis", "emmeans", "evaluate", "fansi", "fastcluster", "fastmap", 
    "fitdistrplus", "fs", "future", "future.apply", "gargle", "generics", "ggbeeswarm", 
    "ggdist", "ggExtra", "ggnewscale", "ggplot2", "ggplotify", "ggpubr", "ggrepel", 
    "ggridges", "ggrastr", "ggsignif", "ggthemes", "glmGamPoi", "glmnet", "glue", 
    "gplots", "gridExtra", "grr", "gstat", "gtable", "gtools", "harmony", "haven", 
    "here", "hms", "htmltools", "htmlwidgets", "httpuv", "httr", "ids", "igraph", 
    "irlba", "jsonlite", "knitr", "ks", "lattice", "later", "leiden", "lifecycle", 
    "listenv", "lme4", "logging", "lubridate", "magick", "magrittr", "MASS", "Matrix", 
    "matrixStats", "memoise", "memuse", "mime", "miniUI", "mclust", "mvtnorm", "ncdf4", 
    "nlme", "openxlsx", "openssl", "pak", "parallel", "patchwork", "pbapply", "pbmcapply", 
    "pheatmap", "pillar", "pkgbuild", "pkgload", "plotly", "plyr", "plogr", "polyclip", 
    "preprocessCore", "prettyunits", "progress", "progressr", "promises", "pscl", 
    "purrr", "R.utils", "R6", "ragg", "randomForest", "rappdirs", "raster", "RANN", 
    "RColorBrewer", "Rcpp", "RcppAnnoy", "RcppArmadillo", "RcppEigen", "RcppHNSW", 
    "RcppML", "RcppParallel", "RcppProgress", "RcppToml", "readr", "remotes", "reshape2", 
    "reticulate", "rlang", "RNetCDF", "ROCR", "rprojroot", "rsample", "RSQLite", 
    "Rtsne", "rvest", "s2", "scales", "scattermore", "selectr", "sessioninfo", "shiny", 
    "shinyBS", "shinydashboard", "snow", "sp", "spatialreg", "spdep", "speedglm", 
    "sparseMatrixStats", "stringi", "stringr", "survival", "svglite", "systemfonts", 
    "terra", "testthat", "textshaping", "tibble", "tidync", "tidyr", "tidyselect", 
    "tidyverse", "timechange", "tzdb", "units", "urlchecker", "urltools", "uwot", 
    "vegan", "vctrs", "viridis", "vroom", "waldo", "wk", "withr", "xfun", "xml2", 
    "xgboost", "yaml", "AnnotationDbi", "AnnotationFilter", "AnnotationHub", "AUCell", 
    "beachmat", "BiocGenerics", "BiocNeighbors", "BiocParallel", "BiocSingular", 
    "BiocVersion", "Biobase", "Biostrings", "bluster", "BSgenome", 
    "BSgenome.Hsapiens.UCSC.hg38", "BSgenome.Mmusculus.UCSC.mm39", "batchelor", 
    "CellChat", "celltalker", "ComplexHeatmap", "DESeq2", "DelayedArray", 
    "DelayedMatrixStats", "diffcyt", "edgeR", "ensembldb", "EnsDb.Hsapiens.v86", 
    "flowCore", "FlowSOM", "GenomeInfoDb", "GenomeInfoDbData", "GenomicRanges", 
    "GEOquery", "Giotto", "GiottoClass", "GlobalOptions", "GSEABase", "GSVA", "h5mread", 
    "HDF5Array", "impute", "IRanges", "JASPAR2020", "limma", "MAST", "MatrixGenerics", 
    "monocle", "monocle3", "Nebulosa", "org.Hs.eg.db", "org.Mm.eg.db", "presto", 
    "rhdf5", "rhdf5filters", "Rhdf5lib", "Rsamtools", "rtracklayer", "Rsubread", 
    "S4Vectors", "scater", "scde", "scDblFinder", "scran", "scuttle", "Seurat", 
    "SeuratData", "SeuratDisk", "SeuratObject", "SeuratWrappers", "Signac", 
    "SingleCellExperiment", "SingleR", "slingshot", "SpatialCellChat", 
    "SpatialExperiment", "SummarizedExperiment", "TFBSTools", "tradeSeq", "XVector", 
    "ALRA", "Azimuth", "BPCells", "MERINGUE", "N2R", "pagoda2", "srtdisk"
)
packages <- sort(unique(trimws(raw_list)))

cat("==================================================\n")
cat("R Package Deep Integrity Verification\n")
cat("==================================================\n\n")

success_count <- 0
missing_pkgs <- character(0)
broken_pkgs <- character(0)

for (pkg in packages) {
    # 使用 Rscript 启动独立子进程进行加载测试
    # 这样可以彻底屏蔽所有 Masked 冲突提示和 Loading 消息
    cmd <- sprintf("Rscript -e \"loadNamespace('%s')\" > /dev/null 2>&1", pkg)
    exit_code <- system(cmd)
    
    if (exit_code == 0) {
        cat(sprintf("[OK]      %s\n", pkg))
        success_count <- success_count + 1
    } else {
        # 如果子进程返回非0，说明加载失败
        # 进一步判断是根本没装，还是装了但二进制损坏
        if (!requireNamespace(pkg, quietly = TRUE)) {
            cat(sprintf("[MISSING] %s\n", pkg))
            missing_pkgs <- c(missing_pkgs, pkg)
        } else {
            cat(sprintf("[BROKEN]  %s\n", pkg))
            broken_pkgs <- c(broken_pkgs, pkg)
        }
    }
}

# 最终统计与清单输出
cat("\n==================================================\n")
cat("VERIFICATION SUMMARY\n")
cat("==================================================\n")
cat(sprintf("Total Checked : %d\n", length(packages)))
cat(sprintf("Passed        : %d\n", success_count))
cat(sprintf("Missing       : %d\n", length(missing_pkgs)))
cat(sprintf("Broken        : %d\n", length(broken_pkgs)))
cat("--------------------------------------------------\n")

# 如果有失败的包，列出清单
if (length(missing_pkgs) > 0) {
    cat("MISSING PACKAGES (Not installed):\n")
    cat(paste0("  - ", missing_pkgs, collapse = "\n"), "\n\n")
}

if (length(broken_pkgs) > 0) {
    cat("BROKEN PACKAGES (Installation corrupted):\n")
    cat(paste0("  - ", broken_pkgs, collapse = "\n"), "\n\n")
}

if (length(missing_pkgs) > 0 || length(broken_pkgs) > 0) {
    cat("RESULT: FAILED\n")
    quit(save = "no", status = 1)
} else {
    cat("RESULT: SUCCESS\n")
    quit(save = "no", status = 0)
}