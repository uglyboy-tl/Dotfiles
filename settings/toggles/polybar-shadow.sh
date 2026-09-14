#!/usr/bin/env bash
# polybar-shadow - 开关 Polybar 阴影
# 由 settings/lib/toggles.sh 调用。子命令: label | apply <0|1> [settle]
#
# 用 picom 的 _COMPTON_SHADOW 窗口属性实时开关（不改配置、不重启 picom）：
#   属性存在且为 0 → 无阴影；移除属性 → 恢复默认（有阴影）。
# settle 非空时反复套用数秒：bspwm 重载后 polybar 正在重建，
# "正在退出的旧窗口"和"刚起的新窗口"会短暂并存，只设一次可能落到旧窗口上而丢失。

set -euo pipefail

apply_shadow() {
  local state="$1" settle="${2:-}" i wid tries=1
  [ -n "$settle" ] && tries=20
  for i in $(seq 1 "$tries"); do
    for wid in $(xdotool search --class -- Polybar 2>/dev/null || true); do
      if [ "$state" = "1" ]; then
        xprop -id "$wid" -remove _COMPTON_SHADOW >/dev/null 2>&1 || true
      else
        xprop -id "$wid" -f _COMPTON_SHADOW 32c -set _COMPTON_SHADOW 0 >/dev/null 2>&1 || true
      fi
    done
    [ -z "$settle" ] && break
    sleep 0.2
  done
}

case "${1:-}" in
  label) printf '%s\n' "Polybar 阴影" ;;
  default) printf '%s\n' 0 ;;   # 默认无阴影
  apply) apply_shadow "${2:-1}" "${3:-}" ;;
esac
