#!/usr/bin/env bash
# 帮助子菜单
# 用法:
#   setting-help.sh   查看/执行快捷键、查看关于（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 快捷键与关于都属于"查看/帮助"而非"设置"，集中在帮助子菜单下。
# 快捷键界面执行命令后返回 MENU_EXIT_ALL，经 menu_loop 向上传播以退出整栈。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

# 加载公共函数(含 epipe_init/select_ui/menu_loop)并初始化 stdout 安全
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/menu.sh"
epipe_init

# 帮助项列表
get_help_items() {
  cat <<EOF
快捷键
关于
EOF
}

# 处理帮助项
handle_help() {
  case "$1" in
    快捷键) "$DOTFILES_DIR/settings/setting-help-keybindings.sh" ;;
    关于) "$DOTFILES_DIR/settings/setting-help-about.sh" ;;
  esac
}

main() {
  menu_loop "帮助" get_help_items handle_help
}

main "$@"
