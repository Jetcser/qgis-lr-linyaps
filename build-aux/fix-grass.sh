#!/bin/bash

# 修正 GRASS 路径、脚本硬编码及二进制 RUNPATH
set -euo pipefail

# 设置根路径
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
GRASS_HOME="$INSTALL_ROOT/grass84"
GRASS_LIB="$GRASS_HOME/lib"

# 1. 移动 grass84 目录到根路径
if [ -d "$INSTALL_ROOT/lib/grass84" ]; then
    mv "$INSTALL_ROOT/lib/grass84" "$INSTALL_ROOT/"
    echo "Moved grass84 to $INSTALL_ROOT/"
fi

# 2. 修正 grass 启动脚本 (Python)
GRASS_BIN="$INSTALL_ROOT/bin/grass"
if [ -f "$GRASS_BIN" ]; then
    sed -i "s|/usr/lib/grass84|$GRASS_HOME|g" "$GRASS_BIN"
    sed -i "s|/usr/share/proj|$INSTALL_ROOT/share/proj|g" "$GRASS_BIN"
    echo "Patched $GRASS_BIN"
fi

# 3. 修正 x-grass 脚本 (Shell)
XGRASS_BIN="$INSTALL_ROOT/bin/x-grass"
if [ -f "$XGRASS_BIN" ]; then
    sed -i "s|/usr/bin/grass|$INSTALL_ROOT/bin/grass|g" "$XGRASS_BIN"
    echo "Patched $XGRASS_BIN"
fi

# 4. 修正共享库的 RUNPATH
if [ -d "$GRASS_LIB" ]; then
    echo "Fixing RUNPATH in $GRASS_LIB..."
    # 查找并处理所有 .so 文件（排除符号链接）
    find "$GRASS_LIB" -maxdepth 1 -name "*.so*" -type f | while read -r lib; do
        if file "$lib" | grep -q "ELF"; then
            patchelf --set-rpath "$GRASS_LIB" "$lib"
            echo "Fixed RUNPATH: $(basename "$lib")"
        fi
    done
fi

echo "GRASS path correction completed."