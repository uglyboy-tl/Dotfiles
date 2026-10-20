#!/usr/bin/env bash
# dunst-pause - 免打扰（暂停 / 恢复 dunst 通知）
# 子命令: label | default | apply <0|1> [settle]；状态 1=开=暂停通知(免打扰) 0=关=正常通知

set -euo pipefail

# 带重试设置暂停状态（settle 时多试几次，等 dunst 就绪）
_set_paused() {
  local val="$1" settle="${2:-}" i tries=1
  [ -n "$settle" ] && tries=15
  for i in $(seq 1 "$tries"); do
    dunstctl set-paused "$val" >/dev/null 2>&1 && break
    sleep 0.2
  done
}

apply_dnd() {
  local state="$1" settle="${2:-}"
  if [ "$state" = "1" ]; then
    _set_paused true "$settle"
  else
    # 仅在确实处于暂停状态时才丢弃积压，否则会误关正在显示的通知
    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
      dunstctl close-all >/dev/null 2>&1 || true
    fi
    _set_paused false "$settle"
  fi
}

case "${1:-}" in
  label) printf '%s\n' "免打扰" ;;
  default) printf '%s\n' 0 ;; # 默认不静音（正常通知）
  apply) apply_dnd "${2:-1}" "${3:-}" ;;
esac
