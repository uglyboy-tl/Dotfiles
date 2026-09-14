#!/usr/bin/env bash
# 字体切换脚本
# 用法:
#   setting-font.sh <字体名>    直接切换到指定字体（单次）
#   setting-font.sh             交互式选择/循环切换（界面由 SELECTOR_UI 决定: gui=rofi, tui=fzf）
#
# 通过修改 fontconfig 的 monospace 字体族，让 ghostty/alacritty 等
# 使用 monospace 的软件统一换字体（无需改各软件配置）。

set -euo pipefail

: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"
FONTS_CONF="${FONTS_CONF:-$XDG_CONFIG_HOME/fontconfig/fonts.conf}"

# 加载公共函数(含 epipe_init)并初始化 stdout 安全
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
epipe_init

# 列出可用等宽字体（去重，取 family[0]）
# 取间距=100 的标准等宽 + 名称含等宽特征(mono/ete/maple 等)的字体,
# 仅排除明显非终端的噪音(emoji/符号/点阵/屏幕阅读版)。
get_fonts() {
  {
    fc-list :spacing=100 -f "%{family[0]}\n" 2>/dev/null
    fc-list -f "%{family[0]}\n" 2>/dev/null | grep -iE "mono|maple|iosevka|jetbrains|firacode|cascadia|monaco"
    fc-list -f "%{family[0]}\n" 2>/dev/null | grep -E "等宽|等距"
    fc-list -f "%{family[0]}\n" 2>/dev/null | grep "Noto Sans Mono"
  } | grep -viE "emoji|signwriting|CJK|IPAGothic|Unifont|点阵|屏幕读|Sample|Standard Symbol|文泉驿点阵" | sort -u
}

# 读取当前 monospace 字体（fontconfig 权威源）
get_current_font() {
  fc-match monospace -f '%{family}\n' 2>/dev/null | head -n1 | tr ',' '\n' | head -n1
}

# 把所选字体设为 monospace 第一位，并保持固定的回退链字体
# 回退链: Hack(拉丁+图标) → Sarasa(中文) → Noto(CJK补充) → Maple(其他)
# 其他任何字体要么成为第一位主字体，要么被移除，以防止破坏字体回退。
# 用 awk 改写 fonts.conf 的 monospace 块，避免依赖 python。
apply_font() {
  local font="$1"
  local conf="$FONTS_CONF"

  if [ ! -f "$conf" ]; then
    notify_error "fontconfig 配置不存在: $conf"
    return 1
  fi

  cp "$conf" "${conf}.bak"
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
  ' "$conf" > "${conf}.tmp" && cat "${conf}.tmp" > "$conf"
  rc=$?
  rm -f "${conf}.tmp" "${conf}.bak"
  return $rc
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

# 校验所选字体
validate_font() {
  if ! fc-list -f "%{family[0]}\n" 2>/dev/null | grep -Fxq "$1"; then
    notify_error "字体 '$1' 未安装，已忽略"
    return 1
  fi
  return 0
}

# 应用指定字体（单次）
# 设置写进 fonts.conf 即算切换完成（新开窗口即刻生效），随后立即提示并返回；
# 耗时的收尾（fc-cache 重建缓存、让 ghostty 重新解析字体）全部丢后台，不阻塞菜单。
apply_font_run() {
  local font="$1"
  validate_font "$font" || return 1
  apply_font "$font" || return 1
  notify "已切换到字体: $font"
  ( fc-cache -f >/dev/null 2>&1; pkill -USR2 -x ghostty >/dev/null 2>&1 ) &
}

# 循环模式：选择 → 应用 → 回到选择界面
# 非法输入(validate 失败)时返回非零，此处不退出，继续回到选择界面
loop_mode() {
  while true; do
    select_font
    apply_font_run "$FONT" || continue
  done
}

# 主流程
main() {
  if [ "$#" -ge 1 ]; then
    # 指定字体名，单次应用
    apply_font_run "$1"
  else
    # 交互式循环
    loop_mode
  fi
}

main "$@"