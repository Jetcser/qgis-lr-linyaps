#!/bin/bash

# 获取环境变量
INSTALL_ROOT="/opt/apps/${LINGLONG_APPID}/files"
TRIPLET=$(cat "/etc/linglong-triplet-list" | xargs 2>/dev/null || echo "x86_64-linux-gnu")


# 定义搜索根目录
RUNTIME_BASE="/runtime/lib/${TRIPLET}/cmake"
APP_BASE="${INSTALL_ROOT}/lib/${TRIPLET}/cmake"

# 区分 /runtime (系统组件) 与 INSTALL_ROOT (应用组件)

# --- Qt6 编译辅助工具 (位于 /runtime) ---
# 显式指定工具路径，防止 CMake 调用系统自带的旧版工具
CMAKE_OPTS+=(
  "-DQt6CoreTools_DIR=${RUNTIME_BASE}/Qt6CoreTools"
  "-DQt6GuiTools_DIR=${RUNTIME_BASE}/Qt6GuiTools"
  "-DQt6WidgetsTools_DIR=${RUNTIME_BASE}/Qt6WidgetsTools"
  "-DQt6LinguistTools_DIR=${RUNTIME_BASE}/Qt6LinguistTools"
)

# --- Qt6 核心基础模块 (位于 /runtime) ---
CMAKE_OPTS+=(
  "-DQt6_DIR=${RUNTIME_BASE}/Qt6"
  "-DQt6Core_DIR=${RUNTIME_BASE}/Qt6Core"
  "-DQt6Gui_DIR=${RUNTIME_BASE}/Qt6Gui"
  "-DQt6Widgets_DIR=${RUNTIME_BASE}/Qt6Widgets"
  "-DQt6Network_DIR=${RUNTIME_BASE}/Qt6Network"
  "-DQt6Sql_DIR=${RUNTIME_BASE}/Qt6Sql"
  "-DQt6Xml_DIR=${RUNTIME_BASE}/Qt6Xml"
  "-DQt6DBus_DIR=${RUNTIME_BASE}/Qt6DBus"
  "-DQt6PrintSupport_DIR=${RUNTIME_BASE}/Qt6PrintSupport"
  "-DQt6Concurrent_DIR=${RUNTIME_BASE}/Qt6Concurrent"
  "-DQt6Test_DIR=${RUNTIME_BASE}/Qt6Test"
  "-DQt6Svg_DIR=${RUNTIME_BASE}/Qt6Svg"
  "-DQt6SvgWidgets_DIR=${RUNTIME_BASE}/Qt6SvgWidgets"
  "-DQt6OpenGL_DIR=${RUNTIME_BASE}/Qt6OpenGL"
  "-DQt6OpenGLWidgets_DIR=${RUNTIME_BASE}/Qt6OpenGLWidgets"
  "-DQt6Core5Compat_DIR=${RUNTIME_BASE}/Qt6Core5Compat"
  "-DQt6UiTools_DIR=${RUNTIME_BASE}/Qt6UiTools"
  "-DQt6Designer_DIR=${RUNTIME_BASE}/Qt6Designer"
  "-DQt6Help_DIR=${RUNTIME_BASE}/Qt6Help"
)

# --- Qt6 QML/Quick 与 WebEngine 模块 (位于 /runtime) ---
CMAKE_OPTS+=(
  "-DQt6Qml_DIR=${RUNTIME_BASE}/Qt6Qml"
  "-DQt6Quick_DIR=${RUNTIME_BASE}/Qt6Quick"
  "-DQt6QuickWidgets_DIR=${RUNTIME_BASE}/Qt6QuickWidgets"
  "-DQt6WebChannel_DIR=${RUNTIME_BASE}/Qt6WebChannel"
  "-DQt6Positioning_DIR=${RUNTIME_BASE}/Qt6Positioning"
  "-DQt6WebEngineCore_DIR=${RUNTIME_BASE}/Qt6WebEngineCore"
  "-DQt6WebEngineWidgets_DIR=${RUNTIME_BASE}/Qt6WebEngineWidgets"
  "-DQt6WebEngineQuick_DIR=${RUNTIME_BASE}/Qt6WebEngineQuick"
)

# --- Qt6 扩展与 3D 模块 (由应用提供，位于 APP_CMAKE_DIR) ---
CMAKE_OPTS+=(
  "-DQt6SerialPort_DIR=${APP_BASE}/Qt6SerialPort"
  "-DQt63DCore_DIR=${APP_BASE}/Qt63DCore"
  "-DQt63DRender_DIR=${APP_BASE}/Qt63DRender"
  "-DQt63DInput_DIR=${APP_BASE}/Qt63DInput"
  "-DQt63DLogic_DIR=${APP_BASE}/Qt63DLogic"
  "-DQt63DAnimation_DIR=${APP_BASE}/Qt63DAnimation"
  "-DQt63DExtras_DIR=${APP_BASE}/Qt63DExtras"
  "-DQt63DQuick_DIR=${APP_BASE}/Qt63DQuick"
  "-DQt63DQuickRender_DIR=${APP_BASE}/Qt63DQuickRender"
)

# --- 插件安装路径 ---
CMAKE_OPTS+=(
  "-DQT_PLUGINS_DIR=lib/${TRIPLET}/qt6/plugins"
)