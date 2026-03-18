import numpy as np
import scanpy as sc
import rapids_singlecell as rsc
from scipy import sparse
import time
import torch

# ---------------------------------------------------------
# 1. 基础环境核查
# ---------------------------------------------------------
print("="*50)
print("🚀 Rbio AI-GPU 极限测试启动")
print("="*50)
print(f"PyTorch GPU 可用性: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"检测到 GPU: {torch.cuda.get_device_name(0)}")
else:
    print("❌ 警告: 未检测到 GPU，脚本可能无法运行！")
    exit(1)

# ---------------------------------------------------------
# 2. 模拟海量单细胞数据
# ---------------------------------------------------------
n_cells = 500000  # 50 万细胞 (可根据显存适当调整)
n_genes = 20000   # 2 万基因
density = 0.02    # 2% 的基因表达率 (模拟真实稀疏单细胞数据)

print(f"\n[1/4] 🧬 正在内存中生成庞大的模拟数据集: {n_cells} 细胞 x {n_genes} 基因...")
start_time = time.time()

# 生成随机的稀疏矩阵
sc_matrix = sparse.random(n_cells, n_genes, density=density, format='csr', dtype=np.float32)
sc_matrix.data = np.random.poisson(lam=1.5, size=sc_matrix.nnz).astype(np.float32)

# 构建 AnnData 对象
adata = sc.AnnData(sc_matrix)
adata.obs_names = [f"Cell_{i}" for i in range(n_cells)]
adata.var_names = [f"Gene_{i}" for i in range(n_genes)]

print(f"✅ 数据集生成完毕! 耗时: {time.time() - start_time:.2f} 秒")
print(f"📊 AnnData 形状: {adata.shape}")

# ---------------------------------------------------------
# 3. 数据迁移至 GPU
# ---------------------------------------------------------
print("\n[2/4] 🏎️ 将数据从 CPU 内存转移至 GPU 显存 (cuDF/CuPy)...")
start_time = time.time()
rsc.get.anndata_to_GPU(adata)
print(f"✅ 数据已进入 GPU! 耗时: {time.time() - start_time:.2f} 秒")

# ---------------------------------------------------------
# 4. GPU 加速的预处理与降维
# ---------------------------------------------------------
print("\n[3/4] ⚡ 开始执行 RAPIDS 预处理与降维 (预估 CPU 需 1小时+，GPU 仅需数秒)...")
start_time = time.time()

# 标准化与对数化
rsc.pp.normalize_total(adata, target_sum=1e4)
rsc.pp.log1p(adata)

# 提取高变基因 (Top 2000)
rsc.pp.highly_variable_genes(adata, n_top_genes=2000, flavor="seurat")
adata = adata[:, adata.var.highly_variable]

# 数据缩放
rsc.pp.scale(adata, max_value=10)

# PCA 降维
rsc.tl.pca(adata, n_comps=50)

print(f"✅ 预处理与 PCA 完毕! 耗时: {time.time() - start_time:.2f} 秒")

# ---------------------------------------------------------
# 5. GPU 加速的图构建、聚类与可视化降维
# ---------------------------------------------------------
print("\n[4/4] 🕸️ 开始构建邻接图并执行 Leiden 聚类与 UMAP...")
start_time = time.time()

# 计算 KNN 邻接图
rsc.pp.neighbors(adata, n_neighbors=15, n_pcs=50)

# Leiden 聚类
rsc.tl.leiden(adata, resolution=1.0)

# UMAP 降维
rsc.tl.umap(adata)

print(f"✅ 邻接图、聚类与 UMAP 完毕! 耗时: {time.time() - start_time:.2f} 秒")

# ---------------------------------------------------------
# 6. 结果抽查与写出
# ---------------------------------------------------------
print("\n🎉 全部 GPU 流程完美跑通！")
print("前 5 个细胞的 Leiden 聚类结果:")
print(adata.obs['leiden'].head(5))