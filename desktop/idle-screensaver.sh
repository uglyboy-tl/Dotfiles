#!/usr/bin/env bash
# idle-screensaver.sh - 空闲后全屏轮播图片，用户一有输入立即结束。
# 轮询 xprintidle，不依赖 X screensaver 扩展（后者常被应用挂起）。
#
# 用法:
#   idle-screensaver.sh [daemon]   常驻：空闲 IDLE_SCREENSAVER_TIMEOUT 秒后开始轮播（bspwmrc 用）
#   idle-screensaver.sh show       立即显示一次，有输入即结束（测试/绑定快捷键用）
#   idle-screensaver.sh stop       结束正在显示的屏保
#
# 本地设置: ~/.config/local/idle-screensaver（可设 IDLE_SCREENSAVER_DIR / TIMEOUT / DELAY）
# 环境变量: IDLE_SCREENSAVER_DIR（图片目录）、IDLE_SCREENSAVER_TIMEOUT（空闲秒数）、IDLE_SCREENSAVER_DELAY（每张秒数）
# 图片目录后备默认 = 随仓库分发的动态壁纸图库（$XDG_DATA_HOME/dynamic-wallpaper/images），任何环境都有图

set -u

# 本地覆盖（不进版本控制）：~/.config/local/idle-screensaver
# 可在其中设置 IDLE_SCREENSAVER_DIR / IDLE_SCREENSAVER_TIMEOUT / IDLE_SCREENSAVER_DELAY。
# 优先级：命令行环境变量 > 本地文件 > 内置默认。
_env_dir="${IDLE_SCREENSAVER_DIR-}"
_env_timeout="${IDLE_SCREENSAVER_TIMEOUT-}"
_env_delay="${IDLE_SCREENSAVER_DELAY-}"
LOCAL_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/local/idle-screensaver"
[ -f "$LOCAL_CONF" ] && . "$LOCAL_CONF"

IMAGES="${_env_dir:-${IDLE_SCREENSAVER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/dynamic-wallpaper/images}}"
TIMEOUT="${_env_timeout:-${IDLE_SCREENSAVER_TIMEOUT:-300}}"
DELAY="${_env_delay:-${IDLE_SCREENSAVER_DELAY:-10}}"
STATE="${XDG_RUNTIME_DIR:-/tmp}/idle-screensaver"

command -v feh >/dev/null 2>&1 || exit 0
command -v xprintidle >/dev/null 2>&1 || exit 0
[ -d "$IMAGES" ] || exit 0
find "$IMAGES" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print -quit 2>/dev/null | grep -q . || exit 0

running() { pgrep -x feh >/dev/null 2>&1; }
start_feh() {
	running || feh --fullscreen --auto-zoom --randomize --recursive \
		--hide-pointer --slideshow-delay "$DELAY" "$IMAGES" &
}
stop_feh() { running && pkill -x feh; }

# 立即显示一次：先等用户停止操作，再监听新的输入来结束（避免「敲回车启动」被当成活动）
show() {
	mkdir -p "$STATE"; : > "$STATE/hold"
	start_feh
	while running && [ "$(xprintidle)" -lt 1000 ]; do sleep 0.2; done
	while running; do
		[ "$(xprintidle)" -lt 300 ] && stop_feh
		sleep 0.2
	done
	rm -f "$STATE/hold"
}

daemon() {
	mkdir -p "$STATE"
	while :; do
		if [ -e "$STATE/hold" ]; then
			sleep 1
			continue
		fi
		if [ "$(( $(xprintidle) / 1000 ))" -ge "$TIMEOUT" ]; then
			start_feh
		else
			stop_feh
		fi
		sleep 2
	done
}

case "${1:-daemon}" in
	daemon)        daemon ;;
	show | now)    show ;;
	stop)          rm -f "$STATE/hold"; stop_feh ;;
	-h | --help)   sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	*)             echo "用法: ${0##*/} [daemon|show|stop]" >&2; exit 2 ;;
esac
