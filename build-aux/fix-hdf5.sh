#!/bin/bash
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
H5_REAL_DIR="$INSTALL_ROOT/lib/$TRIPLET/hdf5/serial"
H5_SETTINGS="$H5_REAL_DIR/libhdf5.settings"

echo "=== 修复 HDF5 环境 ==="

# 1. 修正 .settings 配置文件
if [ -f "$H5_SETTINGS" ]; then
    sed -i "s@Installation point: /usr@Installation point: $INSTALL_ROOT@g" "$H5_SETTINGS"
    ln -srf "$H5_SETTINGS" "$H5_REAL_DIR/libhdf5_serial.settings"
fi

# 2. 批量修正包装器脚本
for cmd in h5cc h5c++ h5fc; do
    WRAPPER="$INSTALL_ROOT/bin/$cmd"
    if [ -f "$WRAPPER" ]; then
        sed -i "s@^prefix=.*@prefix=\"$INSTALL_ROOT\"@g" "$WRAPPER"
        sed -i "s@^exec_prefix=.*@exec_prefix=\"$INSTALL_ROOT\"@g" "$WRAPPER"
        sed -i "s@^libdir=.*@libdir=\"$H5_REAL_DIR\"@g" "$WRAPPER"
        sed -i "s@^includedir=.*@includedir=\"$H5_REAL_DIR/include\"@g" "$WRAPPER"
        sed -i "s@^libdevdir=.*@libdevdir=\"$H5_REAL_DIR\"@g" "$WRAPPER"
    fi
done

# 3. 验证
$INSTALL_ROOT/bin/h5cc -showconfig | grep "Installation point"