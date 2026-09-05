#! /bin/sh
wid=$1
class=$2
instance=$3
consequences=$4

result() {
    eval "$consequences"
    [ "$state" ] || echo "$1"
}

role=$(xprop -id "$wid" WM_WINDOW_ROLE 2>/dev/null)
wtype=$(xprop -id "$wid" _NET_WM_WINDOW_TYPE 2>/dev/null)
transient=$(xprop -id "$wid" WM_TRANSIENT_FOR 2>/dev/null)
wstate=$(xprop -id "$wid" _NET_WM_STATE 2>/dev/null)

case "$wstate" in
    *_NET_WM_STATE_STICKY*)
        case "$wstate" in
            *_NET_WM_STATE_ABOVE*)
                result "state=floating sticky=on layer=above"
                ;;
        esac
        ;;
esac

case "$wtype" in
    *_NET_WM_WINDOW_TYPE_DIALOG*)
        result "state=floating"
        ;;
esac

case "$transient" in
    *not\ found*|'') ;;
    *) result "state=floating" ;;
esac

case "$instance" in
    microsoft-edge|crx__*)
        case "$role" in
            *pop-up*)
                result "state=floating"
                ;;
        esac
        ;;
esac