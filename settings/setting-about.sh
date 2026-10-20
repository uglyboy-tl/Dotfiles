#!/usr/bin/env bash
# setting-about.sh - 显示 fastfetch 系统信息（经 lib/show.sh 展示带 ANSI 颜色的输出）

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
