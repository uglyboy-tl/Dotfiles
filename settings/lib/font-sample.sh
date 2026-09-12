#!/usr/bin/env bash
# 输出字体预览样张的缓存路径（按需用 ImageMagick 渲染）
# 用法: font-sample.sh <字体家族名>
# 字体无法解析或缺 ImageMagick 时无输出（调用方据此跳过预览）
set -euo pipefail

: "${XDG_CACHE_HOME:=$HOME/.cache}"

family="${1:-}"
[ -n "$family" ] || exit 0

cache_dir="$XDG_CACHE_HOME/font-preview"
mkdir -p "$cache_dir"
safe="$(printf '%s' "$family" | tr -c 'A-Za-z0-9._-' '_')"
# 非 ASCII 名经 tr 会变纯下划线，加短哈希避免不同家族撞名
hash="$(printf '%s' "$family" | md5sum | cut -c1-8)"
cache_ver="v2"  # 样张内容变化时递增，使旧缓存失效
cache="$cache_dir/$safe-$hash.$cache_ver.png"
src="$cache.src"

# 缓存命中：样张与旁车都在，且旁车记录的源字体 mtime 未变（命中时不跑 fc-match）
if [ -f "$cache" ] && [ -f "$src" ]; then
  cache_src_file=""
  cache_src_mtime=""
  IFS=$'\t' read -r cache_src_file cache_src_mtime < "$src" || true
  if [ -n "$cache_src_file" ] && [ -f "$cache_src_file" ] \
    && [ "$(stat -c %Y -- "$cache_src_file" 2>/dev/null || echo x)" = "$cache_src_mtime" ]; then
    printf '%s' "$cache"
    exit 0
  fi
fi

# 未命中：解析字体文件，并确认请求的家族在命中字体的家族别名列表里
# （避免 fc-match 对不存在的字体回退到 Noto 之类）
font_file="$(fc-match -f '%{file}' -- "$family" 2>/dev/null || true)"
font_families="$(fc-match -f '%{family}' -- "$family" 2>/dev/null || true)"
[ -n "$font_file" ] && [ -f "$font_file" ] || exit 0
printf '%s' "$font_families" | tr ',' '\n' | grep -Fqx -- "$family" || exit 0

magick_bin="$(command -v magick || command -v convert || true)"
[ -n "$magick_bin" ] || exit 0

# 样张：英文/符号/数字 + 中文 + Nerd Font 图标（字体本身缺的字形会留白）
icons=$'\uf015 \uf07b \uf121 \uf0ad \ue0b0 \ue0b2'
sample="ABCDEFGHIJKLMNO
PQRSTUVWXYZ abcdefg
hijklmnopqrstuvwxyz
0123456789 !\$&*()[]{}@#
中文预览：天地玄黄 你好世界
图标：$icons
等宽：ilI1|O0 <> {}"

tmp="$cache.$$.png"
if "$magick_bin" -size 900x560 -gravity center -font "$font_file" -pointsize 46 \
  xc:white -fill black -annotate +0+0 "$sample" "$tmp" 2>/dev/null; then
  mv -f "$tmp" "$cache"
  printf '%s\t%s\n' "$font_file" "$(stat -c %Y -- "$font_file")" > "$src"
  printf '%s' "$cache"
else
  rm -f "$tmp"
fi
exit 0
