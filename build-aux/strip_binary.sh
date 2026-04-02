#!/bin/bash

set -e

# --- 配置路径 ---
INSTALL_ROOT="${PREFIX}"

echo "正在按照 Debian 标准执行资源剥离..."
echo "--------------------------------------------------"

# 使用 find 扫描所有文件
find "$INSTALL_ROOT" -type f | while read -r FILE; do
    # 使用 file 命令识别 ELF 类型
    FTYPE=$(file "$FILE")
    
    if echo "$FTYPE" | grep -q "ELF"; then
        # 获取原始大小
        OLD_SIZE=$(du -b "$FILE" | cut -f1)

        # --- 逻辑 A: 如果是共享库 (Shared object) ---
        # Debian 逻辑: --strip-unneeded (保留动态符号表以供链接)
        if echo "$FTYPE" | grep -q "shared object"; then
            strip --remove-section=.comment --remove-section=.note --strip-unneeded "$FILE"
            echo "Stripped Library: $(basename "$FILE")"

        # --- 逻辑 B: 如果是可执行文件 (Executable) ---
        # Debian 逻辑: --strip-all (移除所有符号，因为不需要被他人链接)
        elif echo "$FTYPE" | grep -q "executable"; then
            strip --remove-section=.comment --remove-section=.note --strip-all "$FILE"
            echo "Stripped Executable: $(basename "$FILE")"
            
        # --- 逻辑 C: 如果是静态库 (Relocatable / Static archive) ---
        # Debian 逻辑: --strip-debug (只移除调试段)
        elif echo "$FTYPE" | grep -q "relocatable"; then
            strip --strip-debug "$FILE"
            echo "Stripped Object: $(basename "$FILE")"
        fi

        # 计算压缩率
        NEW_SIZE=$(du -b "$FILE" | cut -f1)
        PERCENT=$(( 100 - (NEW_SIZE * 100 / OLD_SIZE) ))
        echo "  空间释放: ${PERCENT}% ($((OLD_SIZE/1024))KB -> $((NEW_SIZE/1024))KB)"
    fi
done

echo "--------------------------------------------------"
echo "二进制符号剥离完成！"