#!/bin/bash
# render.sh - 从 colors.toml 渲染模板生成颜色配置文件
# 用法: render.sh <colors.toml> <template.tpl> <output>

set -euo pipefail

# ============================================================
# 常量
# ============================================================

# 派生变量映射: "派生变量名:源变量名"（omarchy 规范）
declare -A DERIVED_VARS=(
  ["selection_background"]="selection"
  ["selection_foreground"]="bright_foreground"
)

# ============================================================
# 函数
# ============================================================

# 从 colors.toml 构建 sed 替换规则
build_sed_script() {
  local sed_script=""
  declare -A colors_values
  local key value

  while IFS='=' read -r key value; do
    # 跳过注释和空行
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    # 清理 key 和 value（去掉首尾空白和引号）
    key="${key//[[:space:]]/}"
    value="${value//[[:space:]]/}"
    value="${value//\"/}"

    # 跳过非颜色值（不以 # 开头的值）
    [[ "$value" != \#* ]] && continue

    # 保存值（供派生变量使用）并生成替换规则
    colors_values["$key"]="$value"
    sed_script+="s|{{ ${key} }}|${value}|g; "

    # 生成去 # 的派生规则（omarchy 的 {{ key_strip }} 语法）
    value_strip="${value#\#}"
    sed_script+="s|{{ ${key}_strip }}|${value_strip}|g; "
  done < "$COLORS_FILE"

  # 添加派生变量
  for derived in "${!DERIVED_VARS[@]}"; do
    local source_var="${DERIVED_VARS[$derived]}"
    if [[ -n "${colors_values[$source_var]:-}" ]]; then
      sed_script+="s|{{ ${derived} }}|${colors_values[$source_var]}|g; "
    fi
  done

  echo "$sed_script"
}

# ============================================================
# 主逻辑
# ============================================================

# 校验参数
if [ $# -ne 3 ]; then
  echo "用法: render.sh <colors.toml> <template.tpl> <output>" >&2
  exit 1
fi

COLORS_FILE="$1"
TEMPLATE_FILE="$2"
OUTPUT_FILE="$3"

if [ ! -f "$COLORS_FILE" ]; then
  echo "错误: colors.toml 不存在: $COLORS_FILE" >&2
  exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "错误: 模板文件不存在: $TEMPLATE_FILE" >&2
  exit 1
fi

# 构建并校验 sed 脚本
SED_SCRIPT="$(build_sed_script)"
if [ -z "$SED_SCRIPT" ]; then
  echo "错误: colors.toml 中没有找到颜色定义" >&2
  exit 1
fi

# 渲染输出
mkdir -p "$(dirname "$OUTPUT_FILE")"
sed "$SED_SCRIPT" "$TEMPLATE_FILE" > "$OUTPUT_FILE"
echo "已渲染: $OUTPUT_FILE"
