#!/usr/bin/env bash
# setting-font.sh - 字体切换：改写 fontconfig 的 monospace 字体族，
# 让 ghostty/alacritty 等用 monospace 的软件统一换字体（无需改各软件配置）。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"
FONTS_CONF="${FONTS_CONF:-$XDG_CONFIG_HOME/fontconfig/fonts.conf}"

# 公共函数与 stdout 安全
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
epipe_init

# 列出可用等宽字体（去重，取 family[0]）：spacing=100 或名称含等宽特征，排除非终端噪音
get_fonts() {
  # 一次 fc-list + 一趟 awk：fc-list 要枚举全部字体，多跑几次代价高
  fc-list -f "%{family[0]}\t%{spacing}\n" 2>/dev/null |
    awk -F'\t' '
      $2 == 100 { print $1; next }
      tolower($1) ~ /mono|maple|iosevka|jetbrains|firacode|cascadia|monaco/ { print $1; next }
      $1 ~ /等宽/ || $1 ~ /等距/ { print $1; next }
      $1 ~ /Noto Sans Mono/ { print $1 }
    ' |
    grep -viE "emoji|signwriting|CJK|IPAGothic|Unifont|点阵|屏幕读|Sample|Standard Symbol|文泉驿点阵" | sort -u
}

# 读取当前 monospace 字体（fontconfig 权威源）
get_current_font() {
  fc-match monospace -f '%{family}\n' 2>/dev/null | head -n1 | tr ',' '\n' | head -n1
}

# 把所选字体设为 monospace 第一位，并保持固定回退链：
# Hack(拉丁+图标) → Sarasa(中文) → Noto(CJK补充) → Maple(其他)；其他字体一律移除。
apply_font() {
  local font="$1" rc=0
  local conf="$FONTS_CONF"

  if [ ! -f "$conf" ]; then
    notify_error "fontconfig 配置不存在: $conf"
    return 1
  fi

  awk -v font="$font" '
    function emit_strings() {
      # 用户选择字体置顶; 若已在回退链中则不重复
      print "      <string>" font "</string>"
      if (font != "Hack Nerd Font Mono") print "      <string>Hack Nerd Font Mono</string>"
      if (font != "Sarasa Mono SC") print "      <string>Sarasa Mono SC</string>"
      if (font != "Noto Sans Mono CJK SC") print "      <string>Noto Sans Mono CJK SC</string>"
      if (font != "Maple Mono Normal CN") print "      <string>Maple Mono Normal CN</string>"
    }
    # 标记: 检测到 monospace 的 test 块(避免与其他字体族混淆)
    /<string>monospace<\/string>/ { in_mono_test = 1 }
    in_mono_test && /<edit name="family"/ {
      print            # 保留 edit 行
      emit_strings()   # 输出新字体列表
      in_mono_skip = 1  # 跳过旧字体列表
      in_mono_test = 0
      next
    }
    in_mono_skip {
      if (/<\/edit>/) { in_mono_skip = 0; print }
      next
    }
    { print }
  ' "$conf" > "${conf}.tmp" || rc=$?
  if [ "$rc" -eq 0 ]; then
    cat "${conf}.tmp" > "$conf" || rc=$?
  fi
  rm -f "${conf}.tmp"
  return "$rc"
}

# 选择字体（设置全局 FONT；用户取消时退出脚本）
select_font() {
  local current fonts_data
  current="$(get_current_font)"
  fonts_data="$(get_fonts)"
  FONT=$(select_ui \
    -p "当前字体：${current:-无}" \
    -d "$fonts_data" \
    -s "$current" \
    -i "$DOTFILES_DIR/settings/lib/font-sample.sh {}") || exit 0
}

validate_font() {
  if ! fc-list -f "%{family[0]}\n" 2>/dev/null | grep -Fxq "$1"; then
    notify_error "字体 '$1' 未安装，已忽略"
    return 1
  fi
  return 0
}

# 应用指定字体：写入 fonts.conf 即生效；耗时的收尾（fc-cache/ghostty 重解析）丢后台不阻塞
apply_font_run() {
  local font="$1"
  validate_font "$font" || return 1
  apply_font "$font" || return 1
  notify "已切换到字体: $font"
  ( fc-cache -f >/dev/null 2>&1; pkill -USR2 -x ghostty >/dev/null 2>&1 ) &
}

# 循环模式：选择 → 应用 → 回到选择界面（校验失败不退出）
loop_mode() {
  while true; do
    select_font
    apply_font_run "$FONT" || continue
  done
}

main() {
  if [ "$#" -ge 1 ]; then
    apply_font_run "$1"
  else
    loop_mode
  fi
}

main "$@"