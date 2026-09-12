#!/bin/bash
# menu.sh - 通用菜单循环与"退出整栈"传播
# 作为函数库被 settings / setting-help 等 source（需先 source selectors.sh）。

# 防止重复加载
[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

# 子菜单执行了"需要退出整个菜单栈"的动作时返回此码；中间层原样向上传播，
# 入口菜单(--root)捕获后正常退出(码 0)。这样菜单只需在需要时返回该值即可。
MENU_EXIT_ALL=10

# 通用菜单循环
# 用法: menu_loop <提示> <选项命令> <处理函数> [--root]
#   <选项命令>  无参命令，输出换行分隔的选项
#   <处理函数>  接收选中项执行对应动作；返回 MENU_EXIT_ALL 可退出整栈
#   --root      入口菜单：收到 MENU_EXIT_ALL 时整体退出(码 0)，否则以该码向上传播
# 取消(左键/Esc)返回 0，交由上级继续。
menu_loop() {
  local root=0 prompt="$1" items_cmd="$2" handler="$3"
  shift 3
  [ "${1:-}" = "--root" ] && root=1

  local items last=""
  items="$("$items_cmd")"

  while true; do
    local choice rc=0
    choice=$(select_ui -p "$prompt" -d "$items" -s "$last") || return 0
    [ -n "$choice" ] || return 0

    "$handler" "$choice" || rc=$?
    if [ "$rc" -eq "$MENU_EXIT_ALL" ]; then
      [ "$root" -eq 1 ] && exit 0 || exit "$MENU_EXIT_ALL"
    elif [ "$rc" -ne 0 ]; then
      return "$rc"
    fi

    last="$choice"
  done
}
