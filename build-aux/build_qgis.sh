#!/bin/bash

# Deepin23源中自带Qt6 3DExtras组件，不需要额外处理cmake中的相关参数。

# 遇到错误立即退出，引用未定义变量报错，管道错误传播
set -euo pipefail

# 日志初始化
LOG_FILE="/project/logs/build_${LINGLONG_APPID}.log"
echo "--- Build Log Started at $(date) ---" > "$LOG_FILE"
exec > >(tee -i "$LOG_FILE") 2>&1

# 自定义路径与环境变量
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)
QT_VER="6"
PY_VER="3.12"
GRASS_MAINVER="8"
GRASS_INSTALL_PATH="${INSTALL_ROOT}/grass84"
PROJ_DATA="${INSTALL_ROOT}/share/proj"
SOURCES="/project/linglong/sources"
QGIS_TARBALL="$SOURCES/qgis_3.99.0+git20260206+09f76ad7019+99sid.tar.gz"
QGIS_SRC_DIR="/project/qgis-src"
#QGIS_SRC_DIR="${SOURCES}/qgis-src"
TEMPL_DIR="/project/build-templates"
BUILD_ENV="/project/build-aux/build_env_vars.sh"
QT_ENV="/project/build-aux/build_env_qt6.sh"
CLEAN_TOOL="/project/build-aux/clean.sh"
CHS_TRANSLATION="${QGIS_SRC_DIR}/i18n/qgis_zh-Hans.ts"
GISAPP_CPP="${QGIS_SRC_DIR}/src/app/qgisapp.cpp"
GISAPPLICATION_CPP="${QGIS_SRC_DIR}/src/core/qgsapplication.cpp"
GISAPPLICATION_CPP_PATCH="${TEMPL_DIR}/installTranslators_patch_qt${QT_VER}.txt"

source $BUILD_ENV

echo "解压源码包..."
if [ -f "${QGIS_SRC_DIR}/CMakeLists.txt" ]; then
    echo ">>> 检测到源码已存在，跳过解压..."
else
    echo ">>> 正在解压 $QGIS_TARBALL ..."
    mkdir -p "$QGIS_SRC_DIR"
    tar -xf "$QGIS_TARBALL" -C "$QGIS_SRC_DIR" \
        --strip-components=1 \
        --no-same-owner \
        --no-same-permissions
fi

echo "准备ccache缓存..."
mkdir -p "/project/ccache_storage"
export "CCACHE_DIR=/project/ccache_storage"

# 获取QGIS版本号
QGIS_MAJOR=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_MAJOR "\([0-9]*\)")/\1/ip' ${QGIS_SRC_DIR}/CMakeLists.txt)
QGIS_MINOR=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_MINOR "\([0-9]*\)")/\1/ip' ${QGIS_SRC_DIR}/CMakeLists.txt)
QGIS_PATCH=$(sed -ne 's/SET(CPACK_PACKAGE_VERSION_PATCH "\([0-9]*\)")/\1/ip' ${QGIS_SRC_DIR}/CMakeLists.txt)
QGIS_VER="${QGIS_MAJOR}.${QGIS_MINOR}.${QGIS_PATCH}"

echo "QGIS版本号：${QGIS_VER}"

# ============ 前置编译环境准备 =============
# 自定义QGIS关于页面的操作系统名称，修改为玲珑环境标识
LINGLONG_STR="Linyaps Runtime Environment"
sed -i "s/QSysInfo::prettyProductName()/QStringLiteral(\"${LINGLONG_STR}\")/g" "${GISAPP_CPP}"

# 修正installTranslators函数寻找中文翻译文件的逻辑
python3 "/project/build-aux/fix-installTranslators.py" ${GISAPPLICATION_CPP} ${GISAPPLICATION_CPP_PATCH}

# 修正简体中文菜单中Web的翻译，汉化为“网络”
sed -i 's|<translation>Web(&amp;W)</translation>|<translation>网络(\&amp;W)</translation>|g' ${CHS_TRANSLATION}

# 应用qt.conf，定位翻译目录/runtime/...
cp -f "${TEMPL_DIR}/qt${QT_VER}.conf.in" "${INSTALL_ROOT}/bin/qt.conf"

# 确保区域设置正确，避免 Qt 警告
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# 构建PyQGIS.pap需要非空的 machine-id，修复 D-Bus machine-id 缺失问题
mkdir -p /var/lib/dbus
dbus-uuidgen --ensure=/var/lib/dbus/machine-id
ln -sf /var/lib/dbus/machine-id /etc/machine-id
echo "Current machine-id: $(cat /etc/machine-id 2>/dev/null || echo 'unknown')"

# ============ 编译准备 =============
cd "$QGIS_SRC_DIR"

# --- 基础环境配置 ---
export QT_SELECT="qt6"
export NINJA_STATUS="[%f/%t %p] "

# --- 识别 Python 库路径 ---
PYTHON_LIBRARY=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR') + '/' + sysconfig.get_config_var('LDLIBRARY'))")
echo "Python lib：${PYTHON_LIBRARY}"

