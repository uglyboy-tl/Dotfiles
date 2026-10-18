#!/usr/bin/env bash
# 主题预览截图
# 固定 tmux 布局 -> 切分辨率 -> 在桌面 III 开 ghostty(平铺) -> 截图 -> 清理
#
# 用法:
#   capture.sh <输出图片路径>                 截图当前已套用的主题（本脚本不换主题）
#   capture.sh --all                          遍历 themes/colors/，缺图才截，结束恢复原主题
#   capture.sh --all --force                   全部重截（含已有 preview.jpg）
#   capture.sh --all --only dracula,vesper     只处理指定主题
#
# 截图会压缩后写出（缩到 1280 宽 + JPEG q85），建议输出 .jpg。
#
# 场景布局（来自当前 tmux 会话，4 个 pane）:
#   ┌──────────────┬──────────────┐
#   │ fastfetch    │ vim          │
#   │              │ ~/Code/BashDev/bashlet/examples
#   ├──────────────┼──────────────┤
#   │ yazi         │ neomutt      │
#   │ ~/Code/InkWeave
#   └──────────────┴──────────────┘

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"
COLORS_DIR="$DOTFILES_DIR/themes/colors"
STATE_FILE="$XDG_STATE_HOME/theme/current"

ALL=0
FORCE=0
ONLY=""
OUT=""

usage() {
  echo "用法: capture.sh <输出图片路径> | --all [--force] [--only <主题1,主题2>]" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     ALL=1; shift ;;
    --force)   FORCE=1; shift ;;
    --only)    ONLY="${2:?--only 需要主题名，逗号分隔}"; ALL=1; shift 2 ;;
    --only=*)  ONLY="${1#*=}"; ALL=1; shift ;;
    -h | --help) usage ;;
    -*)        echo "未知参数: $1" >&2; usage ;;
    *)         OUT="$1"; shift ;;
  esac
done
[ "$ALL" = 1 ] || [ -n "$OUT" ] || usage

XOUT="DP-0"
MODE_CAPTURE="2560x1440"   # 截图用的 16:9 分辨率
MODE_NATIVE="3440x1440"    # 用完恢复
RATE_NATIVE="120"          # 必须显式给：只给 --mode 的话 xrandr 会选它的 preferred（60Hz），
                           # 而 bspwmrc 要求的是 120Hz，跑完一次就降频了
DESKTOP="III"
SESSION="theme-shot"
GHOSTTY_CLASS="com.mitchellh.ghostty"

# 每个 pane 的命令
# 这四个命令/路径写死后很容易跟现实脉脉脱节（上一版还是 fetch + ~/Code/BashDev/src，
# 两个都不存在了）。截图里如果某个 pane 报「command not found」，先回头改这里。
CMD_TL='fastfetch'
CMD_TR='cd "$HOME/Code/BashDev/bashlet/examples" && vim args.sh'
CMD_BR='neomutt'
CMD_BL='cd "$HOME/Code/InkWeave" && yazi'

prev_desktop=""
prev_theme=""
win=""
tmp=""

# 记录下来的布局（字符网格 308x64；pane id 占位符后填）
# 结构: [左上 TL, 左下 BL]  |  [右上 TR, 右下 BR]
layout_body() {
  printf '308x64,0,0{163x64,0,0[163x40,0,0,%s,163x23,0,41,%s],144x64,164,0[144x32,164,0,%s,144x31,164,33,%s]}' \
    "$1" "$2" "$3" "$4"
}

# tmux layout 校验和: 循环右移一位后累加
layout_checksum() {
  LAYOUT="$1" python3 -c 'import os
c=0
for ch in os.environ["LAYOUT"].encode():
    c=((c>>1)|((c&1)<<15))&0xffff
    c=(c+ch)&0xffff
print("%04x"%c)'
}

