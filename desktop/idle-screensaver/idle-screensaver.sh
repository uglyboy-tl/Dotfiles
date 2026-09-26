#!/usr/bin/env bash
# idle-screensaver.sh - 空闲后全屏轮播图片，用户一有输入立即结束。
# 轮询 xprintidle，不依赖 X screensaver 扩展（后者常被应用挂起）。
#
# 抑制：下列任一成立时不出屏保，并临时禁用熄屏（DPMS），条件消失后自动恢复：
#   1. 浏览器/播放器经 D-Bus 申请抑制（见 idle-screensaver-dbus.py 的心跳文件）
#   2. 有全屏窗口（全屏看视频/游戏/演示）
#   3. 有音频流在播放（窗口化看视频、听歌）
#
# 用法:
#   idle-screensaver.sh [daemon]   常驻：空闲 IDLE_SCREENSAVER_TIMEOUT 秒后开始轮播（bspwmrc 用）
#   idle-screensaver.sh show       立即显示一次，有输入即结束（测试/绑定快捷键用）
#   idle-screensaver.sh stop       结束正在显示的屏保
#   idle-screensaver.sh status     打印当前空闲时间与抑制原因（排查用）
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
FEH_PID="$STATE/feh.pid"           # 屏保自己启动的 feh，避免误杀用户手动打开的
INHIBIT_FILE="$STATE/dbus-inhibit"  # idle-screensaver-dbus.py 写的心跳文件
HEARTBEAT_MAX=5                     # 心跳新鲜度上限（秒），超过视为该服务已死

command -v feh >/dev/null 2>&1 || exit 0
command -v xprintidle >/dev/null 2>&1 || exit 0
[ -d "$IMAGES" ] || exit 0
find "$IMAGES" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print -quit 2>/dev/null | grep -q . || exit 0

# 只认自己启动的 feh：pid 文件 + /proc 校验，避免 PID 复用误判，也避免 pkill 误杀用户手动打开的 feh
feh_pid() {
	[ -s "$FEH_PID" ] || return 1
	local pid
	pid="$(cat "$FEH_PID" 2>/dev/null)" || return 1
	[ -n "$pid" ] && [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = feh ] && printf '%s' "$pid"
}
running() { feh_pid >/dev/null; }
start_feh() {
	if running; then
		return 0
	fi
	mkdir -p "$STATE"
	feh --fullscreen --auto-zoom --randomize --recursive \
		--hide-pointer --slideshow-delay "$DELAY" "$IMAGES" &
	echo $! > "$FEH_PID"
}
stop_feh() {
	local pid
	pid="$(feh_pid)" || { rm -f "$FEH_PID"; return 0; }
	kill "$pid" 2>/dev/null
	rm -f "$FEH_PID"
}

# ── 抑制判定：每项命中就打印一行原因，供 inhibited 与 status 共用 ──
inhibit_reasons() {
	if [ -e "$INHIBIT_FILE" ] &&
		[ "$(( $(date +%s) - $(stat -c %Y "$INHIBIT_FILE" 2>/dev/null || echo 0) ))" -lt "$HEARTBEAT_MAX" ]; then
		sed 's/^/D-Bus: /' "$INHIBIT_FILE"
	fi
	# 全屏窗口（bspwm 的 .fullscreen 状态，浏览器 F11/网页全屏都算）
	bspc query -N -n .fullscreen >/dev/null 2>&1 && echo "全屏窗口"
	# 有音频输出流在播（暂停/停止的流状态是 idle，不会误判）
	command -v pw-dump >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 &&
		pw-dump 2>/dev/null | jq -e 'any(.[]; .type=="PipeWire:Interface:Node" and .info.state=="running" and .info.props["media.class"]=="Stream/Output/Audio")' >/dev/null 2>&1 &&
		echo "音频播放中"
	return 0
}

inhibited() { [ -n "$(inhibit_reasons)" ]; }

# ── 抑制期间禁用 DPMS（熄屏），仅在状态翻转时调用 xset ──
dpms_disabled=0
dpms_hold() {
	[ "$dpms_disabled" = 1 ] && return 0
	xset -dpms 2>/dev/null && dpms_disabled=1
}
dpms_release() {
	[ "$dpms_disabled" = 0 ] && return 0
	xset +dpms 2>/dev/null && dpms_disabled=0
}

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
			dpms_release
			sleep 1
			continue
		fi
		# 只在屏保未显示时判抑制，否则 feh 自己的全屏窗口会被当成「被抑制」
		if ! running && inhibited; then
			dpms_hold
			sleep 2
			continue
		fi
		dpms_release
		if [ "$(( $(xprintidle) / 1000 ))" -ge "$TIMEOUT" ]; then
			start_feh
		else
			stop_feh
		fi
		sleep 2
	done
}

status() {
	local reasons
	reasons="$(inhibit_reasons)"
	if [ -e "$STATE/hold" ]; then
		echo "手动暂停中（show/hold）"
	elif [ -n "$reasons" ]; then
		echo "已抑制：不出屏保、不熄屏"
		printf '%s\n' "$reasons" | sed 's/^/  /'
	else
		echo "未抑制"
	fi
	echo "空闲 $(( $(xprintidle) / 1000 ))s / 阈值 ${TIMEOUT}s，屏保显示中: $(running && echo 是 || echo 否)"
	echo "DPMS: $(xset q 2>/dev/null | awk '/DPMS is/{print $3, $4}')（抑制时 daemon 会临时关闭）"
}

# 退出时别把 DPMS 留在关闭状态
trap 'dpms_release' EXIT
trap 'exit 0' INT TERM

case "${1:-daemon}" in
	daemon)        daemon ;;
	show | now)    show ;;
	stop)          rm -f "$STATE/hold"; stop_feh ;;
	status)        status ;;
	-h | --help)   sed -n '/^# 用法:/,/^#$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	*)             echo "用法: ${0##*/} [daemon|show|stop|status]" >&2; exit 2 ;;
esac
