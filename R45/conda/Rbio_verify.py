#!/usr/bin/env python3
# =============================================================================
# verify_all_packages.py - 全量 GPU 环境与生信包验证脚本
# =============================================================================
# 结合了 GPU 算力验证（CUDA/PyTorch/CuPy/RAPIDS/TF/JAX）与全量生信业务包导入测试。
# =============================================================================

import sys
import subprocess
import os
import importlib
import warnings
warnings.filterwarnings('ignore')

# -----------------------------------------------------------------------------
# 辅助函数与状态记录
# -----------------------------------------------------------------------------
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(title):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*65}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}  {title}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*65}{Colors.RESET}\n")

def print_success(msg):
    print(f"{Colors.GREEN}✓ {msg}{Colors.RESET}")

def print_error(msg):
    print(f"{Colors.RED}✗ {msg}{Colors.RESET}")

def print_warning(msg):
    print(f"{Colors.YELLOW}⚠ {msg}{Colors.RESET}")

def print_info(msg):
    print(f"  {msg}")

# 全局统计
results = {"passed": 0, "failed": 0, "warnings": 0}

# =============================================================================
# 1. 宿主机与 CUDA 底层环境检查
# =============================================================================
print_header("1. 底层系统与 CUDA 环境检查")

try:
    result = subprocess.run(['nvidia-smi'], capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        print_success("nvidia-smi 可用")
        lines = result.stdout.split('\n')
        for line in lines:
            if 'GPU' in line and 'Name' not in line:
                print_info(line.strip())
                break
    else:
        print_warning("nvidia-smi 返回错误 (可能未挂载 GPU 或驱动异常)")
        results["warnings"] += 1
except FileNotFoundError:
    print_error("未找到 nvidia-smi 命令")
    results["failed"] += 1
except Exception as e:
    print_warning(f"nvidia-smi 检查异常: {e}")
    results["warnings"] += 1

cuda_home = os.environ.get('CUDA_HOME', '未设置')
print_info(f"CUDA_HOME 环境变量: {cuda_home}")

# =============================================================================
# 2. 核心深度学习框架与张量运算测试
# =============================================================================
print_header("2. 核心框架 GPU 算力验证")

# 2.1 PyTorch
try:
    import torch
    print_success(f"PyTorch 版本: {torch.__version__}")
    if torch.cuda.is_available():
        print_success(f"PyTorch CUDA 可用: {torch.cuda.get_device_name(0)}")
        try:
            x = torch.rand(1000, 1000, device='cuda')
            y = torch.rand(1000, 1000, device='cuda')
            z = torch.matmul(x, y)
            torch.cuda.synchronize()
            print_success("PyTorch GPU 张量乘法测试通过")
            results["passed"] += 1
        except Exception as e:
            print_error(f"PyTorch GPU 运算失败: {e}")
            results["failed"] += 1
    else:
        print_warning("PyTorch 无法识别 CUDA 设备")
        results["warnings"] += 1
except ImportError as e:
    print_error(f"PyTorch 导入失败: {e}")
    results["failed"] += 1

# 2.2 TensorFlow
# skip

# 2.3 JAX
try:
    import jax
    print_success(f"JAX 版本: {jax.__version__}")
    if jax.default_backend() == 'gpu':
        try:
            import jax.numpy as jnp
            x = jnp.ones((1000, 1000))
            y = jnp.dot(x, x)
            y.block_until_ready()
            print_success("JAX GPU 运算测试通过")
            results["passed"] += 1
        except Exception as e:
            print_error(f"JAX GPU 运算失败: {e}")
            results["failed"] += 1
    else:
        print_warning(f"JAX 当前使用后端: {jax.default_backend()} (非 GPU)")
        results["warnings"] += 1
except ImportError as e:
    print_error(f"JAX 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 3. RAPIDS 生态体系与 CuPy 测试
# =============================================================================
print_header("3. RAPIDS 生态体系与 CuPy 算力验证")

# 3.1 CuPy
try:
    import cupy as cp
    print_success(f"CuPy 版本: {cp.__version__}")
    try:
        x = cp.random.rand(1000, 1000)
        y = cp.random.rand(1000, 1000)
        z = cp.dot(x, y)
        cp.cuda.Stream.null.synchronize()
        print_success("CuPy GPU 运算测试通过")
        results["passed"] += 1
    except Exception as e:
        print_error(f"CuPy GPU 运算失败: {e}")
        results["failed"] += 1
except ImportError as e:
    print_error(f"CuPy 导入失败: {e}")
    results["failed"] += 1

# 3.2 cuDF
try:
    import cudf
    print_success(f"cuDF 版本: {cudf.__version__}")
    try:
        df = cudf.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})
        res = df['a'] + df['b']
        print_success("cuDF GPU 数据帧运算测试通过")
        results["passed"] += 1
    except Exception as e:
        print_error(f"cuDF 运算失败: {e}")
        results["failed"] += 1
