"""
单细胞数据分析脚本 - 终极 GPU 优化版
功能：端到端全量 GPU 加速（QC、过滤、归一化、HVG、PCA）
亮点：解决 200GB 文件爆炸问题，极速全链路加速
Code by Gemini 3 Pro
"""
import sys
import os
import time
import anndata as ad
import numpy as np
import scipy.sparse as sp
from datetime import datetime

# ==========================================
# 参数配置
# ==========================================
MIN_GENES = 500        # 细胞最少基因数
MAX_GENES = 6000       # 细胞最多基因数（过滤双细胞）
MAX_MT_PCT = 10        # 线粒体百分比上限
MIN_CELLS = 50         # 基因最少细胞数
N_TOP_GENES = 2000     # 高变基因数
N_PCS = 50             # 主成分数
MAX_GPU_CELLS = 500000 # PCA 拟合最大采样数（显存保护）
USE_GPU = True         # 是否使用 GPU 加速

# ==========================================
# 日志与初始化设置 (保持你的优雅设计)
# ==========================================
if len(sys.argv) < 2:
    print("用法: python AnalysisDemo.py <sample.h5ad> [output.h5ad] [log_file]")
    sys.exit(1)

file_path = sys.argv[1]
input_dir = os.path.dirname(file_path)
input_basename = os.path.splitext(os.path.basename(file_path))[0]
output_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(input_dir, f"{input_basename}_filtered.h5ad")
log_file = sys.argv[3] if len(sys.argv) > 3 else os.path.join(input_dir, f"{input_basename}_analysis.log")

class Logger:
    def __init__(self, log_file):
        self.terminal = sys.stdout
        self.log = open(log_file, 'w', encoding='utf-8')
    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)
        self.log.flush()
    def flush(self):
        self.terminal.flush()
        self.log.flush()

sys.stdout = Logger(log_file)
sys.stderr = Logger(log_file)

print("="*60)
print("🚀 终极单细胞分析 - 全链路 GPU 极速版")
print(f"📂 输入文件: {file_path}")
print(f"📂 输出文件: {output_path}")
print("="*60)

# ==========================================
# GPU 环境检测与接管
# ==========================================
print("\n[0/5] 🔍 引擎点火: 环境检测...")
if USE_GPU:
    try:
        import cupy as cp
        import cuml
        import rapids_singlecell as rsc  # 👈 核心优化：全链路引入
        from cuml.decomposition import PCA as cuML_PCA
        
        if cp.is_available():
            print(f"✅ GPU 可用: {cp.cuda.runtime.getDeviceProperties(0)['name'].decode()}")
            print(f"📊 cuML 版本: {cuml.__version__} | Rapids-SingleCell 接入")
        else:
            USE_GPU = False
    except ImportError as e:
        print(f"⚠️ RAPIDS 组件缺失: {e}，回退至 CPU 模式")
        import scanpy as sc  # 降级备用
        USE_GPU = False

# ==========================================
# 阶段 1：读取数据与 GPU 大迁徙
# ==========================================
print("\n[1/5] 💾 读取数据并推送至 GPU...")
t0 = time.time()
adata = ad.read_h5ad(file_path)

if adata.obsm: adata.obsm.clear()
if adata.obsp: adata.obsp.clear()
if 'counts' in adata.layers: del adata.layers['counts'] # 清理历史包袱

if USE_GPU:
    rsc.get.anndata_to_GPU(adata) # 👈 极速迁徙， adata.X 变为 CuPy 稀疏矩阵
    pp = rsc.pp                 # 使用 GPU 预处理引擎
else:
    pp = sc.pp                  # 使用 CPU 预处理引擎

t1 = time.time()
print(f"✅ 数据入显存完毕! 耗时: {t1-t0:.2f} 秒 (原始: {adata.n_obs} x {adata.n_vars})")

# ==========================================
# 阶段 2：极速质控计算
# ==========================================
print("\n[2/5] 📊 GPU 质控指标计算...")
t2 = time.time()

adata.var['mt'] = adata.var_names.str.startswith('MT-')
adata.var['ribo'] = adata.var_names.str.startswith(('RPS', 'RPL'))

# 极速计算 QC
pp.calculate_qc_metrics(adata, qc_vars=['mt', 'ribo'], log1p=False, inplace=True)

t3 = time.time()
print(f"✅ 质控计算完毕! 耗时: {t3-t2:.2f} 秒")

# ==========================================
# 阶段 3：过滤细胞和基因
# ==========================================
print("\n[3/5] 🔧 GPU 极速过滤...")
t4 = time.time()

