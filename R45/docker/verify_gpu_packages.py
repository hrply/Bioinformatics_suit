#!/usr/bin/env python3
# =============================================================================
# verify_gpu_packages.py - GPU 环境验证脚本
# =============================================================================
# 测试 Rbio_cuda.dockerfile 中安装的所有 GPU 相关 Python 包
#
# 使用方法:
#   # 在容器内运行
#   python3 /path/to/verify_gpu_packages.py
#
#   # 或通过 docker run
#   docker run --gpus all r-bio:gpu python3 /path/to/verify_gpu_packages.py
# =============================================================================

import sys
import subprocess
import warnings
warnings.filterwarnings('ignore')

# 颜色输出
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(title):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}  {title}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}\n")

def print_success(msg):
    print(f"{Colors.GREEN}✓ {msg}{Colors.RESET}")

def print_error(msg):
    print(f"{Colors.RED}✗ {msg}{Colors.RESET}")

def print_warning(msg):
    print(f"{Colors.YELLOW}⚠ {msg}{Colors.RESET}")

def print_info(msg):
    print(f"  {msg}")

# 统计结果
results = {"passed": 0, "failed": 0, "warnings": 0}

def test_result(name, success, details=""):
    if success:
        print_success(f"{name}")
        results["passed"] += 1
    else:
        print_error(f"{name}")
        results["failed"] += 1
    if details:
        print_info(details)

# =============================================================================
# 1. CUDA 环境检查
# =============================================================================
print_header("1. CUDA 环境检查")