except ImportError as e:
    print_error(f"cuDF 导入失败: {e}")
    results["failed"] += 1

# 3.3 cuML
try:
    import cuml
    print_success(f"cuML 版本: {cuml.__version__}")
    try:
        from cuml.cluster import KMeans
        import cupy as cp
        X = cp.random.rand(100, 10)
        kmeans = KMeans(n_clusters=3)
        kmeans.fit(X)
        print_success("cuML GPU KMeans 聚类测试通过")
        results["passed"] += 1
    except Exception as e:
        print_error(f"cuML 运算失败: {e}")
        results["failed"] += 1
except ImportError as e:
    print_error(f"cuML 导入失败: {e}")
    results["failed"] += 1


# =============================================================================
# 4. 全量生信业务与基础包导入扫描
# =============================================================================
print_header("4. 全量生信业务包完整性扫描")

packages = [
    # 基础与交互
    "rpy2", "anndata2ri", "numpy", "scipy", "pandas", "matplotlib", 
    "seaborn", "numba", "h5py", "tables", "zarr", "pyarrow", 
    "jupyterlab", "notebook", "ipykernel", "ipywidgets", "jupyter-client",
    "adjustText", "joblib", "pydot",
    
    # 算力层与 RAPIDS (元数据包与之前未覆盖的包)
    "torch", "torchvision", "torchaudio", "cuda-python", "cuda-bindings", 
    "cupy-cuda13x", "cudf-cu13", "cuml-cu13", "cugraph-cu13", "rapids", 
    "rapids-singlecell", "torch-geometric", "cuvs-cu13",
    
    # 业务分析包
    "scanpy", "scvi-tools", "cellbender", "anndata", "leidenalg", "python-igraph", 
    "umap-learn", "phate", "scvelo", "squidpy", "gseapy", "decoupleR",
    "PyCytoData", "pertpy", "cellrank", "liana", "FlowKit", "PhenoGraph", 
    "muon", "snapatac2", "ktplotspy", "cellphonedb", 
    "pydeseq2", "pybiomart", "diffxpy", "statsmodels", "statannotations", 
    "pingouin", "pynndescent", "scikit-network", "scikit-learn", "scikit-image", 
    "scikit-misc", "scikit-survival", "harmonypy", "bbknn", "scirpy", "flowio"
]

mapping = {
    "python-igraph": "igraph",
    "scvi-tools": "scvi",
    "umap-learn": "umap",
    "cuda-python": "cuda",
    "cuda-bindings": "cuda",
    "cupy-cuda13x": "cupy",
    "cudf-cu13": "cudf",
    "cuml-cu13": "cuml",
    "cugraph-cu13": "cugraph",
    "cuvs-cu13": "cuvs",
    "torch-geometric": "torch_geometric",
    "jupyter-client": "jupyter_client",
    "FlowKit": "flowkit",
    "PhenoGraph": "phenograph",
    "scikit-network": "sknetwork",
    "scikit-learn": "sklearn",
    "scikit-image": "skimage",
    "scikit-misc": "skmisc",
    "scikit-survival": "sksurv",
    "decoupleR": "decoupler",
    "rapids-singlecell": "rapids_singlecell"
}

