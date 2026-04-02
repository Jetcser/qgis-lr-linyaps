#!/bin/bash
# ----------------------------------------------------------------
# 脚本名称: fix-runtime-links.sh
# 作用: 处理玲珑构建环境下缺失的系统库、错误的软链接及静态库污染
# ----------------------------------------------------------------

set -e
set -o pipefail

# 确保必要的变量已定义
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
PY_VER="3.12"

APP_LIBDIR="${INSTALL_ROOT}/lib/${TRIPLET}"
BASE_LIBDIR="/usr/lib/${TRIPLET}"
RUNTIME_LIBDIR="/runtime/lib/${TRIPLET}"

# --- 动态获取版本号函数 ---
get_lib_ver() {
    local dir=$1
    local name=$2
    # 查找目录下最长的版本号（例如 libzstd.so.1.5.6 匹配 .1.5.6）
    ls "$dir"/${name}.so.* 2>/dev/null | grep -oP '\d+\.\d+(\.\d+)?' | sort -V | tail -n 1
}

# 1. 从 BASE_LIBDIR (宿主/系统) 获取
libzstd_VER=$(get_lib_ver "${BASE_LIBDIR}" "libzstd")
libopenjp2_VER=$(get_lib_ver "${BASE_LIBDIR}" "libopenjp2")
libfontconfig_VER=$(get_lib_ver "${BASE_LIBDIR}" "libfontconfig")

# 2. 从 RUNTIME_LIBDIR (玲珑运行态) 获取
libexslt_VER=$(get_lib_ver "${RUNTIME_LIBDIR}" "libexslt")
libxslt_VER=$(get_lib_ver "${RUNTIME_LIBDIR}" "libxslt")
libQt6SerialPort_VER=$(get_lib_ver "${RUNTIME_LIBDIR}" "libQt6SerialPort")

# 3. 从当前构建产物目录 (APP_LIBDIR) 获取
libblas_VER=$(get_lib_ver "${APP_LIBDIR}/blas" "libblas")
liblapack_VER=$(get_lib_ver "${APP_LIBDIR}/lapack" "liblapack")

# 4. 特殊处理：针对缺失的版本（假设你代码中预期的版本）
# 如果 APP 目录下还没生成对应的库，可以设定一个回退默认值或保持为空
#libopenjp2_fix_VER="2.5.3"

echo "检测so库版本号："
echo "libzstd: $libzstd_VER"
echo "libopenjp2: $libopenjp2_VER"
echo "libfontconfig: $libfontconfig_VER"
echo "libexslt: $libexslt_VER"
echo "libxslt: $libxslt_VER"
echo "libQt6SerialPort: $libQt6SerialPort_VER"
echo "libblas: $libblas_VER"
echo "liblapack: $liblapack_VER"

echo ">>> 开始应用玲珑构建环境修复..."

# 确保目标路径存在
mkdir -p "${APP_LIBDIR}"

###### PDAL ########

# 修复libblas
ln -sf "${APP_LIBDIR}/libblas.so.${libblas_VER}" \
    "${APP_LIBDIR}/libblas.so.${libblas_VER}"
ln -sf "${APP_LIBDIR}/libblas.so.${libblas_VER}" \
    "${APP_LIBDIR}/libblas.so.3"

# 修复liblapack
ln -sf "${APP_LIBDIR}/liblapack.so.${liblapack_VER}" \
    "${APP_LIBDIR}/liblapack.so.${liblapack_VER}"
ln -sf "${APP_LIBDIR}/liblapack.so.3" \
    "${APP_LIBDIR}/liblapack.so.3"

# 修复libzstd.so.1.5.6
ln -sf "${BASE_LIBDIR}/libzstd.so.1" \
    "${APP_LIBDIR}/libzstd.so.${libzstd_VER}"

# --- 修复 PostgreSQL 动态库链路 ---
cp -d ${RUNTIME_LIBDIR}/libpq.so.5* "${APP_LIBDIR}/"
(
  cd "${APP_LIBDIR}/" || exit
  ln -sf libpq.so.5.* libpq.so
  ln -sf libpq.so.5.* libpq.so.5
)

###### INKSCAPE ########

