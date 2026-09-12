#!/usr/bin/env bash
# 内容展示层: 把带 ANSI 颜色的命令输出统一展示
#   TUI: fzf 预览窗格 (ansi-to-ansi.py 保留颜色/对齐)
#   GUI: rofi 只读窗 (viewer.rasi + ansi-to-pango.py 转 Pango)
# 作为函数库被其他脚本 source

[[ -n "${_SHOW_LOADED:-}" ]] && return 0
_SHOW_LOADED=1

: "${XDG_DATA_HOME:=$HOME/.local/share}"
DOTFILES_DIR="$XDG_DATA_HOME/dotfiles"

_show_colors_file() {
  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}"
  local theme_name
  theme_name="$(cat "$state_dir/theme/current" 2>/dev/null || echo tokyo-night)"
  printf '%s\n' "$DOTFILES_DIR/themes/colors/$theme_name/colors.toml"
}

# 解析 <完整命令> [--prompt <提示>] 形式的参数
_show_parse_args() {
  _SHOW_CMD="$1"; shift
  _SHOW_PROMPT="预览"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt) _SHOW_PROMPT="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
}

# TUI: fzf 预览窗格展示命令输出(保留 ANSI 颜色)
# 用法: show_terminal <完整命令> [--prompt <提示>]
show_terminal() {
  _show_parse_args "$@"
  [ -n "$_SHOW_CMD" ] || { echo "show_terminal: 缺少命令" >&2; return 1; }

  local converter="$DOTFILES_DIR/settings/lib/ansi-to-ansi.py"
  local colors_file; colors_file="$(_show_colors_file)"
  local placeholder="(预览) - 按 Esc/← 返回"

  echo "$placeholder" | fzf \
    --prompt "$_SHOW_PROMPT " \
    --height 100% \
    --border \
    --no-sort \
    --no-input \
    --preview "eval $_SHOW_CMD 2>/dev/null | python3 $converter --colors $colors_file 2>/dev/null" \
    --preview-window "up:92%:wrap" \
    --bind "left:abort,right:accept,esc:abort" \
    >/dev/null 2>&1 || true
}

# GUI: rofi 只读窗展示命令输出(转 Pango)
# 用法: show_gui <完整命令> [--prompt <提示>]
show_gui() {
  _show_parse_args "$@"
  [ -n "$_SHOW_CMD" ] || { echo "show_gui: 缺少命令" >&2; return 1; }

  local converter="$DOTFILES_DIR/settings/lib/ansi-to-pango.py"
  local rasi="$DOTFILES_DIR/settings/rofi/viewer.rasi"
  local colors_file; colors_file="$(_show_colors_file)"

  eval "$_SHOW_CMD" 2>/dev/null \
    | python3 "$converter" --colors "$colors_file" 2>/dev/null \
    | rofi -dmenu -markup-rows -no-custom \
        -theme "$rasi" \
        -p "$_SHOW_PROMPT" >/dev/null 2>&1 || true
}

# 按 SELECTOR_UI 分派: gui -> rofi, 其他 -> fzf
# 用法: show_content <完整命令> [--prompt <提示>]
show_content() {
  case "${SELECTOR_UI:-tui}" in
    gui) show_gui "$@" ;;
    *)   show_terminal "$@" ;;
  esac
}
