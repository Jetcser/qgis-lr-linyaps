#!/bin/bash
# 修正 bin/*-config 脚本中的硬编码路径，同时保留首行 Shebang 声明
set -euo pipefail

# 默认路径
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
BIN_DIR="${INSTALL_ROOT}/bin"

echo ">>> 正在修正配置脚本路径 (Prefix: $INSTALL_ROOT)"

# 确保目录存在
[ -d "$BIN_DIR" ] || exit 0

# 处理wx-config
WX_CONFIG="${INSTALL_ROOT}/lib/${TRIPLET}/wx/config/gtk3-unicode-3.2"
if [ -f "$WX_CONFIG" ]; then
    cp -f "$WX_CONFIG" "${INSTALL_ROOT}/bin/wx-config"
fi

# 遍历所有相关的配置脚本
for cfg in "$BIN_DIR"/*-config "$BIN_DIR"/pg_config; do
    [ -f "$cfg" ] || continue
    
    # 仿照你的 pkgconfig 修改逻辑：
    # 1. 只有是脚本文件（Shell 或 Perl）才处理
    # 2. 使用 2,$s 避开首行 Shebang
    # 3. 使用 # 或 | 作为分隔符，防止路径冲突
    
    FILE_TYPE=$(file -b "$cfg")
    if [[ "$FILE_TYPE" == *"script"* ]]; then
        echo "  - FIX CONFIG $FILE_TYPE: $(basename "$cfg")"
        
        # 核心替换逻辑：仅处理第2行到末尾
        sed -i "2,\$s#/usr#$INSTALL_ROOT#g" "$cfg" 2>/dev/null || true
        
        # 修正 Debian 特有的多架构路径后缀
        sed -i "2,\$s#/lib/x86_64-linux-gnu#/lib#g" "$cfg" 2>/dev/null || true
        
        # 防止重复执行导致的路径叠加 (例如 /opt/opt/...)
        sed -i "2,\$s#$INSTALL_ROOT$INSTALL_ROOT#$INSTALL_ROOT#g" "$cfg" 2>/dev/null || true
        
        chmod +x "$cfg"
    fi
done