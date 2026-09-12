#!/usr/bin/env bash
# 快捷键速查脚本
# 用法:
#   setting-keybindings.sh      交互式查看（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 只维护 SHORTCUTS 关联数组（[键位]=描述），命令从 sxhkdrc 自动查得并展开花括号。
# 展示顺序沿用 sxhkdrc 里的顺序。纯查看，回车/Esc 关闭。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"
SXHKD_CONF="$DOTFILES_DIR/desktop/bspwm/sxhkdrc"
SXHKD_CMD="$DOTFILES_DIR/settings/lib/sxhkd-shortcuts.py"

# 加载公共函数(含 epipe_init)并初始化 stdout 安全
source "$DOTFILES_DIR/settings/lib/selectors.sh"
epipe_init

# 精选快捷键: [键位]=描述。键位用 sxhkd 语法（从 sxhkdrc 拷过来即可）。
declare -A SHORTCUTS=(
  ["super + semicolon"]="设置菜单"
  ["super + Return"]="打开终端"
  ["super + w"]="关闭窗口"
  ["super + f"]="全屏"
  ["super + alt + q"]="退出重启"
  ["super + alt + r"]="重载窗口管理"
  ["super + Escape"]="重载快捷键"
  ["Print"]="区域截图"
  ["shift + Print"]="全屏截图"
  ["super + r"]="启动应用"
  ["alt + Tab"]="切换窗口"
  ["super + e"]="文件管理器"
  ["super + m"]="音乐播放器"
  ["super + h"]="系统监控"
  ["super + v"]="剪贴板播放"
  ["super + b"]="蓝牙管理"
)

# 键位显示美化（sxhkd 语法 -> 人类可读）
prettify_key() {
  local k="$1"
  k="${k//super/Super}"
  k="${k//alt/Alt}"
  k="${k//ctrl/Ctrl}"
  k="${k//shift/Shift}"
  k="${k//semicolon/;}"
  k="${k//Print/PrtSc}"
  printf '%s' "$k"
}

# 展示并查看
show_shortcuts() {
  # 从 sxhkdrc 取命令，按文件顺序保留精选键
  local -a order=()
  local -A cmd=()
  if [ -f "$SXHKD_CONF" ] && [ -x "$SXHKD_CMD" ]; then
    local k c
    while IFS=$'\t' read -r k c; do
      [ -n "${SHORTCUTS[$k]+x}" ] || continue
      [ -n "${cmd[$k]+x}" ] && continue
      cmd["$k"]="$c"
      order+=("$k")
    done < <("$SXHKD_CMD" "$SXHKD_CONF")
  fi
  # 没在 sxhkdrc 里找到的键也保留（避免静默消失）
  local k
  for k in "${!SHORTCUTS[@]}"; do
    [ -n "${cmd[$k]+x}" ] && continue
    order+=("$k")
  done

  local rows="" kd desc
  local k
  for k in "${order[@]}"; do
    kd="$(prettify_key "$k")"
    desc="${SHORTCUTS[$k]}"
    rows+="$(printf '%s\t%s\t%s' "$kd" "$desc" "${cmd[$k]:-}")"$'\n'
  done
  rows="${rows%$'\n'}"

  # 按显示宽度补齐（中文占 2 列；bash 的 ${#} 按字符、printf 域宽按字节，都不对）
  # 字体由 rofi 主题（custom/preview）统一指定为 Maple 等宽
  local list
  list="$(printf '%s\n' "$rows" | python3 -c '
import sys, unicodedata
rows = [l.rstrip("\n").split("\t") for l in sys.stdin if l.strip()]
def w(s):
    return sum(2 if unicodedata.east_asian_width(c) in ("W", "F") else 1 for c in s)
if rows:
    kw = max(w(r[0]) for r in rows)
    dw = max(w(r[1]) for r in rows)
    for r in rows:
        k, d, c = (r + ["", "", ""])[:3]
        print(k + " " * (kw - w(k)) + "  " + d + " " * (dw - w(d)) + "  " + c)
')"

  # 纯查看：显示列表，回车/Esc 即关闭
  select_ui -p "快捷键" -d "$list" >/dev/null || true
}

main() {
  show_shortcuts
}

main "$@"
