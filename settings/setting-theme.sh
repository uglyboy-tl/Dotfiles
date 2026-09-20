#!/usr/bin/env bash
# 主题切换（设置项：选择 → 校验 → 应用）
# 用法:
#   setting-theme.sh <主题名>   直接切换到指定主题（单次）
#   setting-theme.sh            交互式选择/循环切换（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 渲染声明与数据在 themes/（render.conf 声明「应用 ← 模板 → 输出/重载」，templates/、colors/）。
# 本脚本只在菜单里被调用，没有非 UI 复用方，故套用逻辑就近放在此处（不单独抽库）。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/render.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
epipe_init

COLORS_DIR="$DOTFILES_DIR/themes/colors"
TEMPLATES_DIR="$DOTFILES_DIR/themes/templates"
RENDER_CONF="$DOTFILES_DIR/themes/render.conf"
STATE_FILE="$XDG_STATE_HOME/theme/current"

# ============================================================
# 主题数据
# ============================================================

get_themes() {
  [ -d "$COLORS_DIR" ] || return 0
  find "$COLORS_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
}

get_current_theme() {
  [ -f "$STATE_FILE" ] && cat "$STATE_FILE"
}

save_current_theme() {
  mkdir -p "$(dirname "$STATE_FILE")"
  printf '%s\n' "$1" > "$STATE_FILE"
}

validate_theme() {
  if [ ! -d "$COLORS_DIR/$1" ]; then
    notify_error "主题 '$1' 不存在，已忽略"
    return 1
  fi
  if [ ! -f "$COLORS_DIR/$1/colors.toml" ]; then
    notify_error "主题 '$1' 缺少 colors.toml，已忽略"
    return 1
  fi
  return 0
}

# ============================================================
# 渲染 / 重载（读 themes/render.conf）
# ============================================================

# 遍历 render.conf 数据行，回调: <回调> <应用> <模板> <输出> <重载> <标记> [追加参数...]
_for_each_target() {
  local callback="$1"
  shift
  local app tmpl out reload flags
  [ -f "$RENDER_CONF" ] || return 1
  while IFS='|' read -r app tmpl out reload flags; do
    case "$app" in '' | '#'*) continue ;; esac
    "$callback" "$app" "$tmpl" "$out" "$reload" "$flags" "$@"
  done < "$RENDER_CONF"
}

# 渲染一行（跳过未装应用；`always` 标记除外）
# 输出路径默认相对 XDG_CONFIG_HOME，`data:` 前缀相对 XDG_DATA_HOME
_render_one() {
  local app="$1" tmpl="$2" out="$3" reload="$4" flags="$5" theme="$6" src dst
  [[ ",$flags," == *",always,"* ]] || command -v "$app" >/dev/null 2>&1 || return 0
  src="$TEMPLATES_DIR/$tmpl"
  case "$out" in
    data:*) dst="$XDG_DATA_HOME/${out#data:}" ;;
    *)      dst="$XDG_CONFIG_HOME/$out" ;;
  esac
  if [ -f "$src" ]; then
    render "$COLORS_DIR/$theme/colors.toml" "$src" "$dst"
    RENDERED=$((RENDERED + 1))
  fi
}

render_templates() {
  RENDERED=0
  _for_each_target _render_one "$1"
  [ "$RENDERED" -gt 0 ]
}

# 重载一行
_reload_one() {
  local app="$1" tmpl="$2" out="$3" reload="$4" flags="$5"
  [ -n "$reload" ] || return 0
  command -v "${reload%% *}" >/dev/null 2>&1 || return 0
  sh -c "$reload" >/dev/null 2>&1 || true
}

reload_apps() { _for_each_target _reload_one; }

# 等 dunst 重启就绪：bspc wm -r 会重跑 bspwmrc 里的 (_s dunst)&，旧 dunst 稍后才被杀；
# 检测 PID 变化 + DBus 就绪后再返回，避免随后的通知被吞。
wait_dunst_ready() {
  local old_pid="$1" i j new_pid
  [ -z "$old_pid" ] && return 0
  for i in $(seq 1 15); do
    new_pid=$(pgrep -x dunst | head -n1 || true)
    if [ -n "$new_pid" ] && [ "$new_pid" != "$old_pid" ]; then
      for j in $(seq 1 20); do
        dunstctl count >/dev/null 2>&1 && return 0
        sleep 0.1
      done
      return 0
    fi
    sleep 0.1
  done
  return 0
}

# 应用主题（单次）
apply_theme() {
  local theme="$1" old_dunst_pid
  validate_theme "$theme" || return 1
  render_templates "$theme" || return 1
  save_current_theme "$theme"
  old_dunst_pid=$(pgrep -x dunst | head -n1 || true)
  reload_apps
  wait_dunst_ready "$old_dunst_pid"
  notify "已切换到主题: $theme"
}

# ============================================================
# 菜单
# ============================================================

select_theme() {
  local current
  current="$(get_current_theme)"
  THEME=$(select_ui \
    -p "当前主题：${current:-无}" \
    -d "$(get_themes)" \
    -s "$current" \
    -i "printf '%s' $COLORS_DIR/{}/preview.jpg") || exit 0
}

loop_mode() {
  while true; do
    select_theme
    apply_theme "$THEME" || continue
  done
}

main() {
  if [ "$#" -ge 1 ]; then
    apply_theme "$1"
  else
    loop_mode
  fi
}

main "$@"
