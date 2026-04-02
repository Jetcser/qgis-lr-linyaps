#!/bin/bash
# 通过 source build_env_vars.sh 调用

set -e

# 基础路径定义 (确保变量已在外部定义，否则给定默认值)
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
GRASS_VER="84"
PY_VER="3.12"

export PERL5LIB=/runtime/share/perl5
export LC_ALL=C

export GISBASE="${INSTALL_ROOT}/grass84"
export PROJ_LIB="${INSTALL_ROOT}/share/proj"
export GDAL_DATA="${INSTALL_ROOT}/share/gdal"

export BISON_PKGDATADIR="${INSTALL_ROOT}/share/bison"
export M4="/usr/bin/m4"

mkdir -p "/project/logs"

export QT_PLUGIN_PATH="\
${INSTALL_ROOT}/lib/${TRIPLET}/qt6/plugins:\
${INSTALL_ROOT}/lib/${TRIPLET}/qca-qt6:\
/runtime/lib/${TRIPLET}/qt6/plugins:\
${QT_PLUGIN_PATH:-}"

export QML2_IMPORT_PATH="\
${INSTALL_ROOT}/lib/${TRIPLET}/qt6/qml:\
/runtime/lib/${TRIPLET}/qt6/qml:\
${QML2_IMPORT_PATH:-}"

# --- 1. 编译时库搜索路径 (静态库/动态库链接) ---
export LIBRARY_PATH="\
${INSTALL_ROOT}/grass${GRASS_VER}/lib:\
${INSTALL_ROOT}/lib/${TRIPLET}:\
${INSTALL_ROOT}/lib:\
/runtime/lib/${TRIPLET}:\
/runtime/lib:\
/usr/lib/${TRIPLET}:\
/usr/lib:\
${LIBRARY_PATH:-}"

# --- 2. 运行时动态库路径 (程序启动查找 .so) ---
# 遍历PREFIX/lib子目录
SUB_LIBS=(
    "${TRIPLET}"
    "${TRIPLET}/lapack"
    "${TRIPLET}/blas"
    "${TRIPLET}/gdk-pixbuf-2.0/2.10.0/loaders"
    "${TRIPLET}/graphviz"
    "${TRIPLET}/odbc"
    "${TRIPLET}/libmariadb3/plugin"
    "${TRIPLET}/hdf5/serial"
    "${TRIPLET}/libheif/plugins"
    "${TRIPLET}/mit-krb5"
#    "${TRIPLET}/openblas-pthread"
    "${TRIPLET}/qca-qt6/crypto"
    "${TRIPLET}/qca-qt6/ogdi/4.1"
)

# 循环拼接路径，获取子目录路径
EXT_LIB_PATHS=""
for sub in "${SUB_LIBS[@]}"; do
    EXT_LIB_PATHS="${INSTALL_ROOT}/lib/${sub}:${EXT_LIB_PATHS}"
done

# 构造变量
export LD_LIBRARY_PATH="\
${EXT_LIB_PATHS}:\
${INSTALL_ROOT}/grass${GRASS_VER}/lib:\
${INSTALL_ROOT}/lib/${TRIPLET}:\
${INSTALL_ROOT}/lib:\
/runtime/lib/${TRIPLET}:\
/runtime/lib:\
/usr/lib/${TRIPLET}:\
/usr/lib:\
${LD_LIBRARY_PATH:-}"

# --- 3. pkg-config 配置文件路径 (处理 .pc 文件) ---
export PKG_CONFIG_PATH="\
${INSTALL_ROOT}/lib/${TRIPLET}/pkgconfig:\
${INSTALL_ROOT}/lib/pkgconfig:\
${INSTALL_ROOT}/share/pkgconfig:\
/runtime/lib/${TRIPLET}/pkgconfig:\
/runtime/lib/pkgconfig:\
/runtime/share/${TRIPLET}/pkgconfig:\
/usr/lib/${TRIPLET}/pkgconfig:\
/usr/lib/pkgconfig:\
/usr/share/pkgconfig:\
${PKG_CONFIG_PATH:-}"

# --- 5. C/C++ 编译器头文件搜索路径 ---
export CPATH="\
${INSTALL_ROOT}/grass${GRASS_VER}/include:\
${INSTALL_ROOT}/include:\
${INSTALL_ROOT}/include/python${PY_VER}:\
${INSTALL_ROOT}/include/${TRIPLET}:\
${INSTALL_ROOT}/include/qt6keychain:\
/runtime/include:\
/runtime/include/python${PY_VER}:\
/runtime/include/${TRIPLET}:\
/usr/include/python${PY_VER}:\
/usr/include/${TRIPLET}:\
/usr/include:\
${CPATH:-}"

# --- 4. CMake 查找前缀 (find_package 核心路径) ---
export CMAKE_PREFIX_PATH="\
${INSTALL_ROOT}/share/cmake:\
${INSTALL_ROOT}/lib/${TRIPLET}/cmake:\
${INSTALL_ROOT}/lib:\
${INSTALL_ROOT}:\
/runtime/lib/${TRIPLET}/cmake:\
/runtime/lib:\
/runtime:\
/usr/lib/${TRIPLET}/cmake:\
/usr/lib:\
/usr:\
${CMAKE_PREFIX_PATH:-}"

# 解决 GeographicLib 的 Find 脚本找不到的问题
export CMAKE_MODULE_PATH="\
${INSTALL_ROOT}/share/cmake/geographiclib:\
${CMAKE_MODULE_PATH:-}"

# --- 3. PYTHONPATH 路径---
# 优先级：自定义安装路径 > Runtime 路径 > 系统路径
export PYTHONPATH="\
${INSTALL_ROOT}/lib/python3/dist-packages:\
${INSTALL_ROOT}/lib/python${PY_VER}/dist-packages:\
${INSTALL_ROOT}/share/qgis/python:\
/runtime/lib/python3/dist-packages:\
/usr/lib/python3/dist-packages:\
${PYTHONPATH:-}"

# --- 4. PATH 路径 ---
export PATH="\
${INSTALL_ROOT}/grass${GRASS_VER}/bin:\
${INSTALL_ROOT}/grass${GRASS_VER}/scripts:\
${INSTALL_ROOT}/bin:\
${PATH:-}"