# 关掉桌面 III 上已有的 ghostty，保证舞台干净
close_stale_ghostty() {
  local id cls pid
  for id in $(bspc query -N -d "$DESKTOP" 2>/dev/null || true); do
    cls="$(bspc query -T -n "$id" | jq -r '.client.className // empty')"
    if [ "$cls" = "$GHOSTTY_CLASS" ]; then
      pid="$(bspc query -T -n "$id" | jq -r '.client.pid // empty')"
      [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
    fi
  done
}

# 分辨率恢复后 bspwm 不一定跟着重排：曾出现「屏幕已是 3440、窗口还是 2560 宽」，
# 右边空一条；且 `bspc wm -r`、重设 window_gap 都不触发重排，只能重启那些窗口。
# 静默出错很难发现，这里断言一下。
_check_tiling() {
  sleep 1  # 给 bspwm 反应 RandR 事件的时间
  bspc wm -d 2>/dev/null | jq -r '
    .monitors[] as $m
    | $m.desktops[]
    | select(.root.rectangle != null)
    | select(($m.rectangle.width  - (.root.rectangle.x + .root.rectangle.width))  > 100
          or ($m.rectangle.height - (.root.rectangle.y + .root.rectangle.height)) > 100)
    | "警告: 桌面 \(.name) 的窗口没铺满监视器（右边缘 \(.root.rectangle.x + .root.rectangle.width) / 屏幕 \($m.rectangle.width)）"
      + "—— bspwm 没有在分辨率恢复后重排，需手动重启受影响的窗口"
  ' 2>/dev/null || true
}

# 整个脚本跑完后的收尾：临时文件、分辨率、桌面
teardown() {
  [ -n "$tmp" ] && rm -f "$tmp"
  xrandr --output "$XOUT" --mode "$MODE_NATIVE" --rate "$RATE_NATIVE" >/dev/null 2>&1 || true
  _check_tiling
  [ -n "$prev_desktop" ] && bspc desktop -f "$prev_desktop" >/dev/null 2>&1 || true
}
trap teardown EXIT

# 当前屏幕尺寸（如 3440x1440）
_screen_size() {
  xrandr --query | sed -n 's/.*current \([0-9]*\) x \([0-9]*\).*/\1x\2/p' | head -1
}

# 切到截图分辨率。注意 bspwmrc 里写死了原生分辨率，而换主题会触发 `bspc wm -r`
# -> bspwmrc 重跑 -> 分辨率被改回去，所以每轮套用主题后都要再按一次。
set_capture_mode() { xrandr --output "$XOUT" --mode "$MODE_CAPTURE"; }

# 分辨率不对时截出来就是原生尺寸（1280x536 而不是 1280x720），静默出错很难发现
_warn_if_wrong_size() {
  local cur
  cur="$(_screen_size)"
  [ "$cur" = "$MODE_CAPTURE" ] || echo "警告: 屏幕当前是 $cur，不是 $MODE_CAPTURE，截图尺寸会不对" >&2
}

# 建 tmux 会话与 4 个 pane
start_tmux() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  tmux new-session -d -s "$SESSION" -n shot -x 308 -y 64
  local w="$SESSION:shot" ids body
  tmux split-window -h -t "$w"
  tmux split-window -v -t "$w"
  tmux split-window -v -t "$w"

  # 取实际 pane id（按 index 顺序：1 左上 / 2 左下 / 3 右上 / 4 右下）
  # select-layout 按 pane index 顺序套用到布局叶子顺序，id 仅作校验
  mapfile -t ids < <(tmux list-panes -t "$w" -F '#{pane_id}' | tr -d '%')
  body="$(layout_body "${ids[0]}" "${ids[1]}" "${ids[2]}" "${ids[3]}")"
  tmux select-layout -t "$w" "$(layout_checksum "$body"),$body"

  # 发送各 pane 命令（与上面 index 顺序对应）
  tmux send-keys -t "%${ids[0]}" "$CMD_TL" Enter
  tmux send-keys -t "%${ids[1]}" "$CMD_BL" Enter
  tmux send-keys -t "%${ids[2]}" "$CMD_TR" Enter
  tmux send-keys -t "%${ids[3]}" "$CMD_BR" Enter
  tmux select-pane -t "%${ids[0]}"
}

# 打开 ghostty -> 等渲染 -> 截图压缩写出
shoot() {
  local out="$1" id cls
  ghostty -e tmux attach -t "$SESSION" >/dev/null 2>&1 &
  sleep 3
  for id in $(bspc query -N -d "$DESKTOP" 2>/dev/null || true); do
    cls="$(bspc query -T -n "$id" | jq -r '.client.className // empty')"
    if [ "$cls" = "$GHOSTTY_CLASS" ]; then
      win="$id"
      bspc node "$id" -t tiled 2>/dev/null || true
    fi
  done

  sleep 6
  _warn_if_wrong_size
  tmp="$(mktemp --suffix=.png)"
  maim -u "$tmp"
  magick "$tmp" -resize "1280x1280>" -strip -quality 85 "$out"
  rm -f "$tmp"
  tmp=""
  echo "已保存: $out ($(du -h "$out" | cut -f1))"
}

