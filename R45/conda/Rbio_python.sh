#!/bin/bash
# =============================================================================
# Rbio_python.sh - GPU加速python生信分析平台配置
# =============================================================================
# 核心逻辑：
# 1. 统一由 Mamba 管理 CUDA 13.x 和核心框架 (PyTorch/RAPIDS/CuPy)。
# 2. 避免在同一环境内混合使用不同渠道的底层库。
# 3. 自动配置环境激活脚本，确保 CUDA_HOME 永远指向 Conda 内部。
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# 1. 初始化与配置
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Rbio_common.sh"

# 初始化命令行参数 (确保 CONDA_ENV_NAME 已定义)
rbio_init "$@"

log_stage "[Stage GPU] 统一构建 CUDA 13 + 核心框架"

# -----------------------------------------------------------------------------
# 2. 核心框架——RAPIDS，推荐Conda渠道安装
# -----------------------------------------------------------------------------
log_info "正在通过 Mamba 一次性解析 PyTorch 与 RAPIDS 依赖..."

# 我们将所有“重量级”包放在一个命令里，让 Solver 寻找最优解
# 这里的顺序和 channel 优先级至关重要
mamba install -y -n "${CONDA_ENV_NAME}" \
    -c rapidsai -c pytorch -c nvidia -c conda-forge \
    python=3.12 \
    "cuda-version>=13.0,<13.2" \
    "pytorch=*=*cuda*" \
    "torchvision=*=*cuda*" \
    "torchaudio=*=*cuda*" \
    rapids=26.02 \
    cupy \
    nx-cugraph \
    cudnn cutensor cusparselt \
    cuda-toolkit \
    r-base=4.5.2 \
    numpy numba \
    --channel-priority flexible

log_info "核心框架安装完成。"

# -----------------------------------------------------------------------------
# 3. 环境变量持久化 (Conda 激活钩子)
# -----------------------------------------------------------------------------
log_info "配置 Conda 内部 CUDA 路径..."

# 这样当你 'conda activate' 时，环境变量会自动设置，无需手动 export
ACTIVATE_DIR="${CONDA_PREFIX}/etc/conda/activate.d"
mkdir -p "${ACTIVATE_DIR}"

cat <<EOF > "${ACTIVATE_DIR}/cuda_paths.sh"
#!/bin/sh
export CUDA_HOME="\${CONDA_PREFIX}"
export PATH="\${CONDA_PREFIX}/bin:\${PATH}"
export LD_LIBRARY_PATH="\${CONDA_PREFIX}/lib:\${LD_LIBRARY_PATH}"
# 强制 JAX 识别 Conda 内部的库
export XLA_FLAGS="--xla_gpu_cuda_data_dir=\${CONDA_PREFIX}"
EOF

# -----------------------------------------------------------------------------
# 4. 生成安装约束 (Protection Layer)
# -----------------------------------------------------------------------------
log_info "生成 GPU 约束文件以防止 Pip 破坏环境..."

# 锁定已经由 Conda 安装好的核心库版本
pip freeze | grep -Ei "^(torch|nvidia|rapids|cudf|cupy|numpy|numba|jax)" \
    | sed 's/ @ file:\/\/.*//g' > "${SCRIPT_DIR}/gpu_constraints.txt"

# -----------------------------------------------------------------------------
# 5. 安装生信应用包 (Pip Layer)
# -----------------------------------------------------------------------------
log_info "安装rpy2和相关包，由于需要和R环境对接，pip安装容易出错"

mamba install -y -c conda-forge -c bioconda \
    rpy2 anndata2ri zlib

log_info "安装生物信息学应用包与 JAX..."

pip install --no-cache-dir -c "${SCRIPT_DIR}/gpu_constraints.txt" \
    "jax[cuda13]" \
    scipy matplotlib seaborn pandas h5py pyarrow \
    scikit-learn scikit-image \
    cellbender pertpy pydeseq2 scrublet \
    "scanpy>=1.12" "scvi-tools>=1.4.2" scvelo \
    squidpy gseapy decoupler \
    torch-geometric umap-learn \
    rapids-singlecell-cu13 \
    shapely flowio PhenoGraph pybiomart \
    python-igraph leidenalg phate bokeh holoviews \
    torch-geometric umap-learn pynndescent \
    scikit-network scikit-misc scikit-survival statsmodels \
    harmonypy bbknn scirpy cellrank liana \
    FlowKit muon snapatac2 \
    statannotations pingouin PyCytoData \
    cellphonedb diffxpy ktplotspy \
    muon snapatac2 pingouin tables zarr louvain anndata h5py

log_info "应用包安装完成。"

# -----------------------------------------------------------------------------
# 6. 验证安装
# -----------------------------------------------------------------------------
log_info "执行 GPU 全栈验证..."

python -c "
import torch, cudf, cupy, jax
import torch.utils.dlpack

print(f'--- 验证报告 ---')
print(f'PyTorch: {torch.__version__} | CUDA Available: {torch.cuda.is_available()}')
print(f'cuDF:    {cudf.__version__}')
print(f'CuPy:    {cupy.__version__}')
print(f'JAX:     {jax.__version__} | Devices: {jax.devices()}')

# 核心测试：共享内存零拷贝 (DLPack)
try:
    df = cudf.Series([1, 2, 3])
    t = torch.utils.dlpack.from_dlpack(df.to_dlpack())
    print('DLPack 内存共享测试: 成功')
except Exception as e:
    print(f'DLPack 内存共享测试: 失败 ({e})')
" || log_warn "验证过程中发现潜在兼容性问题，请检查日志。"

log_info "Rbio_python.sh 执行完毕！环境已准备就绪。"