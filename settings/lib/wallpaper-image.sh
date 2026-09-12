#!/usr/bin/env bash
# 输出某个壁纸风格用于预览的图片路径（固定取 12 点图）
# 用法: wallpaper-image.sh <风格名>
# 找不到时无输出（调用方可据此跳过预览）
set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"

style="${1:-}"
dir="$XDG_DATA_HOME/dynamic-wallpaper/images/$style"

for ext in jpg png; do
  img="$dir/12.$ext"
  if [ -f "$img" ]; then
    printf '%s' "$img"
    exit 0
  fi
done
exit 0
