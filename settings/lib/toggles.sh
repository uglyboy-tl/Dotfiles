#!/usr/bin/env bash
# toggles.sh - 布尔开关引擎（通用，不含任何具体功能）
# 作为函数库被 source：菜单 setting-toggles.sh、以及 bspwmrc 的启动套用。
#
# 约定：每个开关是 settings/toggles/<key>.sh 下的一个可执行脚本，实现三个子命令：
#   label                 打印显示名
#   default               打印"未选择时"的默认状态（0/1），缺省视为 1
#   apply <0|1> [settle]  按给定状态套用（settle 非空时用于骑过窗口重建，可忽略）
# 状态由本引擎持有：$XDG_STATE_HOME/settings/toggles/<key>（1=开 0=关），无文件时用脚本的 default。

# 防止重复加载
[[ -n "${_TOGGLES_LOADED:-}" ]] && return 0
_TOGGLES_LOADED=1

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${DOTFILES_DIR:=$XDG_DATA_HOME/dotfiles}"

TOGGLES_DIR="${TOGGLES_DIR:-$DOTFILES_DIR/settings/toggles}"
TOGGLE_STATE_DIR="${TOGGLE_STATE_DIR:-$XDG_STATE_HOME/settings/toggles}"

# 所有开关 key（脚本文件名去 .sh），按名称排序
toggles_keys() {
  local f
  for f in "$TOGGLES_DIR"/*.sh; do
    [ -e "$f" ] || continue
    basename "$f" .sh
  done
}

toggle_script() { printf '%s/%s.sh\n' "$TOGGLES_DIR" "$1"; }

toggle_label() { "$(toggle_script "$1")" label 2>/dev/null; }

# 默认状态：取自开关脚本的 `default` 子命令，缺省/非法时视为 1
toggles_default() {
  local d
  d="$("$(toggle_script "$1")" default 2>/dev/null)" || true
  case "$d" in 0 | 1) printf '%s\n' "$d" ;; *) echo 1 ;; esac
}

# 当前状态（1=开 0=关），无状态文件时用默认
toggle_state() {
  local f="$TOGGLE_STATE_DIR/$1"
  if [ -f "$f" ]; then cat "$f"; else toggles_default "$1"; fi
}

# 套用（不写状态）：<key> <0|1> [settle]；失败静默（如 polybar 未运行，下次再套）
toggle_apply() {
  local key="$1" state="$2" settle="${3:-}"
  "$(toggle_script "$key")" apply "$state" ${settle:+"$settle"} 2>/dev/null || true
}

# 设置并持久化：<key> <0|1> [settle]
toggle_set() {
  local key="$1" state="$2" settle="${3:-}"
  mkdir -p "$TOGGLE_STATE_DIR"
  printf '%s\n' "$state" > "$TOGGLE_STATE_DIR/$key"
  toggle_apply "$key" "$state" ${settle:+"$settle"}
}

# 翻转并输出新状态：<key>
toggle_flip() {
  local key="$1" cur new
  cur="$(toggle_state "$key")"
  if [ "$cur" = "1" ]; then new=0; else new=1; fi
  toggle_set "$key" "$new"
  printf '%s\n' "$new"
}

# 按已保存状态套用全部开关：[settle]（启动/重载用，不产生任何提示）
toggles_apply_all() {
  local settle="${1:-}" key
  for key in $(toggles_keys); do
    toggle_apply "$key" "$(toggle_state "$key")" ${settle:+"$settle"}
  done
}