pp.filter_cells(adata, min_genes=MIN_GENES)
pp.filter_cells(adata, max_genes=MAX_GENES)
# 在 GPU 上直接进行掩码过滤
adata = adata[adata.obs['pct_counts_mt'] < MAX_MT_PCT].copy()
pp.filter_genes(adata, min_cells=MIN_CELLS)

t5 = time.time()
print(f"✅ 过滤完毕! 耗时: {t5-t4:.2f} 秒 (剩余: {adata.n_obs} x {adata.n_vars})")

# ==========================================
# 阶段 4：归一化、高变基因与安全缩放
# ==========================================
print("\n[4/5] 🧬 归一化与安全缩放 (防文件爆炸)...")
t6 = time.time()

adata.layers['counts'] = adata.X.copy() # 备份原始 count
pp.normalize_total(adata, target_sum=1e4)
pp.log1p(adata)

# 使用 seurat flavor，避免 v3 的非整数报错
pp.highly_variable_genes(adata, n_top_genes=N_TOP_GENES, flavor='seurat')
print(f"📊 提取高变基因: {N_TOP_GENES} 个")

# 👈 核心优化点 1：把全局数据冻结在 .raw，从此以后只对 2000 个基因做运算！
adata.raw = adata 
adata = adata[:, adata.var['highly_variable']].copy() 

# 👈 核心优化点 2：zero_center=False 严防稀疏矩阵变成稠密怪兽！
pp.scale(adata, max_value=10, zero_center=False)

t7 = time.time()
print(f"✅ 归一化与缩放完毕! 耗时: {t7-t6:.2f} 秒")

# ==========================================
# 阶段 5：PCA (免拷贝优化)
# ==========================================
print("\n[5/5] 📉 PCA降维...")
t8 = time.time()

n_cells = adata.n_obs

if USE_GPU:
    # 👈 核心优化 3：数据已经在 GPU 上了，直接提取，无需 cp.asarray()！
    gpu_data = adata.X
    
    if n_cells <= MAX_GPU_CELLS:
        print("🚀 直接全量 GPU PCA")
        pca = cuML_PCA(n_components=N_PCS)
        # GPU 稀疏矩阵直接 fit_transform
        pca_result = pca.fit_transform(gpu_data)
        adata.obsm['X_pca'] = cp.asnumpy(pca_result)
        variance_ratio = cp.asnumpy(pca.explained_variance_ratio_)
        
    else:
        print(f"🚀 触发大队列抽样 PCA (显存保护机制)")
        # 显存友好的抽样方案
        cp.random.seed(42)
        sample_idx = cp.random.choice(n_cells, MAX_GPU_CELLS, replace=False)
        gpu_sample = gpu_data[sample_idx]
        
        pca = cuML_PCA(n_components=N_PCS)
        pca.fit(gpu_sample)
        
        # 分批 Transform 保护显存
        batch_size = 100000
        n_batches = (n_cells + batch_size - 1) // batch_size
        pca_results = []
        for i in range(n_batches):
            start, end = i * batch_size, min((i + 1) * batch_size, n_cells)
            batch_result = pca.transform(gpu_data[start:end])
            pca_results.append(cp.asnumpy(batch_result))
            
        adata.obsm['X_pca'] = np.vstack(pca_results)
        variance_ratio = cp.asnumpy(pca.explained_variance_ratio_)
    
    # 算完 PCA，把数据从 GPU 抽回 CPU
    rsc.get.GPU_to_anndata(adata)
    cp.get_default_memory_pool().free_all_blocks()

else:
    sc.tl.pca(adata, n_comps=N_PCS, svd_solver='arpack')
    variance_ratio = adata.uns['pca']['variance_ratio']

# 保存方差
adata.uns['pca'] = {'variance_ratio': variance_ratio}
print(f"✅ PCA 完毕! 耗时: {time.time()-t8:.2f} 秒 (前10 PC 解释方差: {variance_ratio[:10].sum():.2%})")

# ==========================================
# 保存结果与收尾
# ==========================================
print("\n" + "="*60)
print("💾 清理垃圾并保存结果...")

# 👈 核心优化 4：强行转回 CSR 稀疏格式，把文件体积压到极致
if sp.issparse(adata.X) and not sp.isspmatrix_csr(adata.X):
    adata.X = sp.csr_matrix(adata.X)

adata.write_h5ad(output_path)
file_size = os.path.getsize(output_path) / (1024**3)

print(f"✅ 已保存至: {output_path}")
print(f"📊 最终文件大小: {file_size:.2f} GB (不再是 200GB 的怪物啦！)")
print("="*60)
print(f"🎉 终极加速完成！全流程总耗时: {time.time()-t0:.2f} 秒")
print("="*60)