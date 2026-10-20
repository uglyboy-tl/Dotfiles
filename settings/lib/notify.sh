#!/usr/bin/env bash
# notify.sh - 消息通知：GUI 下用 notify-send 桌面通知，否则输出到命令行。
# 依赖 selectors.sh 提供的 SELECTOR_UI（未设按 tui）；桌面通知失败时自动回退命令行。

: "${SELECTOR_UI:=tui}"

_notify_impl() {
  local urgency="$1"; shift
  local msg="$1" title="${2:-设置}"

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
