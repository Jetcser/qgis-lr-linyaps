#!/bin/bash

# 遇到错误立即退出，引用未定义变量报错
set -euo pipefail

# 记录日志
LOG_FILE="/project/logs/build_pdal.log"
echo "--- Build started at $(date) ---" > "$LOG_FILE"
exec > >(tee -i "$LOG_FILE") 2>&1

# --- 1. 显式路径与 ccache 配置 ---
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
SOURCES="/project/linglong/sources"
PDAL_TARBALL="$SOURCES/pdal-src.tar.bz2"
PDAL_SRC_DIR="$SOURCES/pdal-src"

# 处理/runtime目录下的ztsd库链接
BASE_LIBDIR="/usr/lib/${TRIPLET}"
RUNTIME_LIBDIR="/runtime/lib/${TRIPLET}"
libzstd_VER=$(ls ${BASE_LIBDIR}/libzstd.so.* 2>/dev/null | grep -oP '\d+\.\d+(\.\d+)?' | sort -V | tail -n 1)
ln -sf "${BASE_LIBDIR}/libzstd.so.1" \
    "${RUNTIME_LIBDIR}/libzstd.so.${libzstd_VER}"

echo "===== 开始构建 PDAL ====="

echo "解压源码包..."
if [ -f "${PDAL_SRC_DIR}/CMakeLists.txt" ]; then
    echo ">>> 检测到源码已存在，跳过解压..."
else
    echo ">>> 正在解压 $PDAL_TARBALL ..."
    mkdir -p "$PDAL_SRC_DIR"
    tar -xf "$PDAL_TARBALL" -C "$PDAL_SRC_DIR" \
        --strip-components=1 \
        --no-same-owner \
        --no-same-permissions
fi

# 处理GDAL库冲突：移动安装目录下的旧版本库以防干扰编译
mkdir -p ${INSTALL_ROOT}/bak
mv ${INSTALL_ROOT}/lib/${TRIPLET}/libgdal.so.34* ${INSTALL_ROOT}/bak/

cd $PDAL_SRC_DIR
rm -rf build 
mkdir -p build && cd build

echo "正在配置 CMake..."
# 添加WITH_BACKTRACE参数，避免libunwind引起的回溯链接错误
cmake .. \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_ROOT}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_PLUGIN_PGPOINTCLOUD=ON \
    -DBUILD_PLUGIN_E57=ON \
    -DBUILD_PLUGIN_HDF=ON \
    -DBUILD_PLUGIN_I3S=ON \
    -DBUILD_PLUGIN_ICEBRIDGE=ON \
    -DBUILD_PLUGIN_DRACO=ON \
    -DBUILD_PLUGIN_FAUX=ON \
    -DWITH_COMPLETION=ON \
    -DWITH_TESTS=OFF \
    -DWITH_BACKTRACE=OFF

echo "正在编译..."
ninja -j$(nproc)

echo "正在安装..."
ninja install

mv ${INSTALL_ROOT}/bak/libgdal.so.34* "$INSTALL_ROOT/lib/${TRIPLET}/"
rm -rf ${INSTALL_ROOT}/bak

echo "===== 结束构建 PDAL ====="
