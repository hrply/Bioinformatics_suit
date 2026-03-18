import rmm
import cupy as cp
import numpy as np
import scanpy as sc
import rapids_singlecell as rsc
from rmm.allocators.cupy import rmm_cupy_allocator
import os

def initialize_gpu_environment():
    """
    初始化 RAPIDS 显存管理器 (RMM)
    """
    print("🚀 正在初始化 GPU 优化环境...")
    
    # 1. 配置 RMM
    # pool_allocator: 预分配显存池，避免频繁申请导致的碎片
    # managed_memory: 允许显存不足时自动溢出到系统内存 (性能会下降但不会 OOM)
    rmm.reinitialize(
        pool_allocator=True,
        managed_memory=True, 
        initial_pool_size=None, # 设为 None 则按需动态增加池大小
    )
    
    # 2. 将 CuPy 的分配器指向 RMM
    cp.cuda.set_allocator(rmm_cupy_allocator)
    print("✅ RMM 池化与统一内存已激活。")

def sc_gpu_pipeline_demo():
    # 模拟数据规模 (此处仅为示例，20M 细胞建议从硬盘读取 h5ad/parquet)
    n_cells = 100000 
    n_genes = 2000
    
    print(f"📊 模拟处理规模: {n_cells} 细胞 x {n_genes} 基因")
    
    # 3. 创建数据 (确保使用 float32 节省一半显存)
    X = cp.random.negative_binomial(20, 0.3, size=(n_cells, n_genes)).astype(cp.float32)
    adata = sc.AnnData(X.get()) # 模拟从内存加载
    del X # 及时释放临时大对象
    
    # 4. 将数据搬运至 GPU
    # 使用 rapids-singlecell (rsc) 替代 scanpy (sc)
    rsc.get.anndata_to_GPU(adata)
    print(f"🧬 数据已迁移至 GPU，当前显存占用估计: {adata.X.nbytes / 1024**2:.2f} MB")

    # 5. 标准预处理流程 (GPU 加速版)
    print("🧪 正在执行标准化...")
    rsc.pp.normalize_total(adata, target_sum=1e4)
    rsc.pp.log1p(adata)
    
    print("🔍 正在计算高变基因 (HVG)...")
    rsc.pp.highly_variable_genes(adata, n_top_genes=2000)
    
    print("📉 正在执行 PCA 降维...")
    rsc.tl.pca(adata, n_comps=50)
    
    print("🌐 正在构建邻面图 (Neighbors)...")
    rsc.pp.neighbors(adata, n_neighbors=15, n_pcs=50)
    
    print("🎨 正在运行 UMAP...")
    rsc.tl.umap(adata)
    
    print("🏁 流程测试完成！")
    print(f"UMAP 结果坐标样例: \n{adata.obsm['X_umap'][:5]}")

    # 6. 保存结果前的处理
    # 记得在保存前把数据转回 CPU，否则标准 scanpy 可能无法读取
    # rsc.get.anndata_to_CPU(adata)
    # adata.write("/data/result.h5ad")

if __name__ == "__main__":
    try:
        initialize_gpu_environment()
        sc_gpu_pipeline_demo()
    except Exception as e:
        print(f"❌ 运行出错: {e}")
    finally:
        # 强制清理显存
        cp.get_default_memory_pool().free_all_blocks()
        print("🧹 显存已释放。")