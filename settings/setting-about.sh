#!/usr/bin/env bash
# 系统信息(关于)脚本
# 用法:
#   setting-about.sh   显示 fastfetch 系统信息（界面由 SELECTOR_UI 决定）
#
# 通过通用展示层 lib/show.sh 展示带 ANSI 颜色的输出:
#   gui: rofi 只读窗 (viewer.rasi + ansi-to-pango.py)
#   tui: fzf 预览窗格 (ansi-to-ansi.py)

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/show.sh"
epipe_init

main() {
  show_content "fastfetch --pipe false" --prompt "关于"
}

main "$@"
