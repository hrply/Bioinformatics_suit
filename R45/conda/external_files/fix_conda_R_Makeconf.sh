#!/bin/bash
# =============================================================================
# configure_r_compilers.sh - The Ultimate Full-Stack Makeconf Patcher (Fixed)
# =============================================================================
set -e

log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

CONDA_PREFIX=${CONDA_PREFIX:-$(conda info --base)}
R_HOME="${CONDA_PREFIX}/lib/R"
MAKECONF="${R_HOME}/etc/Makeconf"

[ ! -f "${MAKECONF}" ] && { echo "Makeconf not found!"; exit 1; }

# =============================================================================
# 1. 自动嗅探 Conda 环境下的所有底层编译工具链
# =============================================================================
CC=$(ls ${CONDA_PREFIX}/bin/*-conda-linux-gnu-cc | head -n 1)
CXX=$(ls ${CONDA_PREFIX}/bin/*-conda-linux-gnu-c++ | head -n 1)
FC=$(ls ${CONDA_PREFIX}/bin/*-conda-linux-gnu-gfortran | head -n 1)
AR=$(ls ${CONDA_PREFIX}/bin/*-conda-linux-gnu-ar | head -n 1)
RANLIB=$(ls ${CONDA_PREFIX}/bin/*-conda-linux-gnu-ranlib | head -n 1)
NM=$(ls ${CONDA_PREFIX}/bin/*-conda-linux-gnu-nm | head -n 1)

# Objective-C/C++ 通常复用 C/C++ 编译器
OBJC=${CC}
OBJCXX=${CXX}

log_info "Detected Toolchain:"
echo "  CC:      ${CC}"
echo "  CXX:     ${CXX}"
echo "  FC:      ${FC}"
echo "  AR:      ${AR}"
echo "  RANLIB:  ${RANLIB}"

# =============================================================================
# 2. 备份（安全第一）
# =============================================================================
BACKUP="${MAKECONF}.bak.full.$(date +%Y%m%d%H%M%S)"
cp "${MAKECONF}" "${BACKUP}"
log_info "Makeconf backed up to ${BACKUP}"

# =============================================================================
# 3. 增强版替换函数
# =============================================================================
update_makeconf_var() {
    local var_name="$1"
    local var_value="$2"
    if grep -E -q "^${var_name}[[:space:]]*=" "${MAKECONF}"; then
        sed -i -E "s|^${var_name}[[:space:]]*=.*|${var_name} = ${var_value}|" "${MAKECONF}"
    else
        echo "${var_name} = ${var_value}" >> "${MAKECONF}"
    fi
}

log_info "Extracting raw physical flags to prevent Makefile recursion..."

# 【核心修复点】：直接提取纯文本字符串（物理真值），剥离变量引用！
RAW_CFLAGS=$(grep -E "^CFLAGS[[:space:]]*=" "${MAKECONF}" | head -n 1 | sed -E 's/^CFLAGS[[:space:]]*=[[:space:]]*//')
RAW_CXXFLAGS=$(grep -E "^CXXFLAGS[[:space:]]*=" "${MAKECONF}" | head -n 1 | sed -E 's/^CXXFLAGS[[:space:]]*=[[:space:]]*//')

log_info "Patching Makeconf for ALL languages and standards..."

# =============================================================================
# 4. 修复基础工具链 & 基础语言
# =============================================================================
update_makeconf_var "AR" "${AR}"
update_makeconf_var "RANLIB" "${RANLIB}"
update_makeconf_var "NM" "${NM}"

update_makeconf_var "CC" "${CC}"
update_makeconf_var "CXX" "${CXX} -std=gnu++17"
update_makeconf_var "FC" "${FC}"
update_makeconf_var "F77" "${FC}"
update_makeconf_var "OBJC" "${OBJC}"
update_makeconf_var "OBJCXX" "${OBJCXX}"

# 确保 Fortran 链接库存在 (生信数学库核心)
update_makeconf_var "FLIBS" "-lgfortran -lm -lquadmath"

# =============================================================================
# 5. 修复所有 C 语言标准 (填补 CC23 等空白)
# =============================================================================
for std in 17 23 90 99; do
    update_makeconf_var "CC${std}" "${CC} -std=gnu${std}"
    
    # 注入物理纯文本！打破循环！
    update_makeconf_var "C${std}FLAGS" "${RAW_CFLAGS}"
done

# =============================================================================
# 6. 修复所有 C++ 语言标准 (彻底终结 arrow 编译错误)
# =============================================================================
for std in 11 14 17 20 23 26; do
    update_makeconf_var "CXX${std}" "${CXX}"
    update_makeconf_var "CXX${std}STD" "-std=gnu++${std}"
    update_makeconf_var "CXX${std}PICFLAGS" "-fPIC"
    
    # 注入物理纯文本！打破循环！
    update_makeconf_var "CXX${std}FLAGS" "${RAW_CXXFLAGS}"
    
    # 修复共享库动态链接器 (解决 .so 文件生成失败)
    update_makeconf_var "SHLIB_CXX${std}LD" "\$(CXX${std}) \$(CXX${std}STD)"
    update_makeconf_var "SHLIB_CXX${std}LDFLAGS" "-shared"
done

# =============================================================================
# 7. 修复 Fortran 等其他动态链接器
# =============================================================================
update_makeconf_var "SHLIB_FCLD" "\$(FC)"
update_makeconf_var "SHLIB_FCLDFLAGS" "-shared"
update_makeconf_var "SHLIB_LD" "\$(CC)"
update_makeconf_var "SHLIB_LDFLAGS" "-shared"


log_info "Makeconf successfully and completely patched WITHOUT recursive traps!"
log_info "You can now securely compile any R package (C/C++/Fortran/ObjC)."