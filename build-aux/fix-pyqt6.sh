#! /bin/bash

set -e
set -o pipefail

SOURCES="/project/linglong/sources"
REMOVE_VER="6.7"

# 定义所有包含二进制绑定、存在 ABI 冲突风险的核心包
# 排除掉版本中立的构建工具 (sipbuild, pyqtbuild)
TARGETS=(
    "python3-pyqt6"
    "python3-pyqt6.qtmultimedia"
    "python3-pyqt6.qtpositioning"
    "python3-pyqt6.qtserialport"
    "python3-pyqt6.qtsvg"
    "pyqt6-dev"
    "pyqt6-dev-tools"
)

# 清理ABI冲突的PyQt6-6.7
for pkg in "${TARGETS[@]}"; do rm -f "${SOURCES}/${pkg}_${REMOVE_VER}"*.deb; done