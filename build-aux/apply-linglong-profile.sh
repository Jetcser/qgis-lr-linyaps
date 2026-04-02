#!/bin/bash

INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"

mkdir -p "$INSTALL_ROOT/etc"

cp "/project/build-templates/profile.in" "$INSTALL_ROOT/etc/profile"
chmod +x "$INSTALL_ROOT/etc/profile"

cp "/project/build-templates/env_vars.sh.in" "$INSTALL_ROOT/bin/env_vars.sh"
chmod +x "$INSTALL_ROOT/bin/env_vars.sh"

echo "qgis启动参数已添加.."