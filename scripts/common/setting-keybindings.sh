#!/usr/bin/env bash
# 快捷键速查脚本
# 用法:
#   setting-keybindings.sh      交互式查看（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 精选最重要的快捷键展示，按功能分区。
# 选中后显示对应命令，然后回到列表。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

# 加载公共函数(含 epipe_init)并初始化 stdout 安全
source "$DOTFILES_DIR/scripts/common/selectors.sh"
source "$DOTFILES_DIR/scripts/common/notify.sh"
epipe_init

# 精选快捷键列表: "描述<TAB>键位<TAB>命令"
get_shortcuts() {
  cat <<'EOF'
打开终端	Super + Return	ghostty
启动应用	Super + r	rofi -show drun
切换窗口	Alt + Tab	rofi -show window
文件管理器	Super + e	ghostty --x11-instance-name=yazi -e yazi
音乐播放器	Super + m	ghostty -e ncmpcpp
系统监控	Super + h	ghostty -e btop
新闻阅读	Super + n	ghostty -e newsboat
剪贴板播放	Super + v	mpv "$(xclip -selection clipboard -o)"
蓝牙管理	Super + b	~/.local/bin/rofi-bluetooth
关闭窗口	Super + w	bspc node -c
强制关闭	Super + Shift + w	bspc node -k
全屏	Super + f	bspc node -t fullscreen
浮动/平铺	Super + Space	bspc node -t "~"{floating,tiled}
切换布局	Super + Shift + f	bspc desktop -l next
退出重启	Super + Alt + q	bspc quit
重载窗口管理	Super + Alt + r	bspc wm -r
重载快捷键	Super + Escape	pkill -USR1 -x sxhkd
EOF
}

# 展示并查看
show_shortcuts() {
  local list
  list="$(get_shortcuts)"

  while true; do
    local choice
    choice=$(select_ui \
      -p "快捷键" \
      -d "$list") || break

    local desc="${choice%%	*}"
    local rest="${choice#*	}"
    local key="${rest%%	*}"
    local cmd="${rest#*	}"
    cmd="${cmd%%	*}"

    notify "描述: $desc
键位: $key
命令: $cmd" "快捷键"
  done
}

main() {
  show_shortcuts
}

main "$@"