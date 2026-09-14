#!/usr/bin/env bash
# dunst-pause - 免打扰（暂停 / 恢复 dunst 通知）
# 由 settings/lib/toggles.sh 调用。子命令: label | default | apply <0|1> [settle]
# 状态: 1=开=暂停通知(免打扰)  0=关=正常通知
#
# 说明：
#   开启时不给提示——暂停会立刻收起通知，提示看不到，没意义。
#   关闭时先丢弃暂停期间积压的通知再恢复（否则恢复瞬间会把旧通知一次性弹出）。
#   提示由菜单统一发出；本脚本只负责套用。

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
    # 仅在确实处于暂停状态时才丢弃积压——否则会误关正在显示的通知
    # （如主题切换后 bspwmrc 重套开关时，把刚弹的"已切换主题"关掉）
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
