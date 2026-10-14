#!/bin/sh
# 外部窗口规则：按 class/instance/title 匹配窗口属性
# bspwm 通过 external_rules_command 调用此脚本

wid=$1
class=$2
instance=$3
consequences=$4

# 获取窗口标题（优先 _NET_WM_NAME，回退到 WM_NAME）
title=$(xprop -id "$wid" _NET_WM_NAME 2>/dev/null | sed 's/.*= "\(.*\)"/\1/')
[ -n "$title" ] || title=$(xprop -id "$wid" WM_NAME 2>/dev/null | sed 's/.*= "\(.*\)"/\1/')

# 获取窗口属性
role=$(xprop -id "$wid" WM_WINDOW_ROLE 2>/dev/null)
wtype=$(xprop -id "$wid" _NET_WM_WINDOW_TYPE 2>/dev/null)
transient=$(xprop -id "$wid" WM_TRANSIENT_FOR 2>/dev/null)
wstate=$(xprop -id "$wid" _NET_WM_STATE 2>/dev/null)

result() {
    eval "$consequences"
    [ "$state" ] || echo "$1"
}

# 置顶 + 粘性窗口（如画中画播放器）
case "$wstate" in
    *_NET_WM_STATE_STICKY*)
        case "$wstate" in
            *_NET_WM_STATE_ABOVE*)
                result "state=floating sticky=on layer=above"
                ;;
        esac
        ;;
esac

# 对话框窗口默认浮动
case "$wtype" in
    *_NET_WM_WINDOW_TYPE_DIALOG*)
        result "state=floating"
        ;;
esac

# 有父窗口的窗口（transient）浮动
case "$transient" in
    *not\ found*|'') ;;
    *) result "state=floating" ;;
esac

# Edge 浏览器的弹窗（Bitwarden、画中画等）
case "$instance" in
    microsoft-edge|crx__*)
        case "$role" in
            *pop-up*)
                result "state=floating"
                ;;
        esac
        ;;
esac

# 按标题匹配：画中画窗口
case "$title" in
    *"Picture-in-Picture"*|*"Picture in picture"*|*"画中画"*)
        result "state=floating sticky=on layer=above center=on rectangle=640x360+1280+80"
        ;;
esac

# 按标题匹配：Bitwarden 解锁弹窗
case "$title" in
    *"Bitwarden"*"locked"*|*"Bitwarden"*"解锁"*|*"Vault"*)
        result "state=floating center=on"
        ;;
esac

# 按标题匹配：密码输入框（各种应用的认证弹窗）
case "$title" in
    *"Authentication"*|*"密码"*|*"Password"*|*"Enter password"*)
        result "state=floating center=on"
        ;;
esac

# 按标题匹配：下载对话框
case "$title" in
    *"Save As"*|*"Save as"*|*"另存为"*|*"Download"*|*"下载"*)
        result "state=floating center=on"
        ;;
esac

# 按标题匹配：更新提示
case "$title" in
    *"Update Available"*|*"更新可用"*|*"Software Update"*)
        result "state=floating center=on"
        ;;
esac
