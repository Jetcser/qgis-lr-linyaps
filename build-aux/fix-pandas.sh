#!/bin/bash

INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
SITE_DIR="${INSTALL_ROOT}/lib/python3/dist-packages"
PANDAS_DIR="${SITE_DIR}/pandas"

echo "=== 修复 PANDAS 元数据 ==="

# 1. 提取原始版本号 (2.2.3)
PD_VER_RAW=$(grep "^version =" "${PANDAS_DIR}/__version.py" | cut -d"'" -f2)

if [ -z "$PD_VER_RAW" ]; then
    echo "错误：无法提取版本号"
    exit 1
fi

# 2. 拼接为 2.2.3+dfsg
PD_VER="${PD_VER_RAW}+dfsg"
echo "处理后的版本号: ${PD_VER}"

# 3. 更新 _version.py 中的 JSON 内容
sed -i "s/\"error\": \"unable to compute version\"/\"error\": null/" "${PANDAS_DIR}/_version.py"
sed -i "s/\"version\": \"0+unknown\"/\"version\": \"${PD_VER}\"/" "${PANDAS_DIR}/_version.py"

# 4. 重命名 egg-info 目录并修改内部文件
OLD_EGG="${SITE_DIR}/pandas-0+unknown.egg-info"
NEW_EGG="${SITE_DIR}/pandas-${PD_VER}.egg-info"

if [ -d "$OLD_EGG" ]; then
    mv "$OLD_EGG" "$NEW_EGG"
    PKG_INFO="${NEW_EGG}/PKG-INFO"
    [ -f "$PKG_INFO" ] && sed -i "s/^Version: 0+unknown/Version: ${PD_VER}/" "$PKG_INFO"
fi

echo "修复完成！"