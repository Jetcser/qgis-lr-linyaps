#!/bin/bash

# 遇到错误立即退出
set -euo pipefail

# 记录日志
LOG_FILE="/project/logs/build_blend2d.log"
exec > >(tee -i "$LOG_FILE") 2>&1

# 玲珑环境相关配置
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
SOURCES="/project/linglong/sources"

# Blend2d 路径配置
BLEND2D_TARBALL="$SOURCES/blend2d-src.tar.bz2"
BLEND2D_SRC_DIR="$SOURCES/blend2d-src"

echo "===== 开始构建 Blend2D ====="

# 准备源码
mkdir -p "$BLEND2D_SRC_DIR"

echo "正在解压..."
# .tar.bz2 使用 -xf 即可自动识别
tar -xf "$BLEND2D_TARBALL" -C "$BLEND2D_SRC_DIR" --strip-components=1

# 移除CMakeLists自带的-O2优化参数,交给CMake控制
cd "$BLEND2D_SRC_DIR"
if [ -f "CMakeLists.txt" ]; then
    echo "正在预处理 CMakeLists.txt..."
    sed -i '/-O2/d' 'CMakeLists.txt'
fi

# 编译构建
echo "创建构建目录..."
rm -rf build && mkdir -p build && cd build

# 设置编译器为 Clang
export CC="clang-17"
export CXX="clang++-17"

echo "正在配置 CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_ROOT}" \
    -DBLEND2D_TEST=FALSE \
    -DBLEND2D_EMBED=FALSE \
    -DBLEND2D_STATIC=FALSE \
    -DBLEND2D_EXTERNAL_ASMJIT=FALSE \
    -Wno-dev

echo "正在编译..."
make -j$(nproc)

echo "正在安装..."
make install

echo "===== 结束构建 Blend2D ====="