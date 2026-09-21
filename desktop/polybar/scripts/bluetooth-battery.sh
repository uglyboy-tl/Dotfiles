#!/usr/bin/env bash
# 显示本地配置中指定的蓝牙设备电量,支持多设备(每节一个设备)。
# 未连接或无电量信息的设备跳过;全部跳过则输出空行,polybar 会隐藏该模块。
# 配置:~/.config/local/polybar/bluetooth-battery.conf

set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/local/polybar/bluetooth-battery.conf"

hide() {
    printf '\n'
    exit 0
}

# MAC -> 电量百分比(无则输出空)
battery_of() {
    local mac="$1" path raw pct=""
    path="$(busctl --system tree org.bluez 2>/dev/null | grep -oP "/org/bluez/hci\d+/dev_${mac//:/_}" | head -1 || true)"
    if [ -n "$path" ]; then
        raw="$(busctl --system get-property org.bluez "$path" org.bluez.Battery1 Percentage 2>/dev/null || true)"
        pct="${raw##* }"
    fi
    if ! [[ "$pct" =~ ^[0-9]+$ ]]; then
        pct="$(bluetoothctl info "$mac" 2>/dev/null | grep -oP 'Battery Percentage:.*\(\K[0-9]+' || true)"
    fi
    if [[ "$pct" =~ ^[0-9]+$ ]]; then
        printf '%s' "$pct"
    fi
    return 0
}

# 名称 -> 已连接设备的 MAC
resolve_mac() {
    bluetoothctl devices Connected 2>/dev/null | grep -F "$1" | head -1 | cut -d' ' -f2 || true
}

out=""

# mac name icon -> 追加到 out
emit() {
    local mac="$1" name="$2" icon="$3" pct
    [ -n "$mac" ] || [ -n "$name" ] || return 0
    [ -n "$mac" ] || mac="$(resolve_mac "$name")"
    [ -n "$mac" ] || return 0
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" || return 0
    pct="$(battery_of "$mac")"
    [ -n "$pct" ] || return 0
    if [ -n "$icon" ]; then
        out+="${out:+  }${icon} ${pct}%"
    else
        out+="${out:+  }${pct}%"
    fi
    return 0
}

mac="" name="" icon=""
flush() {
    emit "$mac" "$name" "$icon"
    mac="" name="" icon=""
}

[ -r "$config" ] || hide

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        '' | \;* | '#'*)
            continue
            ;;
        \[*\])
            flush
            ;;
        *'='*)
            key="${line%%=*}"
            val="${line#*=}"
            key="$(printf '%s' "$key" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
            val="$(printf '%s' "$val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            case "$key" in
                mac) mac="$val" ;;
                name) name="$val" ;;
                icon) icon="$val" ;;
            esac
            ;;
    esac
done < "$config"
flush

[ -n "$out" ] || hide
printf '%s\n' "$out"