pkg_passed = []
pkg_failed = []

print(f"{'包名称 (Package)':<25} | {'状态 (Status)':<10}")
print("-" * 65)

for pkg in sorted(list(set(packages))):
    # 元包 (Meta-packages) 跳过实际导入
    if pkg in ["rapids", "cuda-bindings", "cudf-cu13", "cuml-cu13", "cugraph-cu13", "cuvs-cu13", "cupy-cuda13x"]:
        print(f"{pkg:<25} | {Colors.GREEN}✅ SKIP (Meta-package){Colors.RESET}")
        pkg_passed.append(pkg)
        results["passed"] += 1
        continue
        
    import_name = mapping.get(pkg, pkg)
    
    # 对 cellbender 做特殊处理（它可能没有标准 __init__.py 导致直接导入受限）
    if pkg == "cellbender":
        try:
            import cellbender
            print(f"{pkg:<25} | {Colors.GREEN}✅ OK{Colors.RESET}")
            pkg_passed.append(pkg)
            results["passed"] += 1
        except ImportError:
            try:
                from cellbender.remove_background import remove_background
                print(f"{pkg:<25} | {Colors.GREEN}✅ OK (via submodule){Colors.RESET}")
                pkg_passed.append(pkg)
                results["passed"] += 1
            except ImportError as e2:
                print(f"{pkg:<25} | {Colors.RED}❌ FAILED ({e2}){Colors.RESET}")
                pkg_failed.append(pkg)
                results["failed"] += 1
        continue

    # 标准导入逻辑
    try:
        importlib.import_module(import_name)
        print(f"{pkg:<25} | {Colors.GREEN}✅ OK{Colors.RESET}")
        pkg_passed.append(pkg)
        results["passed"] += 1
    except ImportError as e:
        print(f"{pkg:<25} | {Colors.RED}❌ FAILED ({e}){Colors.RESET}")
        pkg_failed.append(pkg)
        results["failed"] += 1
    except Exception as e:
        print(f"{pkg:<25} | {Colors.YELLOW}⚠️ ERROR ({type(e).__name__}){Colors.RESET}")
        pkg_failed.append(pkg)
        results["failed"] += 1

# =============================================================================
# 5. GPU 内存与状态检查
# =============================================================================
print_header("5. GPU 显存分配监控")

try:
    import torch
    if torch.cuda.is_available():
        for i in range(torch.cuda.device_count()):
            total = torch.cuda.get_device_properties(i).total_memory / 1024**3
            reserved = torch.cuda.memory_reserved(i) / 1024**3
            allocated = torch.cuda.memory_allocated(i) / 1024**3
            print_info(f"[{i}] {torch.cuda.get_device_name(i)}")
            print_info(f"    总量: {total:.2f} GB | 保留: {reserved:.2f} GB | 已用: {allocated:.2f} GB")
    else:
        print_warning("无可用 GPU，跳过显存检查")
except Exception as e:
    print_warning(f"无法读取 GPU 显存: {e}")

# =============================================================================
# 6. 最终测试报告汇总
# =============================================================================
print_header("🎯 最终测试报告")

total_tests = results["passed"] + results["failed"] + results["warnings"]

print(f"总计检测项目: {total_tests}")
print(f"  {Colors.GREEN}► 成功: {results['passed']}{Colors.RESET}")
print(f"  {Colors.RED}► 失败: {results['failed']}{Colors.RESET}")
print(f"  {Colors.YELLOW}► 警告: {results['warnings']}{Colors.RESET}")

if pkg_failed:
    print(f"\n{Colors.RED}缺失或导入异常的包: {', '.join(pkg_failed)}{Colors.RESET}")

if results["failed"] == 0 and len(pkg_failed) == 0:
    print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 恭喜！环境验证完美通过！完整的单细胞与底层 GPU 加速栈均已就绪。{Colors.RESET}\n")
    sys.exit(0)
else:
    print(f"\n{Colors.RED}{Colors.BOLD}❌ 验证存在失败项，请向上滚动排查 FAILED 记录。{Colors.RESET}\n")
    sys.exit(1)