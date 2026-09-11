#!/usr/bin/env bash
# 消息通知模块: GUI 下用桌面通知(notify-send), 否则输出到命令行。
#
# 依赖: SELECTOR_UI 变量(gui/tui, 由 selectors.sh 提供; 未设则按 tui)。
# 用法:
#   notify <消息> [标题]        普通信息
#   notify_error <消息> [标题]  错误(桌面通知用 critical 紧急度, 命令行走 stderr)
#
# 桌面通知失败(如无 DBUS/未装 notify-send)时自动回退命令行输出。

: "${SELECTOR_UI:=tui}"

_notify_impl() {
  local urgency="$1"; shift
  local msg="$1" title="${2:-设置}"

  # GUI 优先尝试桌面通知, 失败则回退命令行(不中断调用方)
  if [ "$SELECTOR_UI" = gui ] && command -v notify-send >/dev/null 2>&1 \
     && notify-send -u "$urgency" "$title" "$msg"; then
    return 0
  fi

  if [ "$urgency" = critical ]; then
    echo "$msg" >&2
  else
    echo "$msg"
  fi
}

notify()       { _notify_impl normal   "$@"; }
notify_error() { _notify_impl critical "$@"; }
