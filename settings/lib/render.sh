#!/bin/bash
# render.sh - 从 colors.toml 渲染模板生成颜色配置文件
# 作为函数库被其他脚本 source

# 防止重复加载
[[ -n "${_RENDER_LOADED:-}" ]] && return 0
_RENDER_LOADED=1

# 颜色派生规则。colors.toml 只声明上游真实存在的色值（16 个 ANSI 槽 +
# background/foreground/selection_*），UI 专用色（暗底、次要文字、accent 等）在这里算，
# 不由人手工填——手工填正是 colors.toml 之前出现「背景色被当次要文字色」的根因。
#
# 语法："<派生键>=<表达式>"，表达式三选一：
#   @<键>                    直接取另一个键
#   scale:<键>:<百分比>       亮度等比缩放（<100 变暗、>100 变亮；RGB 等比=保色相）
#   mix:<键A>:<键B>:<百分比>   从 A 向 B 混合，百分比指 B 的权重（0-100）
# 操作数写 #rrggbb 字面量也可以（如 light_foreground 里的 #ffffff）。
# colors.toml 里已声明的同名键优先，派生不覆盖。
#
# 缩放系数 80/57/130 是按主流主题（Catppuccin mantle/crust、Nord nord1/2、
# Gruvbox Material bg_dim、Tokyo Night bg_dark）反推出来的。
# orange 取 red/yellow 中点，与 Omarchy 全部 6 个主题的 orange 实测 dE00 < 0.5。
# muted 在 bright_black 基础上向 foreground 提 25%：muted 只服务于 GUI 禁
# 用态文字（GTK insensitive_fg_color 等），直接用 bright_black 在 Nord/Oxocarbon
# 上只有 1.6:1，禁用态文字完全读不出来。ANSI 8 槽不经过 muted，走 bright_black。
RENDER_DERIVED=(
  "dark_background=scale:background:80"
  "darker_background=scale:background:57"
  "lighter_background=scale:background:130"
  "dark_foreground=mix:foreground:background:42"
  "light_foreground=mix:foreground:#ffffff:30"
  "muted=mix:bright_black:foreground:25"
  "accent=@blue"
  "orange=mix:red:yellow:50"
  "selection=@selection_background"
)

# 十六进制颜色运算（逐通道 RGB，不做感知空间转换：够用且零外部依赖）
# 结果写入变量 $1
_render_hex_scale() { # <#rrggbb> <百分比>
  local hex="${2#\#}" pct="$3" r g b
  r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
  r=$(((r * pct + 50) / 100)); g=$(((g * pct + 50) / 100)); b=$(((b * pct + 50) / 100))
  ((r > 255)) && r=255; ((g > 255)) && g=255; ((b > 255)) && b=255
  printf -v "$1" '#%02x%02x%02x' "$r" "$g" "$b"
}

_render_hex_mix() { # <#rrggbb A> <#rrggbb B> <B 的百分比>
  local ha="${2#\#}" hb="${3#\#}" pct="$4" r g b
  local ar=$((16#${ha:0:2})) ag=$((16#${ha:2:2})) ab=$((16#${ha:4:2}))
  local br=$((16#${hb:0:2})) bg=$((16#${hb:2:2})) bb=$((16#${hb:4:2}))
  r=$(((ar * (100 - pct) + br * pct + 50) / 100))
  g=$(((ag * (100 - pct) + bg * pct + 50) / 100))
  b=$(((ab * (100 - pct) + bb * pct + 50) / 100))
  printf -v "$1" '#%02x%02x%02x' "$r" "$g" "$b"
}

# 把 RENDER_DERIVED 里还没被声明过的键算出来，写进 nameref 指向的关联数组
_render_apply_derived() {
  local -n _vals="$1"
  local rule name expr op a1 a2 a3 c1 c2
  for rule in "${RENDER_DERIVED[@]}"; do
    name="${rule%%=*}"
    expr="${rule#*=}"
    [[ -n "${_vals[$name]:-}" ]] && continue
    op="${expr%%:*}"
    if [[ "$expr" == @* ]]; then
      _vals["$name"]="${_vals[${expr#@}]:-}"
      continue
    fi
    IFS=':' read -r op a1 a2 a3 <<< "$expr"
    case "$op" in
      scale)
        [[ -n "${_vals[$a1]:-}" ]] && _render_hex_scale "_vals[$name]" "${_vals[$a1]}" "$a2"
        ;;
      mix)
        c1="$a1"; [[ "$c1" != \#* ]] && c1="${_vals[$a1]:-}"
        c2="$a2"; [[ "$c2" != \#* ]] && c2="${_vals[$a2]:-}"
        [[ -n "$c1" && -n "$c2" ]] && _render_hex_mix "_vals[$name]" "$c1" "$c2" "$a3"
        ;;
    esac
  done
}

# 转义替换串中的 sed 特殊字符（\ & |），结果写入变量 $1（避免子 shell）
_render_escape_var() {
  local v="$2"
  v="${v//\\/\\\\}"
  v="${v//&/\\&}"
  v="${v//|/\\|}"
  printf -v "$1" '%s' "$v"
}

# 从 colors.toml 构建 sed 替换规则
render_build_sed_script() {
  local colors_file="$1"
  local sed_script=""
  local -A colors_values
  local key value esc

  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[[:space:]]*[#\;] ]] && continue
    [[ -z "$key" ]] && continue

    key="${key//[[:space:]]/}"
    value="${value//\"/}"

    # 只取首个 #rrggbb[aa]；行尾跟的 `# 注释` 也就在这一步被切掉
    if [[ "$value" =~ (\#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?) ]]; then
      colors_values["$key"]="${BASH_REMATCH[1]}"
    fi
  done < "$colors_file"

  _render_apply_derived colors_values

  for key in "${!colors_values[@]}"; do
    value="${colors_values[$key]}"
    _render_escape_var esc "$value"
    sed_script+="s|{{ ${key} }}|${esc}|g; "
    _render_escape_var esc "${value#\#}"
    sed_script+="s|{{ ${key}_strip }}|${esc}|g; "
  done

  printf '%s' "$sed_script"
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

  # 模板里引用但 colors.toml/派生规则都没提供的变量会原样留下——直接报出来，
  # 否则只会静默渲染出字面的 "{{ foo }}" 写进应用配置
  local undefined
  undefined="$(grep -o '{{ [a-z_]* }}' "$output_file" 2>/dev/null | sort -u || true)"
  if [ -n "$undefined" ]; then
    echo "错误: 模板 $template_file 引用了未定义的变量:" >&2
    # 变量名里含空格，不能直接印 $undefined（会被 IFS 切碎成 `{{ / foo / }}` 六行）
    while IFS= read -r v; do printf '  %s\n' "$v" >&2; done <<< "$undefined"
    return 1
  fi
}
