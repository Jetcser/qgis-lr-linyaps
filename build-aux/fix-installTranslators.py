import os
import sys

def replace_function_body(target_file, patch_file):
    # 1. 检查文件是否存在
    if not os.path.exists(target_file):
        print(f"失败：找不到目标文件 {target_file}")
        return
    if not os.path.exists(patch_file):
        print(f"失败：找不到补丁文件 {patch_file}")
        return

    # 2. 读取补丁内容
    with open(patch_file, 'r', encoding='utf-8') as f:
        patch_content = f.read().strip()

    # 3. 读取原文件内容
    with open(target_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 4. 定位函数起始行
    target_func = "void QgsApplication::installTranslators()"
    start_idx = -1
    for i, line in enumerate(lines):
        if target_func in line:
            start_idx = i
            break

    if start_idx == -1:
        print(f"失败：在文件中未找到函数 {target_func}")
        return

    # 5. 智能匹配大括号范围
    brace_count = 0
    end_idx = -1
    found_first_brace = False

    for i in range(start_idx, len(lines)):
        line = lines[i]
        # 统计当前行的大括号
        brace_count += line.count('{')
        if '{' in line:
            found_first_brace = True
        
        brace_count -= line.count('}')
        
        # 当找到起始大括号且计数器归零，说明函数块结束
        if found_first_brace and brace_count == 0:
            end_idx = i
            break

    # 6. 执行整体替换
    if end_idx != -1:
        # 将原函数内容替换为补丁内容
        # 注意：这里会替换掉从函数名所在行到结束大括号的所有内容
        new_content = lines[:start_idx] + [patch_content + '\n'] + lines[end_idx + 1:]
        
        with open(target_file, 'w', encoding='utf-8') as f:
            f.writelines(new_content)
        print(f">>> 已完成 installTranslators 函数修正 (目标: {target_file})")
    else:
        print(f"警告：定位 installTranslators 函数结束位置失败...")

if __name__ == "__main__":
    # 检查命令行参数数量
    if len(sys.argv) != 3:
        print("用法错误！")
        print("正确用法: python3 fix-installTranslators.py <目标CPP文件> <补丁TXT文件>")
        sys.exit(1)

    # 从命令行获取参数
    target_cpp_path = sys.argv[1]
    patch_txt_path = sys.argv[2]

    # 运行替换逻辑
    replace_function_body(target_cpp_path, patch_txt_path)