# 处理libxslt1-dev1.1.35链接
ln -sf ${RUNTIME_LIBDIR}/libexslt.so.${libexslt_VER} \
	${APP_LIBDIR}/libexslt.so
ln -sf ${RUNTIME_LIBDIR}/libxslt.so.${libxslt_VER} \
	${APP_LIBDIR}/libxslt.so

###### QGIS ########

# --- 1. 修复 Python 库 ---
# 玲珑运行态下 libpython 可能会丢失，直接复制实体文件
echo ">> 修复 libpython${PY_VER}"
if [ -f "${BASE_LIBDIR}/libpython${PY_VER}.so.1.0" ]; then
    cp -af "${BASE_LIBDIR}/libpython${PY_VER}.so.1.0" "${APP_LIBDIR}/"
    (cd "${APP_LIBDIR}" && \
     ln -sf "libpython${PY_VER}.so.1.0" "libpython${PY_VER}.so.1" && \
     ln -sf "libpython${PY_VER}.so.1.0" "libpython${PY_VER}.so")
else
    echo "Warning: 系统中未找到 libpython${PY_VER}.so.1.0"
fi

# --- 2. 修复 Qt6 编译链路 ---
echo ">> 修复 qmake6 & Qt6SerialPort"
ln -sf /runtime/bin/qmake6 /runtime/bin/${TRIPLET}-qmake6 || true
if [ -f "${RUNTIME_LIBDIR}/libQt6SerialPort.so.${libQt6SerialPort_VER}" ]; then
    ln -sf "${RUNTIME_LIBDIR}/libQt6SerialPort.so.${libQt6SerialPort_VER}" "${APP_LIBDIR}/"
fi

# --- 3. 修复 PostgreSQL 动态库链路 ---
echo ">> 修复 libpq"
if ls ${RUNTIME_LIBDIR}/libpq.so.5* >/dev/null 2>&1; then
    cp -d ${RUNTIME_LIBDIR}/libpq.so.5* "${APP_LIBDIR}/"
    (cd "${APP_LIBDIR}" && \
     ln -sf libpq.so.5.* libpq.so && \
     ln -sf libpq.so.5.* libpq.so.5)
fi

# --- 4. 修复 ODBC 库 ---
echo ">> 修复 ODBC"
ln -sf ${RUNTIME_LIBDIR}/libodbc.so.2   "${APP_LIBDIR}/libodbc.so"
ln -sf ${RUNTIME_LIBDIR}/libodbccr.so.2 "${APP_LIBDIR}/libodbccr.so"

# --- 5. 修复 OpenJPEG 版本偏差 (2.5.3 -> 2.5.0) ---
#echo ">> 修复 libopenjp2"
#if [ -f "${BASE_LIBDIR}/libopenjp2.so.${libopenjp2_VER}" ]; then
#    ln -sf "${BASE_LIBDIR}/libopenjp2.so.${libopenjp2_VER}" "${APP_LIBDIR}/libopenjp2.so.${libopenjp2_fix_VER}"
#fi

# --- 6. 修复 GeographicLib CMake 配置 ---
echo ">> 修复 GeographicLib CMake 路径"
GEOG_CMAKE="$INSTALL_ROOT/share/cmake/geographiclib"
if [ -f "$GEOG_CMAKE/FindGeographicLib.cmake" ]; then
    ln -sf "FindGeographicLib.cmake" "$GEOG_CMAKE/GeographicLibConfig.cmake"
fi

# --- 7. 解决 Fontconfig 静态库污染 (解决 relocation 错误) ---
echo ">> 修复 Fontconfig"
# 1. 彻底移除安装目录下的静态库（如果有）
rm -f "${APP_LIBDIR}/libfontconfig.a"
# 2. 强制将链接指向系统动态库
if [ -f "${BASE_LIBDIR}/libfontconfig.so.${libfontconfig_VER}" ]; then
    ln -sf "${BASE_LIBDIR}/libfontconfig.so.${libfontconfig_VER}" "${APP_LIBDIR}/libfontconfig.so"
elif [ -f "${RUNTIME_LIBDIR}/libfontconfig.so" ]; then
    ln -sf "${RUNTIME_LIBDIR}/libfontconfig.so" "${APP_LIBDIR}/libfontconfig.so"
fi

echo ">>> 环境修复完成。"