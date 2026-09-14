#!/usr/bin/env bash
# 开关设置：布尔型设置的统一子菜单（纯菜单 UI）
# 用法:
#   setting-toggles.sh            交互式（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 具体开关见 settings/toggles/，引擎见 settings/lib/toggles.sh。
# 本脚本只负责"列出 / 选择 / 翻转"，不含任何具体功能；新增开关无需改动本文件。

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

# 菜单条目：标签 + 当前状态
get_items() {
  local key mark
  for key in $(toggles_keys); do
    [ "$(toggle_state "$key")" = "1" ] && mark="开" || mark="关"
    printf '%s：%s\n' "$(toggle_label "$key")" "$mark"
  done
}

# 选中即翻转
handle() {
  local choice="$1" key label new
  for key in $(toggles_keys); do
    label="$(toggle_label "$key")"
    case "$choice" in
      "$label"：*)
        new="$(toggle_flip "$key")"
        if [ "$new" = "1" ]; then notify "已开启：$label"; else notify "已关闭：$label"; fi
        return 0
        ;;
    esac
  done
}

menu_loop "开关" get_items handle