# 检查 nvidia-smi
try:
    result = subprocess.run(['nvidia-smi'], capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        print_success("nvidia-smi 可用")
        # 提取 GPU 信息
        lines = result.stdout.split('\n')
        for line in lines:
            if 'GPU' in line and 'Name' not in line:
                print_info(line.strip())
                break
    else:
        print_warning("nvidia-smi 返回错误 (可能无 GPU 设备)")
        results["warnings"] += 1
except FileNotFoundError:
    print_error("nvidia-smi 未找到")
    results["failed"] += 1
except Exception as e:
    print_warning(f"nvidia-smi 检查失败: {e}")
    results["warnings"] += 1

# 检查 CUDA 环境变量
import os
cuda_home = os.environ.get('CUDA_HOME', '/usr/local/cuda-12.4')
cuda_path = os.environ.get('PATH', '')
ld_library_path = os.environ.get('LD_LIBRARY_PATH', '')

print_info(f"CUDA_HOME: {cuda_home}")
print_info(f"CUDA in PATH: {'/usr/local/cuda' in cuda_path or 'cuda-12' in cuda_path}")
print_info(f"LD_LIBRARY_PATH: {ld_library_path[:80]}..." if len(ld_library_path) > 80 else f"LD_LIBRARY_PATH: {ld_library_path}")

# 检查 nvcc
try:
    result = subprocess.run(['nvcc', '--version'], capture_output=True, text=True, timeout=5)
    if result.returncode == 0:
        version_line = [l for l in result.stdout.split('\n') if 'release' in l]
        print_success(f"nvcc 可用: {version_line[0].strip() if version_line else 'unknown'}")
    else:
        print_warning("nvcc 返回错误")
except FileNotFoundError:
    print_warning("nvcc 未找到 (可能仅运行时环境)")
except Exception as e:
    print_warning(f"nvcc 检查失败: {e}")

# =============================================================================
# 2. PyTorch 测试
# =============================================================================
print_header("2. PyTorch 测试")

try:
    import torch
    print_success(f"PyTorch 版本: {torch.__version__}")
    
    # CUDA 可用性
    cuda_available = torch.cuda.is_available()
    if cuda_available:
        print_success(f"CUDA 可用: {torch.cuda.get_device_name(0)}")
        print_info(f"CUDA 版本: {torch.version.cuda}")
        print_info(f"GPU 数量: {torch.cuda.device_count()}")
        
        # 简单张量运算测试
        try:
            x = torch.rand(1000, 1000, device='cuda')
            y = torch.rand(1000, 1000, device='cuda')
            z = torch.matmul(x, y)
            torch.cuda.synchronize()
            print_success("GPU 张量运算测试通过")
        except Exception as e:
            print_error(f"GPU 张量运算测试失败: {e}")
    else:
        print_warning("CUDA 不可用 (可能无 GPU 设备或驱动问题)")
        results["warnings"] += 1
        
except ImportError as e:
    print_error(f"PyTorch 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 3. JAX 测试
# =============================================================================
print_header("3. JAX 测试")

try:
    import jax
    print_success(f"JAX 版本: {jax.__version__}")
    
    # 检查后端
    backend = jax.default_backend()
    print_info(f"默认后端: {backend}")
    
    if backend == 'gpu':
        print_success("JAX 使用 GPU 后端")
        try:
            import jax.numpy as jnp
            x = jnp.ones((1000, 1000))
            y = jnp.dot(x, x)
            y.block_until_ready()
            print_success("JAX GPU 运算测试通过")
        except Exception as e:
            print_error(f"JAX GPU 运算测试失败: {e}")
    else:
        print_warning(f"JAX 使用 {backend} 后端 (非 GPU)")
        results["warnings"] += 1
        
except ImportError as e:
    print_error(f"JAX 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 4. TensorFlow 测试
# =============================================================================
print_header("4. TensorFlow 测试")

try:
    import tensorflow as tf
    print_success(f"TensorFlow 版本: {tf.__version__}")
    
    # GPU 设备
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        print_success(f"检测到 {len(gpus)} 个 GPU")
        for gpu in gpus:
            print_info(f"  {gpu}")
    else:
        print_warning("未检测到 GPU 设备")
        results["warnings"] += 1
    
    # 简单运算测试
    try:
        with tf.device('/GPU:0' if gpus else '/CPU:0'):
            a = tf.random.normal([1000, 1000])
            b = tf.random.normal([1000, 1000])
            c = tf.matmul(a, b)
        print_success("TensorFlow 运算测试通过")
    except Exception as e:
        print_error(f"TensorFlow 运算测试失败: {e}")
        
except ImportError as e:
    print_error(f"TensorFlow 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 5. CuPy 测试
# =============================================================================
print_header("5. CuPy 测试")

try:
    import cupy as cp
    print_success(f"CuPy 版本: {cp.__version__}")
    
    # CUDA 运行时版本
    print_info(f"CUDA 运行时版本: {cp.cuda.runtime.runtimeGetVersion()}")
    
    # GPU 运算测试
    try:
        x = cp.random.rand(1000, 1000)
        y = cp.random.rand(1000, 1000)
        z = cp.dot(x, y)
        cp.cuda.Stream.null.synchronize()
        print_success("CuPy GPU 运算测试通过")
    except Exception as e:
        print_error(f"CuPy GPU 运算测试失败: {e}")
        
except ImportError as e:
    print_error(f"CuPy 导入失败: {e}")
    results["failed"] += 1
except Exception as e:
    print_warning(f"CuPy 初始化失败 (可能无 GPU): {e}")
    results["warnings"] += 1

# =============================================================================
# 6. RAPIDS 测试
# =============================================================================
print_header("6. RAPIDS 测试")

# cuDF
try:
    import cudf
    print_success(f"cuDF 版本: {cudf.__version__}")
    
    try:
        df = cudf.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})
        result = df['a'] + df['b']
        print_success("cuDF 运算测试通过")
    except Exception as e:
        print_error(f"cuDF 运算测试失败: {e}")
        
except ImportError as e:
    print_error(f"cuDF 导入失败: {e}")
    results["failed"] += 1
except Exception as e:
    print_warning(f"cuDF 初始化失败 (可能无 GPU): {e}")
    results["warnings"] += 1

# cuML
try:
    import cuml
    print_success(f"cuML 版本: {cuml.__version__}")
    
    try:
        from cuml.cluster import KMeans
        import cupy as cp
        X = cp.random.rand(100, 10)
        kmeans = KMeans(n_clusters=3)
        kmeans.fit(X)
        print_success("cuML KMeans 测试通过")
    except Exception as e:
        print_error(f"cuML 运算测试失败: {e}")
        
except ImportError as e:
    print_error(f"cuML 导入失败: {e}")
    results["failed"] += 1
except Exception as e:
    print_warning(f"cuML 初始化失败 (可能无 GPU): {e}")
    results["warnings"] += 1

# rapids-singlecell
try:
    import rapids_singlecell as rsc
    print_success(f"rapids-singlecell 版本: {rsc.__version__}")
except ImportError as e:
    print_error(f"rapids-singlecell 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 7. 单细胞分析包测试
# =============================================================================
print_header("7. 单细胞分析包测试")

# scvi-tools
try:
    import scvi
    print_success(f"scvi-tools 版本: {scvi.__version__}")
except ImportError as e:
    print_error(f"scvi-tools 导入失败: {e}")
    results["failed"] += 1

# cellbender
try:
    import cellbender
    print_success(f"cellbender 版本: {cellbender.__version__}")
except ImportError as e:
    # cellbender 可能没有 __version__
    try:
        from cellbender.remove_background import remove_background
        print_success("cellbender 导入成功")
    except ImportError as e2:
        print_error(f"cellbender 导入失败: {e2}")
        results["failed"] += 1

# scanpy (基础包)
try:
    import scanpy as sc
    print_success(f"scanpy 版本: {sc.__version__}")
except ImportError as e:
    print_error(f"scanpy 导入失败: {e}")
    results["failed"] += 1

# anndata
try:
    import anndata
    print_success(f"anndata 版本: {anndata.__version__}")
except ImportError as e:
    print_error(f"anndata 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 8. PyTorch Geometric 测试
# =============================================================================
print_header("8. PyTorch Geometric 测试")

try:
    import torch_geometric
    print_success(f"PyTorch Geometric 版本: {torch_geometric.__version__}")
    
    # 基础导入测试
    try:
        from torch_geometric.nn import GCNConv
        from torch_geometric.data import Data
        print_success("PyTorch Geometric 核心模块导入成功")
    except Exception as e:
        print_error(f"PyTorch Geometric 模块导入失败: {e}")
        
except ImportError as e:
    print_error(f"PyTorch Geometric 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 9. 其他 GPU 相关包
# =============================================================================
print_header("9. 其他 GPU 相关包")

# numba (CUDA JIT)
try:
    from numba import cuda
    print_success("numba.cuda 导入成功")
    
    if cuda.is_available():
        print_success("numba CUDA 可用")
    else:
        print_warning("numba CUDA 不可用")
        results["warnings"] += 1
except ImportError as e:
    print_error(f"numba.cuda 导入失败: {e}")
    results["failed"] += 1

# =============================================================================
# 10. 内存和设备信息
# =============================================================================
print_header("10. GPU 内存信息")

try:
    import torch
    if torch.cuda.is_available():
        for i in range(torch.cuda.device_count()):
            total = torch.cuda.get_device_properties(i).total_memory / 1024**3
            reserved = torch.cuda.memory_reserved(i) / 1024**3
            allocated = torch.cuda.memory_allocated(i) / 1024**3
            print_info(f"GPU {i}: {torch.cuda.get_device_name(i)}")
            print_info(f"  总显存: {total:.2f} GB")
            print_info(f"  已保留: {reserved:.2f} GB")
            print_info(f"  已分配: {allocated:.2f} GB")
    else:
        print_warning("无可用 GPU 设备")
except Exception as e:
    print_warning(f"无法获取 GPU 内存信息: {e}")

# =============================================================================
# 总结
# =============================================================================
print_header("测试总结")

total = results["passed"] + results["failed"] + results["warnings"]
print(f"总计: {total} 项测试")
print(f"{Colors.GREEN}通过: {results['passed']}{Colors.RESET}")
print(f"{Colors.RED}失败: {results['failed']}{Colors.RESET}")
print(f"{Colors.YELLOW}警告: {results['warnings']}{Colors.RESET}")

if results["failed"] == 0:
    print(f"\n{Colors.GREEN}{Colors.BOLD}✓ 所有核心测试通过！{Colors.RESET}")
    sys.exit(0)
else:
    print(f"\n{Colors.RED}{Colors.BOLD}✗ 存在失败的测试{Colors.RESET}")
    sys.exit(1)