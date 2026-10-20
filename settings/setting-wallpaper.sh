#!/usr/bin/env bash
# setting-wallpaper.sh - 壁纸切换：选择 → 校验 → 应用（套用逻辑在 lib/wallpaper.sh）

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
source "$DOTFILES_DIR/settings/lib/wallpaper.sh"
epipe_init

# 选择风格（设置全局 STYLE；用户取消时退出脚本）
select_style() {
  local current
  current="$(wallpaper_current)"
  STYLE=$(select_ui \
    -p "当前壁纸：${current:-无}" \
    -d "$(wallpaper_list)" \
    -s "$current" \
    -i "$DOTFILES_DIR/settings/lib/wallpaper-image.sh {}") || exit 0
}

# 切换并提示（失败不退出进程，供循环内忽略）
switch_wallpaper() {
  local style="$1"
  if ! wallpaper_validate "$style"; then
    notify_error "壁纸风格 '$style' 不存在，已忽略"
    return 1
  fi
  wallpaper_apply "$style" || return 1
  notify "已切换壁纸风格: $style"
}

loop_mode() {
  while true; do
    select_style
    switch_wallpaper "$STYLE" || continue
  done
}

main() {
  if [ "$#" -ge 1 ]; then
    switch_wallpaper "$1"
  else
    loop_mode
  fi
}

main "$@"
