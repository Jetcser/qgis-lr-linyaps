#!/bin/bash
set -euo pipefail

# --- 记录日志 ---
LOG_FILE="/project/logs/build_inkscape.log"
exec > >(tee -i "$LOG_FILE") 2>&1

# 自定义路径与环境变量
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
SOURCES="/project/linglong/sources"
INKSCAPE_SRC_DIR="$SOURCES/inkscape-dsc"

echo "===== 开始构建 INKSCAPE ====="

cd "$INKSCAPE_SRC_DIR"

# 删除混淆的GraphicsMagick链接
rm -f "${INSTALL_ROOT}/lib/pkgconfig/ImageMagick++.pc"
rm -f "${INSTALL_ROOT}/lib/pkgconfig/ImageMagick.pc"

# 配置与编译
rm -rf build 
mkdir -p build && cd build

echo "正在配置 CMake..."
cmake .. -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_ROOT" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_POPPLER=ON \
    -DWITH_IMAGE_MAGICK=ON \
    -DWITH_GRAPHICS_MAGICK=OFF \
    -DWITH_NLS=OFF \
    -DWITH_GSPELL=OFF \
    -DWITH_X11=OFF \
    -DBUILD_TESTING=OFF

echo "正在编译..."
ninja -j$(nproc)

echo "正在安装..."
ninja install

echo "清理冗余及包装程序入口..."
rm -rf "${INSTALL_ROOT}/share/icons/hicolor/cursors"
rm -rf "${INSTALL_ROOT}/share/icons/hicolor/scalable/actions"
rm -rf "${INSTALL_ROOT}/share/icons/multicolor"
rm -rf "${INSTALL_ROOT}/share/icons/Tango"

rm -rf "${INSTALL_ROOT}/share/inkscape/tutorials"
rm -rf "${INSTALL_ROOT}/share/inkscape/examples"

rm -f "${INSTALL_ROOT}/bin/inkview"

# 创建headless程序入口
cp -f "${INSTALL_ROOT}/bin/inkscape" "${INSTALL_ROOT}/bin/inkscape.bin"
cp -f "/project/build-templates/inkscape.in" "${INSTALL_ROOT}/bin/inkscape"

echo "===== 结束构建 INKSCAPE ====="
