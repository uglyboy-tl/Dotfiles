#!/bin/bash
# opencode provider quota monitor - 长驻模式
# tail=true 常驻进程,点击发 USR1 信号立即切换,像 internal/date 一样快

AUTH_FILE="$HOME/.local/share/opencode/auth.json"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/polybar-opencode-cache"
CACHE_TTL=300

mkdir -p "$CACHE_DIR"

CURRENT="opencode-go"
SLEEP_PID=0

cache_valid() {
    local f="$CACHE_DIR/$1"
    [ -f "$f" ] && [ -s "$f" ] && [ $(($(date +%s) - $(stat -c %Y "$f" 2>/dev/null || echo 0))) -lt "$CACHE_TTL" ]
}

get_key() {
    case "$1" in
        opencode-go) jq -r '.["opencode-go"].key // empty' "$AUTH_FILE" 2>/dev/null ;;
        deepseek)    jq -r '.deepseek.key // empty' "$AUTH_FILE" 2>/dev/null ;;
    esac
}

get_url() {
    case "$1" in
        opencode-go) echo "https://opencode.ai/zen/go/v1/usage" ;;
        deepseek)    echo "https://api.deepseek.com/user/balance" ;;
    esac
}

fetch() {
    local provider=$1
    cache_valid "$provider" && return
    local key=$(get_key "$provider") url=$(get_url "$provider")
    [ -z "$key" ] || [ -z "$url" ] && return
    local resp=$(curl -sf --max-time 5 -H "Authorization: Bearer $key" "$url" 2>/dev/null)
    [ -n "$resp" ] && echo "$resp" > "$CACHE_DIR/$provider"
}

# 内容只输出图标+数值,样式(颜色/字体)由模块配置统一管理
render_opencode_go() {
    local data=$(cat "$CACHE_DIR/opencode-go" 2>/dev/null)
    [ -z "$data" ] && echo "--" && return
    local r=$(echo "$data" | jq -r '.usage.rolling.percent // empty')   # 5h
    local m=$(echo "$data" | jq -r '.usage.monthly.percent // empty')   # 月
    local out=""
    [ -n "$r" ] && out=" ${r}%"
    [ -n "$m" ] && { [ -n "$out" ] && out="$out "; out="${out} ${m}%"; }
    [ -z "$out" ] && out="--"
    echo "${out}"
}

render_deepseek() {
    local data=$(cat "$CACHE_DIR/deepseek" 2>/dev/null)
    [ -z "$data" ] && echo "--" && return
    local bal=$(echo "$data" | jq -r '.balance_infos[0].total_balance // empty')
    [ -z "$bal" ] && echo "--" && return
    echo " ¥${bal}"
}

render() {
    case "$CURRENT" in
        opencode-go) render_opencode_go ;;
        deepseek)    render_deepseek ;;
    esac
}

toggle() {
    [ "$CURRENT" = "deepseek" ] && CURRENT="opencode-go" || CURRENT="deepseek"
    # 打断 sleep,立即渲染输出
    [ "$SLEEP_PID" -ne 0 ] && kill "$SLEEP_PID" 2>/dev/null
    true
}

trap toggle USR1

# 启动时同步获取一次
fetch opencode-go
fetch deepseek

while true; do
    fetch opencode-go   # 缓存未过期时零开销
    fetch deepseek
    echo "$(render)"
    sleep 60 &
    SLEEP_PID=$!
    wait
done