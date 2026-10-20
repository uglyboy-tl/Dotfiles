#!/usr/bin/env bash
# polybar-float - 开关 Polybar 悬浮效果（阴影 + 毛玻璃）：设/删窗口属性 `_POLYBAR_FLAT`
# 子命令: label | apply <0|1> [settle]。picom 只在窗口重映射或 reinit 时重算，故套用后发 SIGUSR1。
set -euo pipefail

PROP=_POLYBAR_FLAT

set_float() {
  local state="$1" settle="${2:-}" i wid tries=1
  [ -n "$settle" ] && tries=20
  for i in $(seq 1 "$tries"); do
    for wid in $(xdotool search --class -- Polybar 2>/dev/null || true); do
      if [ "$state" = "1" ]; then
        xprop -id "$wid" -remove "$PROP" >/dev/null 2>&1 || true
      else
        xprop -id "$wid" -f "$PROP" 32c -set "$PROP" 1 >/dev/null 2>&1 || true
      fi
    done
    [ -z "$settle" ] && break
    sleep 0.2
  done
  # 属性落定后再让 picom 重算，否则新状态要等下一次窗口重绘才生效
  pkill -USR1 -x picom >/dev/null 2>&1 || true
}

case "${1:-}" in
  label) printf '%s\n' "Polybar 悬浮效果" ;;
  default) printf '%s\n' 0 ;;   # 默认：无阴影 + 不模糊（透明）
  apply) set_float "${2:-1}" "${3:-}" ;;
esac
