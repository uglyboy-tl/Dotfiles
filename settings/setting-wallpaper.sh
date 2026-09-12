#!/usr/bin/env bash
# 壁纸切换脚本
# 用法:
#   wallpaper.sh <风格名>      直接切换到指定风格（单次）
#   wallpaper.sh              交互式选择/循环切换（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"
WALLPAPER_DIR="$XDG_DATA_HOME/dynamic-wallpaper/images"
STATE_FILE="$XDG_STATE_HOME/wallpaper/current"

# 加载公共函数(含 epipe_init)并初始化 stdout 安全
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
epipe_init

# 列出可用壁纸风格
get_wallpaper_styles() {
  if [ -d "$WALLPAPER_DIR" ]; then
    find "$WALLPAPER_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
  fi
}

# 读取当前壁纸风格
get_current_style() {
  # 优先从 STATE_FILE 读取
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
    return
  fi
  # 否则从 crontab 读取
  local cron_line
  cron_line=$(crontab -l 2>/dev/null | grep "dwall.sh")
  if [ -n "$cron_line" ]; then
    echo "$cron_line" | grep -oP 'dwall\.sh -s \K[^ ]+'
  fi
}

# 保存当前壁纸风格
save_current_style() {
  mkdir -p "$(dirname "$STATE_FILE")"
  echo "$1" > "$STATE_FILE"
}

# 选择壁纸风格（设置全局 STYLE；用户取消时退出脚本）
select_style() {
  local current styles_data
  current="$(get_current_style)"
  styles_data="$(get_wallpaper_styles)"
  STYLE=$(select_ui \
    -p "当前壁纸：${current:-无}" \
    -d "$styles_data" \
    -s "$current" \
    -i "$DOTFILES_DIR/settings/lib/wallpaper-image.sh {}") || exit 0
}

# 校验壁纸风格（失败返回1，不退出进程）
validate_style() {
  if [ ! -d "$WALLPAPER_DIR/$1" ]; then
    notify_error "壁纸风格 '$1' 不存在，已忽略"
    return 1
  fi
  return 0
}

# 应用壁纸
apply_wallpaper() {
  local style="$1"
  "$DOTFILES_DIR/desktop/scripts/dwall.sh" -s "$style"
}

# 更新 crontab
crontab_update() {
  local style="$1"
  local cron_line
  cron_line=$(crontab -l 2>/dev/null | grep "dwall.sh" || true)

  # 构建 crontab 条目
  local new_cron
  new_cron="@hourly env DISPLAY=:0 XAUTHORITY=\"/var/run/lightdm/uglyboy/xauthority\" PATH=\"$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin\" XDG_DATA_HOME=\"$HOME/.local/share\" DBUS_SESSION_BUS_ADDRESS=\"unix:path=/run/user/1000/bus\" XDG_SESSION_TYPE=x11 DESKTOP_SESSION=bspwm TERM=dumb dwall.sh -s $style # dotbot"

  if [ -n "$cron_line" ]; then
    # 替换已有条目
    (crontab -l 2>/dev/null | grep -v "dwall.sh" || true; echo "$new_cron") | crontab -
  else
    # 添加新条目
    (crontab -l 2>/dev/null; echo "$new_cron") | crontab -
  fi
  echo "已更新 crontab: 壁纸风格 -> $style"
}

# 应用指定壁纸风格（单次）
apply_wallpaper_run() {
  local style="$1"
  validate_style "$style" || return 1
  apply_wallpaper "$style"
  crontab_update "$style"
  save_current_style "$style"
  notify "已切换壁纸风格: $style"
}

# 循环模式：选择 → 应用 → 回到选择界面
# 非法输入(validate 失败)时 apply_wallpaper_run 返回非零，此处不退出，继续回到选择界面
loop_mode() {
  while true; do
    select_style
    apply_wallpaper_run "$STYLE" || continue
  done
}

main() {
  if [ "$#" -ge 1 ]; then
    # 指定风格名，单次应用
    apply_wallpaper_run "$1"
  else
    # 交互式循环
    loop_mode
  fi
}

main "$@"
