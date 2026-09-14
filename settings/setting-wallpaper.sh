#!/usr/bin/env bash
# 壁纸切换（菜单 UI：选择 → 校验 → 应用）
# 用法:
#   setting-wallpaper.sh <风格名>   直接切换（单次）
#   setting-wallpaper.sh            交互式选择/循环切换（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 套用逻辑在 settings/lib/wallpaper.sh（bspwmrc 启动套用也用它）。

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