# --- 构建 CMake 参数 ---
CMAKE_OPTS=(
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    #"-DCMAKE_BUILD_TYPE=Debug"
    "-DCMAKE_INSTALL_PREFIX=${INSTALL_ROOT}"
    "-DCCACHE_EXE:FILEPATH=${INSTALL_ROOT}/bin/ccache"
    "-DWITH_INTERNAL_NLOHMANN_JSON=OFF"
    "-DCMAKE_VERBOSE_MAKEFILE=1"
    "-DBINDINGS_GLOBAL_INSTALL=FALSE"
    "-DSIP_GLOBAL_INSTALL=FALSE"
    "-DPEDANTIC=TRUE"
    "-DQGIS_QML_SUBDIR=share/qgis/qml"
    "-DWITH_CUSTOM_WIDGETS=TRUE"
    "-DWITH_QWTPOLAR=FALSE"
    "-DWITH_QSPATIALITE=TRUE"
    "-DWITH_3D=TRUE"
    "-DWITH_HANA=TRUE"
    "-DWITH_EPT=TRUE"
    "-DWITH_SERVER=FALSE"
    "-DWITH_SERVER_PLUGINS=FALSE"
    "-DWITH_INTERNAL_SPATIALINDEX=TRUE"
    "-DWITH_QTWEBKIT=OFF"
    "-DWITH_QTWEBENGINE=ON"
    "-DWITH_QUICK=ON"
    "-DWITH_GRASS=TRUE"
    "-DWITH_GRASS7=FALSE"
    "-DWITH_GRASS${GRASS_MAINVER}=TRUE"
    "-DGRASS_PREFIX${GRASS_MAINVER}=${GRASS_INSTALL_PATH}"
    "-DWITH_QSCIAPI=ON"
    "-DWITH_GEOGRAPHICLIB=TRUE"
    "-DWITH_SFCGAL=TRUE"
    "-DWITH_APIDOC=OFF"
    "-DWITH_PDAL=TRUE"
    "-DENABLE_TESTS=FALSE"
    "-DQT_DEBUG_FIND_PACKAGE=ON"
    #"-DWITH_PDF4QT=TRUE"
    "-DWITH_PDF4QT=FALSE"
    "-DQT_PLUGINS_DIR=lib/${TRIPLET}/qt6/plugins"
    "-DWITH_INTERNAL_QWT=TRUE"
)

source $QT_ENV

#CMAKE_OPTS+=(
#  "-Wno-dev"
#)

# --- 针对 Qt6Keychain 和 QMake 的专项修复 ---
CMAKE_OPTS+=(
  "-DQt6Keychain_DIR=${INSTALL_ROOT}/lib/${TRIPLET}/cmake/Qt6Keychain"
  "-DQTKEYCHAIN_INCLUDE_DIR=${INSTALL_ROOT}/include/qt6keychain"
  "-DQTKEYCHAIN_LIBRARY=${INSTALL_ROOT}/lib/${TRIPLET}/libqt6keychain.so"
  # 显式指定 QMAKE 路径
  "-DQT_QMAKE_EXECUTABLE=/runtime/bin/qmake6"
)

# 指定QScintilla开发文件路径
CMAKE_OPTS+=(
  "-DQSCINTILLA_INCLUDE_DIR=${INSTALL_ROOT}/include/${TRIPLET}/qt6"
  "-DQSCINTILLA_LIBRARY=${INSTALL_ROOT}/lib/${TRIPLET}/libqscintilla2_qt6.so"
)

echo "开始编译..."

# 删除旧的构建目录
rm -rf build
mkdir -p build && cd build

cmake .. "${CMAKE_OPTS[@]}"
ninja -j$(nproc)

echo "开始安装..."
ninja install

# 将pdf4qt的库移动到lib/下
mv ${INSTALL_ROOT}/usr/lib/libPdf4QtLibCore* ${INSTALL_ROOT}/lib/ 2>/dev/null || true
rm -rf  ${INSTALL_ROOT}/usr/lib

echo "安装图标及mime资源"
rm -rf ${INSTALL_ROOT}/share/icons/*
rm -rf ${INSTALL_ROOT}/share/mime/*
cp -af ${TEMPL_DIR}/xdg-resource/* "${INSTALL_ROOT}/share/"
echo "图标安装完成..."

echo "安装程序快捷方式"
TMP_DESKTOP="${TEMPL_DIR}/org.qgis.qgis.desktop.in"
LL_DESKOP="${INSTALL_ROOT}/share/applications/${LINGLONG_APPID}.linyaps.desktop"
rm -rf ${INSTALL_ROOT}/share/applications/*
cp -f "${TMP_DESKTOP}" "${LL_DESKOP}"
# 将desktop模板里的@VERSION@替换为变量值 QGIS_VER
sed -i "s/@VERSION@/${QGIS_VER}/g" "${LL_DESKOP}"
echo "程序快捷方式安装完成..."

echo "清理QGIS开发及冗余文件..."
${CLEAN_TOOL}

# --- Python 字节码编译 (生成 .pyc) ---
echo "编译Python字节码..."

# 使用 python3 的 compileall 模块进行静态编译，静默模式
find ${INSTALL_ROOT} -name "__pycache__" -exec rm -rf {} +
find ${INSTALL_ROOT} -name "*.pyc" -delete
python3 -m compileall -f -q "${INSTALL_ROOT}/share/qgis/python"
python3 -m compileall -f -q "${INSTALL_ROOT}/lib/python3/dist-packages"

echo "QGIS构建完成，安装路径： ${INSTALL_ROOT}"