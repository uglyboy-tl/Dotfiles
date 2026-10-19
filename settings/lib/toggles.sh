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

# 标签与默认状态是开关脚本的静态属性，缓存起来：菜单每次重绘都要它们，
# 不缓存的话每个开关每帧都要 fork 一次脚本（原先一帧 = 2-3 次 spawn/开关）。
# 状态文件不存在时才会读默认值，所以默认值也值得缓存。
declare -A _TOGGLE_LABEL_CACHE=() _TOGGLE_DEFAULT_CACHE=()

toggle_label() {
  local key="$1"
  [[ -n "${_TOGGLE_LABEL_CACHE[$key]:-}" ]] ||
    _TOGGLE_LABEL_CACHE["$key"]="$("$(toggle_script "$key")" label 2>/dev/null)"
  printf '%s\n' "${_TOGGLE_LABEL_CACHE[$key]}"
}

# 默认状态：取自开关脚本的 `default` 子命令，缺省/非法时视为 1
toggles_default() {
  local key="$1" d
  if [[ -z "${_TOGGLE_DEFAULT_CACHE[$key]+x}" ]]; then
    d="$("$(toggle_script "$key")" default 2>/dev/null)" || true
    case "$d" in 0 | 1) _TOGGLE_DEFAULT_CACHE["$key"]="$d" ;; *) _TOGGLE_DEFAULT_CACHE["$key"]=1 ;; esac
  fi
  printf '%s\n' "${_TOGGLE_DEFAULT_CACHE[$key]}"
}

# 预热标签/默认值缓存。必须在**父 shell** 里调用：菜单里常见的 `x="$(toggle_label k)"`
# 会把缓存写进子 shell，父 shell 拿不到，逐帧重绘等于每帧重新 fork 一遍开关脚本。
toggles_warm_cache() {
  local key label d
  while IFS= read -r key; do
    if [[ -z "${_TOGGLE_LABEL_CACHE[$key]:-}" ]]; then
      label="$("$(toggle_script "$key")" label 2>/dev/null)" || true
      _TOGGLE_LABEL_CACHE["$key"]="$label"
    fi
    if [[ -z "${_TOGGLE_DEFAULT_CACHE[$key]+x}" ]]; then
      d="$("$(toggle_script "$key")" default 2>/dev/null)" || true
      case "$d" in 0 | 1) _TOGGLE_DEFAULT_CACHE["$key"]="$d" ;; *) _TOGGLE_DEFAULT_CACHE["$key"]=1 ;; esac
    fi
  done < <(toggles_keys)
}

# 菜单快照：每个开关一行 `<key>\t<标签>\t<状态>`（制表符分隔——标签是人写的，可能含空格/冒号）。
# 这是菜单每帧要的全部信息，一次给全；标签走缓存、状态是文件读取，所以除了调用方那一次
# `$(toggles_lines)` 不再有子 shell。冷缓存时逐个回退到脚本，不会给出空标签。
toggles_lines() {
  local key label st state_file
  while IFS= read -r key; do
    label="${_TOGGLE_LABEL_CACHE[$key]:-}"
    [ -n "$label" ] || label="$("$(toggle_script "$key")" label 2>/dev/null)"
    state_file="$TOGGLE_STATE_DIR/$key"
    if [ -f "$state_file" ]; then
      read -r st < "$state_file" || true
    else
      st="${_TOGGLE_DEFAULT_CACHE[$key]:-1}"
    fi
    printf '%s\t%s\t%s\n' "$key" "$label" "$st"
  done < <(toggles_keys)
}

# 当前状态（1=开 0=关），无状态文件时用默认
# 用 read 而不是 $(cat)：菜单每次重绘都逐项问一次，cat 是外部命令（多一次 fork）
toggle_state() {
  local f="$TOGGLE_STATE_DIR/$1" st
  if [ -f "$f" ]; then
    read -r st < "$f" || true
    printf '%s\n' "$st"
  else
    toggles_default "$1"
  fi
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
  local -a keys=()
  mapfile -t keys < <(toggles_keys)
  for key in "${keys[@]}"; do
    toggle_apply "$key" "$(toggle_state "$key")" ${settle:+"$settle"}
  done
}
