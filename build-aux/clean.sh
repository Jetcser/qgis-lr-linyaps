#!/bin/bash

# 自定义路径与环境变量
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs)

rm -rf "${INSTALL_ROOT}/include/qgis"
rm -f "${INSTALL_ROOT}/share/qgis/FindQGIS.cmake"
find "${INSTALL_ROOT}" -name "*.sip" -exec rm -rf {} +
rm -f "${INSTALL_ROOT}/bin/qgis_bench"
rm -f "${INSTALL_ROOT}/bin/test_provider_wcs"
rm -rf "${INSTALL_ROOT}/share/fonts"

# 清除sbin等冗余
rm -rf "${INSTALL_ROOT}/sbin"
rm -rf "${INSTALL_ROOT}/libexec"
rm -rf "${INSTALL_ROOT}/man"
rm -rf "${INSTALL_ROOT}/mkspecs"
rm -rf "${INSTALL_ROOT}/src"

# 清除 bin 目录冗余
REMOVE_BIN=(
    *-config *_config gcc* *gcc gcov* bison* make dh_*
    clang* aclocal-1.17 autoconf autoheader autom4te cache
    automake-1.17 autoreconf autoscan autoupdate
    ${TRIPLET}-*
)

for item in "${REMOVE_BIN[@]}"; do
    rm -rf ${INSTALL_ROOT}/bin/$item
done

# 清除 share 目录冗余
REMOVE_SHARE=(
    aclocal* autoconf automake* cmake* pkgconfig libtool
    doc doc-base man info gtk-doc help
    gdb clang debhelper lintian bison vala
    apport bug zsh bash-completion
    eigen3 emacs et djvu dpkg gettext gir-1.0 nodejs perl5 sass
    sphinx_rtd_theme tcltk thumbnailers vim vulkan wayland* xml*
    pixmaps numpy3 mysql-common misc metainfo menu icu sgml* )

for item in "${REMOVE_SHARE[@]}"; do
    rm -rf ${INSTALL_ROOT}/share/$item
done

# 清理空目录
find ${INSTALL_ROOT} -depth -empty -type d -delete