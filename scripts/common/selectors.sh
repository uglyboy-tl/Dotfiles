#!/usr/bin/env bash
# 通用选择器函数
# 提供 fzf 和 rofi 两种选择界面，供其他脚本复用。

# 防止重复加载
[[ -n "${_SELECTORS_LOADED:-}" ]] && return 0
_SELECTORS_LOADED=1

: "${XDG_STATE_HOME:=$HOME/.local/state}"

# UI 模式: gui(rofi) | tui(fzf)。由入口(如 settings)决定并导出，
# 子脚本通过调用 select_ui 读取，无需再关心具体界面类型。
: "${SELECTOR_UI:=tui}"

# ============================================================
# 轻量化 stdout 安全：处理从 sxhkd(快捷键)启动时 stdout 是 socket 的问题
# ============================================================

# 忽略 SIGPIPE 并把标准输出/错误重定向到日志文件(仅当 stdout 非终端时)。
# 从 sxhkd(快捷键)启动时 stdout 是 socket, echo 到无读方管道会 EPIPE,
# 在 set -e 下中断脚本; 命令行走 tty 无此问题且保留终端输出。
# 交互值经命令替换返回, 不受重定向影响。
# 用法: 在脚本顶部(定义完变量后)调用 epipe_init
epipe_init() {
  trap '' PIPE
  if ! [ -t 1 ]; then
    local log="${XDG_STATE_HOME}/settings/logs/$(basename "${0:-script}").log"
    mkdir -p "$(dirname "$log")"
    exec >> "$log" 2>&1
  fi
}

# fzf 选择器
# 用法: fzf_selector [选项]
#   -p, --prompt <提示>    选择提示（默认"选择"）
#   -h, --header <标题>    标题信息
#   -d, --data <数据>      选择数据（换行分隔）
#   -s, --selected <内容>  当前选中项（用于定位）
#   -H, --height <高度>    高度百分比（默认40%）
#
# 返回: 用户选择的内容（通过 stdout）
# 返回码: 0=成功, 1=取消
fzf_selector() {
  local prompt="选择"
  local header=""
  local data=""
  local selected=""
  local height="40%"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--prompt)  prompt="$2"; shift 2 ;;
      -h|--header)  header="$2"; shift 2 ;;
      -d|--data)    data="$2"; shift 2 ;;
      -s|--selected) selected="$2"; shift 2 ;;
      -H|--height)  height="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # 计算选中行号
  local selected_row=0
  if [[ -n "$selected" && -n "$data" ]]; then
    local i=0
    while IFS= read -r line; do
      if [[ "$line" == "$selected" ]]; then
        selected_row=$i
        break
      fi
      ((i++))
    done <<< "$data"
  fi

  # 构建 fzf 参数
  local fzf_args=(
    --prompt "$prompt"
    --height "$height"
    --border
    --no-preview
  )

  [[ -n "$header" ]] && fzf_args+=(--header "$header")
  [[ $selected_row -gt 0 ]] && fzf_args+=(--bind "load:pos:$((selected_row + 1))")

  # 执行 fzf
  local result
  result=$(echo "$data" | fzf "${fzf_args[@]}" 2>/dev/null) || return 1
  echo "$result"
}

# rofi 选择器
# 用法: rofi_selector [选项]
#   -p, --prompt <提示>    选择提示（默认"选择"）
#   -d, --data <数据>      选择数据（换行分隔）
#   -s, --selected <内容>  当前选中项（用于定位）
#
# 返回: 用户选择的内容（通过 stdout）
# 返回码: 0=成功, 1=取消
rofi_selector() {
  local prompt="选择"
  local data=""
  local selected=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--prompt)  prompt="$2"; shift 2 ;;
      -d|--data)    data="$2"; shift 2 ;;
      -s|--selected) selected="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # 计算选中行号
  local selected_row=0
  if [[ -n "$selected" && -n "$data" ]]; then
    local i=0
    while IFS= read -r line; do
      if [[ "$line" == "$selected" ]]; then
        selected_row=$i
        break
      fi
      ((i++))
    done <<< "$data"
  fi

  # 执行 rofi
  local result
  result=$(echo "$data" | rofi -dmenu -theme custom -p "$prompt" -selected-row "$selected_row") || return 1
  echo "$result"
}

# 统一选择器：按 SELECTOR_UI 自动分派 rofi/fzf，调用方无需关心界面类型。
# 参数与 fzf_selector/rofi_selector 一致。
# 用法: select_ui -p <提示> -d <数据> [-s <当前选中>]
select_ui() {
  if [ "$SELECTOR_UI" = "gui" ]; then
    rofi_selector "$@"
  else
    fzf_selector "$@"
  fi
}

# 检测当前环境是否支持 GUI(rofi)：需 rofi 可用且有图形会话。
selector_gui_supported() {
  command -v rofi >/dev/null 2>&1 \
    && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }
}
