#!/bin/bash
# menu.sh - 通用菜单循环与"退出整栈"传播
# 作为函数库被 settings / setting-* 等 source（需先 source selectors.sh）。

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

  # 记住上次选中项的“位置”而非内容：内容可能随操作变化（如开关的 开/关 标签），
  # 按位置回填才能让下次打开仍高亮同一项。
  local last_idx=-1

  while true; do
    # 每轮重新生成选项：菜单项可能随状态变化
    local items choice sel="" rc=0 i=0 line
    items="$("$items_cmd")"

    # 用上次记录的位置在新列表中取回当前内容作为高亮项
    if [ "$last_idx" -ge 0 ]; then
      while IFS= read -r line; do
        if [ "$i" -eq "$last_idx" ]; then
          sel="$line"
          break
        fi
        i=$((i + 1))
      done <<< "$items"
    fi

    choice=$(select_ui -p "$prompt" -d "$items" -s "$sel") || return 0
    [ -n "$choice" ] || return 0

    # 记录选中项位置
    i=0
    while IFS= read -r line; do
      if [ "$line" = "$choice" ]; then
        last_idx=$i
        break
      fi
      i=$((i + 1))
    done <<< "$items"

    "$handler" "$choice" || rc=$?
    if [ "$rc" -eq "$MENU_EXIT_ALL" ]; then
      [ "$root" -eq 1 ] && exit 0 || exit "$MENU_EXIT_ALL"
    elif [ "$rc" -ne 0 ]; then
      return "$rc"
    fi
  done
}
