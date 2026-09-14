#!/usr/bin/env bash
# wallpaper.sh - 壁纸引擎（无 UI）
# 作为函数库被 source：菜单 setting-wallpaper.sh、以及 bspwmrc 的启动套用。
# 不含交互/提示逻辑（那是菜单的事）。

# 防止重复加载
[[ -n "${_WALLPAPER_LOADED:-}" ]] && return 0
_WALLPAPER_LOADED=1

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${DOTFILES_DIR:=$XDG_DATA_HOME/dotfiles}"

WALLPAPER_DIR="${WALLPAPER_DIR:-$XDG_DATA_HOME/dynamic-wallpaper/images}"
WALLPAPER_STATE_FILE="${WALLPAPER_STATE_FILE:-$XDG_STATE_HOME/wallpaper/current}"

# 可用风格列表
wallpaper_list() {
  [ -d "$WALLPAPER_DIR" ] || return 0
  find "$WALLPAPER_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
}

# 当前风格：优先状态文件，否则从 crontab 提取
wallpaper_current() {
  if [ -f "$WALLPAPER_STATE_FILE" ]; then
    cat "$WALLPAPER_STATE_FILE"
    return
  fi
  local cron_line
  cron_line=$(crontab -l 2>/dev/null | grep "dwall.sh")
  if [ -n "$cron_line" ]; then
    echo "$cron_line" | grep -oP 'dwall\.sh -s \K[^ ]+'
  fi
}

wallpaper_save() {
  mkdir -p "$(dirname "$WALLPAPER_STATE_FILE")"
  printf '%s\n' "$1" > "$WALLPAPER_STATE_FILE"
}

# 校验风格
wallpaper_validate() { [ -d "$WALLPAPER_DIR/$1" ]; }

# 更新 crontab（每小时轮换当前风格）
_wallpaper_crontab_update() {
  local style="$1" cron_line new_cron
  cron_line=$(crontab -l 2>/dev/null | grep "dwall.sh" || true)
  new_cron="@hourly env DISPLAY=:0 XAUTHORITY=\"/var/run/lightdm/uglyboy/xauthority\" PATH=\"$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin\" XDG_DATA_HOME=\"$HOME/.local/share\" DBUS_SESSION_BUS_ADDRESS=\"unix:path=/run/user/1000/bus\" XDG_SESSION_TYPE=x11 DESKTOP_SESSION=bspwm TERM=dumb dwall.sh -s $style # dotbot"
  if [ -n "$cron_line" ]; then
    (crontab -l 2>/dev/null | grep -v "dwall.sh" || true; echo "$new_cron") | crontab -
  else
    (crontab -l 2>/dev/null; echo "$new_cron") | crontab -
  fi
}

# 套用风格（校验 → dwall → crontab → 存状态；无提示）
wallpaper_apply() {
  local style="$1"
  wallpaper_validate "$style" || return 1
  "$DOTFILES_DIR/desktop/scripts/dwall.sh" -s "$style"
  _wallpaper_crontab_update "$style"
  wallpaper_save "$style"
}
