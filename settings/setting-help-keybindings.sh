#!/usr/bin/env bash
# 快捷键界面：列出精选快捷键，选中即执行对应命令（仿 Omarchy 的 keybindings 菜单）
# 用法:
#   setting-help-keybindings.sh            交互式（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#   setting-help-keybindings.sh --gui      强制用 rofi（桌面快捷键直启时用）
#
# 只维护 SHORTCUTS 关联数组（[键位]=描述），命令从 sxhkdrc 自动查得并展开花括号。
# 展示顺序沿用 sxhkdrc 里的顺序。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"
SXHKD_CONF="$DOTFILES_DIR/desktop/bspwm/sxhkdrc"
SXHKD_CMD="$DOTFILES_DIR/settings/lib/sxhkd-shortcuts.py"

# 记录入口是否已指定 UI（从 settings 子菜单进入时会继承 SELECTOR_UI）
_inherited_ui="${SELECTOR_UI:-}"

# 加载公共函数(含 epipe_init/select_ui/selector_gui_supported/MENU_EXIT_ALL)并初始化 stdout 安全
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/menu.sh"

# 独立运行(如快捷键直启)时默认 GUI：无继承的 SELECTOR_UI 且无终端时用 rofi
if [ -z "$_inherited_ui" ]; then
  if selector_gui_supported; then
    SELECTOR_UI=gui
  else
    SELECTOR_UI=tui
  fi
fi
# 允许 --gui / --tui 覆盖
for _arg in "$@"; do
  case "$_arg" in
    --gui) selector_gui_supported && SELECTOR_UI=gui ;;
    --tui) SELECTOR_UI=tui ;;
  esac
done
export SELECTOR_UI

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

# 生成 "显示行<TAB>命令"：显示行按 sxhkdrc 顺序、中文宽度对齐
build_rows() {
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
  for k in "${order[@]}"; do
    kd="$(prettify_key "$k")"
    desc="${SHORTCUTS[$k]}"
    rows+="$(printf '%s\t%s\t%s' "$kd" "$desc" "${cmd[$k]:-}")"$'\n'
  done
  rows="${rows%$'\n'}"

  # 按显示宽度补齐（中文占 2 列），输出 "键位+描述+命令<TAB>命令"
  printf '%s\n' "$rows" | python3 -c '
import sys, unicodedata
rows = [l.rstrip("\n").split("\t") for l in sys.stdin if l.strip()]
def w(s):
    return sum(2 if unicodedata.east_asian_width(c) in ("W", "F") else 1 for c in s)
if rows:
    kw = max(w(r[0]) for r in rows)
    dw = max(w(r[1]) for r in rows)
    for r in rows:
        k, d, c = (r + ["", "", ""])[:3]
        display = k + " " * (kw - w(k)) + "  " + d + " " * (dw - w(d)) + "  " + c
        print(display + "\t" + c)
'
}

# 展示并执行：选中项对应的命令
show_shortcuts() {
  local list="" line cmd
  declare -A RUN_CMD=()
  while IFS=$'\t' read -r line cmd; do
    [ -n "$line" ] || continue
    RUN_CMD["$line"]="$cmd"
    list+="$line"$'\n'
  done < <(build_rows)
  list="${list%$'\n'}"

  local choice
  choice=$(select_ui -p "快捷键（回车执行）" -d "$list") || exit 0
  [ -n "$choice" ] || exit 0
  cmd="${RUN_CMD[$choice]:-}"
  [ -n "$cmd" ] || exit 0

  # 后台执行，脱离本进程（GUI 程序/窗口管理命令均适用）
  setsid bash -c "$cmd" >/dev/null 2>&1 </dev/null &
  # 通知上级菜单直接退出（不再回上级）；取消(左键/Esc)则正常返回
  exit "$MENU_EXIT_ALL"
}

main() {
  show_shortcuts
}

main "$@"