# 拆掉这一轮的 tmux 会话与 ghostty
stop_tmux() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  [ -n "$win" ] && bspc node "$win" -c 2>/dev/null || true
  win=""
}

prev_desktop="$(bspc query -D -d focused --names 2>/dev/null || true)"

# 先定好要处理哪些主题，参数写错就不必动分辨率和桌面了
themes=()
if [ "$ALL" = 1 ]; then
  prev_theme="$(cat "$STATE_FILE" 2>/dev/null || true)"
  [ -d "$COLORS_DIR" ] || { echo "错误: 找不到 $COLORS_DIR" >&2; exit 1; }
  mapfile -t themes < <(
    for d in "$COLORS_DIR"/*/; do
      [ -f "$d/colors.toml" ] || continue
      name="$(basename "$d")"
      if [ -n "$ONLY" ] && [[ ",$ONLY," != *",$name,"* ]]; then continue; fi
      printf '%s\n' "$name"
    done
  )
  [ "${#themes[@]}" -gt 0 ] || { echo "没有匹配的主题（--only $ONLY）" >&2; exit 1; }
fi

close_stale_ghostty
set_capture_mode
bspc desktop -f "$DESKTOP"
sleep 1

if [ "$ALL" = 0 ]; then
  start_tmux
  shoot "$OUT"
  stop_tmux
  exit 0
fi

# ============================================================
# 批量模式：套用主题 -> 截图 -> 下一轮
# ============================================================

# 套用主题时不弹桌面通知（notify 按 SELECTOR_UI 分派，tui 走 stdout 被吃掉）
apply_theme_quiet() {
  SELECTOR_UI=tui "$DOTFILES_DIR/settings/setting-theme.sh" "$1" >/dev/null
}

i=0
shot=0
last_applied=""
for name in "${themes[@]}"; do
  i=$((i + 1))
  out="$COLORS_DIR/$name/preview.jpg"
  if [ -f "$out" ] && [ "$FORCE" = 0 ]; then
    echo "[$i/${#themes[@]}] $name: 已有 preview.jpg，跳过（--force 可重截）"
    continue
  fi

  echo "[$i/${#themes[@]}] $name: 套用主题..."
  apply_theme_quiet "$name"
  last_applied="$name"
  # 换主题触发的 bspc wm -r 会让 bspwmrc 把分辨率改回原生，等它跑完再按回来
  sleep 2
  set_capture_mode

  start_tmux
  shoot "$out"
  stop_tmux
  shot=$((shot + 1))
done

# 收尾恢复原主题（没截过图就不用恢复；最后套用的就是原主题时也不必再来一遍）
if [ "$shot" -gt 0 ] && [ -n "$prev_theme" ] && [ "$prev_theme" != "$last_applied" ] \
   && [ -f "$COLORS_DIR/$prev_theme/colors.toml" ]; then
  echo "恢复主题: $prev_theme"
  apply_theme_quiet "$prev_theme"
fi

echo "完成: 新截图 $shot 张，共处理 $i 个主题"

# 收尾校验：跑完批量，渲染产物应该就是 theme/current 那套色。
# 曾观察到一次「状态文件已恢复、产物还停在上一个主题」的静默不一致（复现不出来），
# 生活中不想再靠肉眼发现，这里断言一下。
_self_check() {
  local theme want have
  theme="$(cat "$STATE_FILE" 2>/dev/null || true)"
  [ -n "$theme" ] && [ -f "$COLORS_DIR/$theme/colors.toml" ] || return 0
  [ -f "$XDG_CONFIG_HOME/alacritty/colors.toml" ] || return 0
  want="$(sed -n 's/^background *= *"\([^"]*\)".*/\1/p' "$COLORS_DIR/$theme/colors.toml" | head -1)"
  have="$(sed -n 's/^background *= *"\([^"]*\)".*/\1/p' "$XDG_CONFIG_HOME/alacritty/colors.toml" | head -1)"
  if [ -n "$want" ] && [ -n "$have" ] && [ "$want" != "$have" ]; then
    echo "警告: theme/current=$theme (background $want) 但渲染产物是 $have——恢复没生效" >&2
  fi
}
_self_check
