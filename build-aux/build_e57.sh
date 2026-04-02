#!/bin/bash

# 遇到错误立即退出
set -euo pipefail

# 记录日志
LOG_FILE="/project/logs/build_e57.log"
exec > >(tee -i "$LOG_FILE") 2>&1

INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
SOURCES="/project/linglong/sources"
E57_TARBALL="$SOURCES/e57-src.tar.gz"
E57_SRC_DIR="$SOURCES/e57-src"

echo "===== 开始构建 E57 ====="

#rm -rf "$E57_SRC_DIR"
mkdir -p "$E57_SRC_DIR"

echo "正在解压..."
tar -xf "$E57_TARBALL" -C "$E57_SRC_DIR" --strip-components=1

# 3. 编译构建
cd "$E57_SRC_DIR"
rm -rf build && mkdir -p  build && cd build

echo "正在配置 CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_ROOT}" \
    -DE57_BUILD_TEST=OFF \
    -DE57_BUILD_SHARED=ON

echo "正在编译..."
make -j$(nproc)

echo "正在安装..."
make install

echo "===== 结束构建E57 ====="

