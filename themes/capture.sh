#!/usr/bin/env bash
# 主题预览截图（不含主题切换）
# 固定 tmux 布局 -> 切分辨率 -> 在桌面 III 开 ghostty(平铺) -> 截图 -> 清理
#
# 用法:
#   capture.sh <输出图片路径>
#
# 截图会压缩后写出（缩到 1280 宽 + JPEG q85），建议输出 .jpg。
#
# 场景布局（来自当前 tmux 会话，4 个 pane）:
#   ┌──────────────┬──────────────┐
#   │ fetch        │ vim          │
#   │              │ ~/Code/BashDev/src
#   ├──────────────┼──────────────┤
#   │ yazi         │ neomutt      │
#   │ ~/Code/InkWeave
#   └──────────────┴──────────────┘

set -euo pipefail

OUT="${1:?用法: capture.sh <输出图片路径>}"

XOUT="DP-0"
MODE_CAPTURE="2560x1440"   # 截图用的 16:9 分辨率
MODE_NATIVE="3440x1440"    # 用完恢复
DESKTOP="III"
SESSION="theme-shot"
GHOSTTY_CLASS="com.mitchellh.ghostty"

# 每个 pane 的命令
CMD_TL='fetch'
CMD_TR='cd "$HOME/Code/BashDev/src" && vim example.sh'
CMD_BR='neomutt'
CMD_BL='cd "$HOME/Code/InkWeave" && yazi'

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

prev_desktop="$(bspc query -D -d focused --names 2>/dev/null || true)"
win=""
tmp=""

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
  [ -n "$win" ] && bspc node "$win" -c 2>/dev/null || true
  [ -n "$tmp" ] && rm -f "$tmp"
  xrandr --output "$XOUT" --mode "$MODE_NATIVE" >/dev/null 2>&1 || true
  [ -n "$prev_desktop" ] && bspc desktop -f "$prev_desktop" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# 关掉桌面 III 上已有的 ghostty，保证舞台干净
for id in $(bspc query -N -d "$DESKTOP" 2>/dev/null || true); do
  cls="$(bspc query -T -n "$id" | jq -r '.client.className // empty')"
  if [ "$cls" = "$GHOSTTY_CLASS" ]; then
    pid="$(bspc query -T -n "$id" | jq -r '.client.pid // empty')"
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  fi
done

# 建 tmux 会话与 4 个 pane
tmux kill-session -t "$SESSION" 2>/dev/null || true
tmux new-session -d -s "$SESSION" -n shot -x 308 -y 64
W="$SESSION:shot"
tmux split-window -h -t "$W"
tmux split-window -v -t "$W"
tmux split-window -v -t "$W"

# 取实际 pane id（按 index 顺序：1 左上 / 2 左下 / 3 右上 / 4 右下）
# select-layout 按 pane index 顺序套用到布局叶子顺序，id 仅作校验
mapfile -t IDS < <(tmux list-panes -t "$W" -F '#{pane_id}' | tr -d '%')
BODY="$(layout_body "${IDS[0]}" "${IDS[1]}" "${IDS[2]}" "${IDS[3]}")"
tmux select-layout -t "$W" "$(layout_checksum "$BODY"),$BODY"

# 发送各 pane 命令（与上面 index 顺序对应）
tmux send-keys -t "%${IDS[0]}" "$CMD_TL" Enter
tmux send-keys -t "%${IDS[1]}" "$CMD_BL" Enter
tmux send-keys -t "%${IDS[2]}" "$CMD_TR" Enter
tmux send-keys -t "%${IDS[3]}" "$CMD_BR" Enter
tmux select-pane -t "%${IDS[0]}"

# 切换分辨率并聚焦桌面 III
xrandr --output "$XOUT" --mode "$MODE_CAPTURE"
bspc desktop -f "$DESKTOP"
sleep 1

# 打开 ghostty 并确保平铺
ghostty -e tmux attach -t "$SESSION" >/dev/null 2>&1 &
sleep 3
for id in $(bspc query -N -d "$DESKTOP" 2>/dev/null || true); do
  cls="$(bspc query -T -n "$id" | jq -r '.client.className // empty')"
  if [ "$cls" = "$GHOSTTY_CLASS" ]; then
    win="$id"
    bspc node "$id" -t tiled 2>/dev/null || true
  fi
done

# 等应用渲染
sleep 6

# 截图：先存 PNG 临时文件，再压缩（缩到 1280 宽 + JPEG q85）后写出
tmp="$(mktemp --suffix=.png)"
maim -u "$tmp"
magick "$tmp" -resize "1280x1280>" -strip -quality 85 "$OUT"
echo "已保存: $OUT ($(du -h "$OUT" | cut -f1))"
