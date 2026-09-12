#!/bin/bash
# render.sh - 从 colors.toml 渲染模板生成颜色配置文件
# 作为函数库被其他脚本 source

# 防止重复加载
[[ -n "${_RENDER_LOADED:-}" ]] && return 0
_RENDER_LOADED=1

# 派生变量映射: "派生变量名:源变量名"（omarchy 规范）
declare -A RENDER_DERIVED_VARS=(
  ["selection_background"]="selection"
  ["selection_foreground"]="bright_foreground"
)

# 从 colors.toml 构建 sed 替换规则
render_build_sed_script() {
  local colors_file="$1"
  local sed_script=""
  declare -A colors_values
  local key value

  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    key="${key//[[:space:]]/}"
    value="${value//[[:space:]]/}"
    value="${value//\"/}"

    [[ "$value" != \#* ]] && continue

    colors_values["$key"]="$value"
    sed_script+="s|{{ ${key} }}|${value}|g; "

    value_strip="${value#\#}"
    sed_script+="s|{{ ${key}_strip }}|${value_strip}|g; "
  done < "$colors_file"

  for derived in "${!RENDER_DERIVED_VARS[@]}"; do
    local source_var="${RENDER_DERIVED_VARS[$derived]}"
    if [[ -n "${colors_values[$source_var]:-}" ]]; then
      sed_script+="s|{{ ${derived} }}|${colors_values[$source_var]}|g; "
    fi
  done

  echo "$sed_script"
}

# 渲染模板
# 用法: render <colors.toml> <template.tpl> <output>
render() {
  if [ $# -ne 3 ]; then
    echo "用法: render <colors.toml> <template.tpl> <output>" >&2
    return 1
  fi

  local colors_file="$1"
  local template_file="$2"
  local output_file="$3"

  if [ ! -f "$colors_file" ]; then
    echo "错误: colors.toml 不存在: $colors_file" >&2
    return 1
  fi

  if [ ! -f "$template_file" ]; then
    echo "错误: 模板文件不存在: $template_file" >&2
    return 1
  fi

  local sed_script
  sed_script="$(render_build_sed_script "$colors_file")"
  if [ -z "$sed_script" ]; then
    echo "错误: colors.toml 中没有找到颜色定义" >&2
    return 1
  fi

  mkdir -p "$(dirname "$output_file")"
  sed "$sed_script" "$template_file" > "$output_file"
}
