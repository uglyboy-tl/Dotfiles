#!/usr/bin/env bash
# 主题切换脚本
# 用法:
#   theme <主题名>      直接切换到指定主题（单次）
#   theme              交互式选择/循环切换（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 从 colors/ 下读取主题，通过模板渲染生成各软件颜色配置。

# 严格模式。
# 注意: 交互式命令(fzf/rofi)的返回码用 if/|| 处理，
# 避免 set -e 在用户取消时误触发退出。
set -euo pipefail

# ============================================================
# 配置
# ============================================================

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

# 加载公共函数(含 epipe_init)并初始化 stdout 安全
source "$DOTFILES_DIR/desktop/scripts/common/selectors.sh"
source "$DOTFILES_DIR/desktop/scripts/common/render.sh"
source "$DOTFILES_DIR/desktop/scripts/common/notify.sh"
epipe_init

COLORS_DIR="$DOTFILES_DIR/themes/colors"
TEMPLATES_DIR="$DOTFILES_DIR/themes/templates"
STATE_FILE="$XDG_STATE_HOME/theme/current"

# 模板映射: "软件名:模板文件名:输出路径(相对于 XDG_CONFIG_HOME)"
# 渲染时先判断软件是否存在（command -v），不存在则跳过
declare -A THEME_TEMPLATES=(
  ["rofi"]="rofi.rasi.tpl:rofi/colors.rasi"
  ["polybar"]="polybar.ini.tpl:polybar/colors.ini"
  ["dunst"]="dunst.conf.tpl:dunst/dunstrc.d/colors.conf"
  ["alacritty"]="alacritty.toml.tpl:alacritty/colors.toml"
  ["ghostty"]="ghostty.conf.tpl:ghostty/colors.conf"
  ["urxvt"]="rxvt.tpl:X11/Xresources.d/rxvt-colors"
  ["zathura"]="zathura.conf.tpl:zathura/colors.conf"
  ["bspwm"]="bspwm.sh.tpl:bspwm/colors.sh"
)

# 需要重载的软件: "软件名:重载命令"
# ghostty 通过 SIGUSR2 信号重载配置
# urxvt 通过重新加载 XResources 更新颜色（新窗口生效）
declare -A RELOAD_CMDS=(
  ["polybar"]="polybar-msg cmd restart"
  ["dunst"]="dunstctl reload"
  ["ghostty"]="pkill -USR2 -x ghostty"
  ["urxvt"]="xrdb -merge $XDG_CONFIG_HOME/X11/Xresources"
  ["bspwm"]="bspc wm -r"
)

# ============================================================
# 函数
# ============================================================

# 列出可用主题
get_themes() {
  find "$COLORS_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
}

# 读取当前主题（从状态文件）
get_current_theme() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  fi
}

# 保存当前主题
save_current_theme() {
  mkdir -p "$(dirname "$STATE_FILE")"
  echo "$1" > "$STATE_FILE"
}

# 选择主题（设置全局 THEME；用户取消时退出脚本）
select_theme() {
  local current themes_data
  current="$(get_current_theme)"
  themes_data="$(get_themes)"
  THEME=$(select_ui \
    -p "当前主题：${current:-无}" \
    -d "$themes_data" \
    -s "$current") || exit 0
}

# 校验主题（失败返回1，不退出进程，供循环内忽略非法输入）
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

# 渲染模板
render_templates() {
  local theme="$1"
  local rendered=0

  for app in "${!THEME_TEMPLATES[@]}"; do
    # 软件未安装则跳过
    if ! command -v "$app" >/dev/null 2>&1; then
      echo "跳过: $app（未安装）"
      continue
    fi

    IFS=':' read -r template_file output_path <<< "${THEME_TEMPLATES[$app]}"
    local src="$TEMPLATES_DIR/$template_file"
    local dst="$XDG_CONFIG_HOME/$output_path"

    if [ -f "$src" ]; then
      render "$COLORS_DIR/$theme/colors.toml" "$src" "$dst"
      rendered=$((rendered + 1))
    else
      echo "跳过: $app（模板 $template_file 不存在）"
    fi
  done

  if [ "$rendered" -eq 0 ]; then
    notify_error "主题 '$theme' 没有可用的模板"
    exit 1
  fi
}

# 重载软件
reload_apps() {
  for app in "${!RELOAD_CMDS[@]}"; do
    local cmd="${RELOAD_CMDS[$app]}"
    local cmd_name="${cmd%% *}"
    if command -v "$cmd_name" >/dev/null 2>&1; then
      if $cmd >/dev/null 2>&1; then
        echo "已通知 $app 重新加载"
      else
        echo "警告: $app 未运行，跳过" >&2
      fi
    fi
  done
}

# ============================================================
# 主函数
# ============================================================

# 等待 dunst 重启完成：bspc wm -r 会重跑 bspwmrc，其中 ( _s dunst ) & 是
# 异步子 shell，旧 dunst 稍后才被杀。检测 PID 变化 + DBus 就绪后再发通知，
# 避免通知落在重启窗口期被吞。dunst 未运行或未重启则直接返回。
wait_dunst_ready() {
  local old_pid="$1" i j new_pid
  [ -z "$old_pid" ] && return 0
  for i in $(seq 1 15); do # 最多 1.5s 等 PID 变化
    new_pid=$(pgrep -x dunst | head -n1 || true)
    if [ -n "$new_pid" ] && [ "$new_pid" != "$old_pid" ]; then
      # dunst 已重启，等它注册 DBus 可用
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

# 应用指定主题（单次）
apply_theme() {
  local theme="$1" old_dunst_pid
  validate_theme "$theme" || return 1
  render_templates "$theme"
  save_current_theme "$theme"
  # 先重载各软件(含 bspc wm -r，会重启 dunst)，等新 dunst 就绪后再发通知
  old_dunst_pid=$(pgrep -x dunst | head -n1 || true)
  reload_apps
  wait_dunst_ready "$old_dunst_pid"
  notify "已切换到主题: $theme"
}

# 循环模式：选择 → 应用 → 回到选择界面
# 非法输入(validate 失败)时 apply_theme 返回非零，此处不退出，继续回到选择界面
loop_mode() {
  while true; do
    select_theme
    apply_theme "$THEME" || continue
  done
}

main() {
  if [ "$#" -ge 1 ]; then
    # 指定主题名，单次应用
    apply_theme "$1"
  else
    # 交互式循环
    loop_mode
  fi
}

main "$@"
