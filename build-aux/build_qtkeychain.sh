#!/bin/bash
set -e

# --- 基础路径定义 ---
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
SOURCES="/project/linglong/sources"
SOURCE_DIR="${SOURCES}/qtkeychain-dsc"
TEMPL_DIR="/project/build-templates"

# 0.12版本QtKeychainConfig.cmake.in在Qt6下行为不正常，使用0.15版本代替
cp -a ${TEMPL_DIR}/QtKeychainConfig.cmake.in ${SOURCE_DIR}/QtKeychainConfig.cmake.in

# --- 进入源码目录 ---
cd "${SOURCE_DIR}"
rm -rf build && mkdir build && cd build

echo "正在为 Qt6 环境配置 Qt6Keychain..."

# 显式传入所有 Qt6 路径
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_ROOT}" \
    -DCMAKE_INSTALL_LIBDIR="lib/${TRIPLET}" \
    -DBUILD_WITH_QT6=ON \
    -DQt6_DIR="/runtime/lib/${TRIPLET}/cmake/Qt6" \
    -DQt6Core_DIR="/runtime/lib/${TRIPLET}/cmake/Qt6Core" \
    -DQt6LinguistTools_DIR="/runtime/lib/${TRIPLET}/cmake/Qt6LinguistTools"

echo "正在开始编译..."
cmake --build . -j$(nproc)

echo "正在安装..."
cmake --install .

echo "✅ Qt6Keychain 编译完成"