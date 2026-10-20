#!/bin/bash
# menu.sh - 通用菜单循环与"退出整栈"传播（需先 source selectors.sh）

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

# 子菜单返回此码表示要退出整个菜单栈；中间层原样传播，入口菜单(--root)捕获后以 0 退出。
MENU_EXIT_ALL=10

# 通用菜单循环：menu_loop <提示> <选项命令> <处理函数> [--root]
menu_loop() {
  local root=0 prompt="$1" items_cmd="$2" handler="$3"
  shift 3
  [ "${1:-}" = "--root" ] && root=1

  # 记住上次选中项的“位”而非内容：内容会随状态变（如开关的开/关标签）。
  local last_idx=-1

  while true; do
    local items choice sel="" rc=0
    items="$("$items_cmd")"

    [ "$last_idx" -ge 0 ] && _list_line_at sel "$items" "$last_idx"

    choice=$(select_ui -p "$prompt" -d "$items" -s "$sel") || return 0
    [ -n "$choice" ] || return 0

    _list_index_of last_idx "$items" "$choice"

    "$handler" "$choice" || rc=$?
    if [ "$rc" -eq "$MENU_EXIT_ALL" ]; then
      [ "$root" -eq 1 ] && exit 0 || exit "$MENU_EXIT_ALL"
    elif [ "$rc" -ne 0 ]; then
      return "$rc"
    fi
  done
}
