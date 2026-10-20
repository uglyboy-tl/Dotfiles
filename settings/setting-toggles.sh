#!/usr/bin/env bash
# setting-toggles.sh - 开关设置子菜单（纯菜单 UI，只负责列出/选择/翻转）
# 具体开关见 settings/toggles/，引擎见 settings/lib/toggles.sh。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

# 记录入口是否已指定 UI（从 settings 子菜单进入时会继承 SELECTOR_UI）
_inherited_ui="${SELECTOR_UI:-}"

source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/menu.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
source "$DOTFILES_DIR/settings/lib/toggles.sh"

# 独立运行（快捷键直启）时默认 GUI
if [ -z "$_inherited_ui" ]; then
  if selector_gui_supported; then SELECTOR_UI=gui; else SELECTOR_UI=tui; fi
fi
export SELECTOR_UI
epipe_init

# 菜单条目：标签 + 当前状态（元数据全部来自 toggles_lines）
get_items() {
  local key label st mark
  while IFS=$'\t' read -r key label st; do
    if [ "$st" = "1" ]; then mark="开"; else mark="关"; fi
    printf '%s：%s\n' "$label" "$mark"
  done < <(toggles_lines)
}

# 选中即翻转：条目形如「<标签>：<开|关>」，去掉尾部状态后按标签找 key
handle() {
  local choice="$1" label key="" k l new
  label="${choice%：*}"
  while IFS=$'\t' read -r k l _; do
    if [ "$l" = "$label" ]; then key="$k"; fi
  done < <(toggles_lines)
  [ -n "$key" ] || return 0
  new="$(toggle_flip "$key")"
  if [ "$new" = "1" ]; then notify "已开启：$label"; else notify "已关闭：$label"; fi
}

menu_loop "开关" get_items handle
