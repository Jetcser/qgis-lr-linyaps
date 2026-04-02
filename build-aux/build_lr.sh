#!/bin/bash

# --- 0. 错误处理配置 ---
# set -e: 任何命令执行失败（返回非0）则立即退出脚本
# set -o pipefail: 管道命令中只要有一个子命令失败，整个管道就视为失败
set -e
set -o pipefail

QGIS_BRANCH="lr"
mkdir -p "/project/logs"

# --- 1. 路径与变量定义 ---
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
DIR_SOURCES="/project/linglong/sources"
DIR_AUX="/project/build-aux"
DIR_CACHE="/project/build_cache_${QGIS_BRANCH}"
DIR_DEPS="${DIR_CACHE}/deps"
DIR_BASE="${DIR_CACHE}/qgis_base"
DIR_FINAL="${DIR_CACHE}/final_product"

mkdir -p ${DIR_DEPS}
mkdir -p ${DIR_BASE}
mkdir -p ${DIR_FINAL}

INSTALL_DEP="/project/install_dep"

FILE_FINAL_BIN="${DIR_FINAL}/bin/qgis"
FILE_DEPS_LIST="${DIR_DEPS}/packages.list"

# 脚本变量
SCRIPT_ENV="${DIR_AUX}/build_env_vars.sh"
SCRIPT_QGIS="${DIR_AUX}/build_qgis.sh"
SCRIPT_STRIP="${DIR_AUX}/strip_binary.sh"
SCRIPT_PROFILE="${DIR_AUX}/apply-linglong-profile.sh"

# --- 2. 组件配置 ---
COMP_NAMES=("qtkeychain" "e57" "pdal" "inkscape" "blend2d")
COMP_FILES=(
    "${DIR_BASE}/lib/${TRIPLET}/libqt6keychain.so.0.12.0"
    "${DIR_BASE}/lib/libE57Format.so"
    "${DIR_BASE}/bin/pdal"
    "${DIR_BASE}/bin/inkscape"
    "${DIR_BASE}/lib/libblend2d.so"
)
COMP_SCRIPTS=(
    "${DIR_AUX}/build_qtkeychain.sh"
    "${DIR_AUX}/build_e57.sh"
    "${DIR_AUX}/build_pdal.sh"
    "${DIR_AUX}/build_inkscape.sh"
    "${DIR_AUX}/build_blend2d.sh"
)

# --- 3. 核心功能函数 ---

# 报错退出函数
function error_exit() {
    echo "ERROR: $1 失败，时间: $(date '+%Y-%m-%d %H:%M:%S')" >&2
    exit 1
}

# 执行主程序构建
function run_finalize() {
    echo ">>> 开始最终阶段构建..."
    bash "${SCRIPT_QGIS}"    || error_exit "构建 QGIS"
    bash "${SCRIPT_STRIP}"   || error_exit "剥离符号表 (Strip)"
    bash "${SCRIPT_PROFILE}" || error_exit "应用环境配置文件"
    cp -a ${PREFIX}/* "${DIR_FINAL}/"
    echo ">>> 构建任务圆满完成。"
}

# 环境初始化
function run_init_env() {
    echo ">>> 正在初始化构建环境..."
    mkdir -p "${DIR_DEPS}" "${DIR_BASE}" "${DIR_FINAL}"
    # 清理pyqt6.7，避免与pyqt6.9的冲突
    bash "${DIR_AUX}/fix-pyqt6.sh"
    bash "${INSTALL_DEP}" "${DIR_SOURCES}" "${PREFIX}" || error_exit "安装基础依赖"
    
    # 注意：source 环境变量通常对当前 shell 生效
    source "${SCRIPT_ENV}" || error_exit "加载环境变量"
    
    bash "${DIR_AUX}/fix-configs.sh"       || error_exit "修复 CONFIGS"
    bash "${DIR_AUX}/fix-hdf5.sh"          || error_exit "修复 HDF5"
#   bash "${DIR_AUX}/fix-openblas-lib.sh"  || error_exit "修复 OpenBLAS"
    bash "${DIR_AUX}/fix-grass.sh"       || error_exit "修复 GRASS84"
    bash "${DIR_AUX}/fix-runtime-links.sh"       || error_exit "修复编译环境链接"
    bash "${DIR_AUX}/fix-pandas.sh"       || error_exit "修复PANDAS元数据"
    
    # 清理字体，缓存依赖环境
    rm -rf "${PREFIX}/share/fonts"	
    cp -a ${PREFIX}/* "${DIR_DEPS}/"
}

# --- 4. 逻辑执行流程 ---

SHOULD_SKIP_ALL=false

# A. 检查最终产物
if [ -f "${FILE_FINAL_BIN}" ]; then
    echo ">>> 发现最终产物，执行同步..."
    cp -a "${DIR_FINAL}/"* "${PREFIX}/"
    SHOULD_SKIP_ALL=true
fi

if [ "$SHOULD_SKIP_ALL" = false ]; then
    # B. 寻找起始编译点 (Index)
    START_INDEX=-1
    for i in "${!COMP_FILES[@]}"; do
        if [ ! -f "${COMP_FILES[$i]}" ]; then
            START_INDEX=$i
            echo ">>> 检测到组件缺失: ${COMP_NAMES[$i]}"
            break
        fi
    done

    # C. 主逻辑判断
    if [ "$START_INDEX" -eq -1 ] && [ -d "${DIR_BASE}" ] && [ "$(ls -A ${DIR_BASE})" ]; then
        echo ">>> 基础组件库完整，加载缓存后构建主程序..."
        cp -a "${DIR_BASE}/"* "${PREFIX}/"
        source "${SCRIPT_ENV}"
        run_finalize
    else
        # 检查是否需要从环境初始化开始
        if [ ! -f "${FILE_DEPS_LIST}" ]; then
            run_init_env
            START_INDEX=0
        else
            echo ">>> 环境就绪，恢复基础依赖并加载变量..."
            source "${SCRIPT_ENV}"
            cp -a "${DIR_DEPS}/"* "${PREFIX}/"
        fi

        # 循环执行后续组件
        for (( i=0; i<${#COMP_SCRIPTS[@]}; i++ )); do
            # 如果索引小于检测到的起始点，说明已经编译并备份过，直接跳过
            if [ $i -lt $START_INDEX ]; then
                echo ">>> 跳过已存在的组件: ${COMP_NAMES[$i]}"
                continue
            fi

            echo ">>> [$(($i+1))/${#COMP_SCRIPTS[@]}] 正在编译组件: ${COMP_NAMES[$i]}"
            
            # 执行编译脚本
            bash "${COMP_SCRIPTS[$i]}" || error_exit "编译组件 ${COMP_NAMES[$i]}"
            
            # --- 关键修改：每成功一个，同步一次缓存 ---
            echo ">>> 组件 ${COMP_NAMES[$i]} 编译成功，正在同步至缓存..."
            # 使用 cp -a 增量同步到 DIR_BASE
            cp -a ${PREFIX}/* "${DIR_BASE}/"
        done

        # 最终产物构建
        run_finalize
    fi
fi

echo ">>> QGIS构建流程全部完成..."