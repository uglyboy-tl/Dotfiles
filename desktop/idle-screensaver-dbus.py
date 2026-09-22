#!/usr/bin/env python3
# idle-screensaver-dbus.py - 为自研屏保提供 org.freedesktop.ScreenSaver 抑制接口。
#
# 背景：Chromium/Firefox/mpv 播放音视频时会向会话总线申请「别让屏幕睡」（桌面环境
# 通常由 GNOME/KDE 提供该服务）。bspwm 裸装没有这个服务，请求落空后退回 X11
# XScreenSaverSuspend；而自研屏保（desktop/idle-screensaver.sh）按 xprintidle 判定
# 空闲，既看不到 D-Bus 请求也不受 XScreenSaverSuspend 影响，于是看视频照样弹屏保。
#
# 本服务不锁屏、不做 UI，只把「谁在申请抑制」写成心跳文件
#   $XDG_RUNTIME_DIR/idle-screensaver/dbus-inhibit
# 内容为 cookie/应用名/原因，每秒刷新一次 mtime；idle-screensaver.sh 认为文件
# 新鲜（<5 秒）时就不出屏保、不熄屏。心跳的好处：本服务被 kill 后抑制最多 5 秒
# 自动失效，不会留下永久的僵死抑制。
#
# 用法: idle-screensaver-dbus.py    （常驻；总线名已被占用时直接退出，不抢）
import os
import subprocess
import sys
import time
from pathlib import Path

try:
    import dbus
    import dbus.service
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib
except ImportError as e:
    print(f"idle-screensaver-dbus: 缺少依赖（{e}），跳过", file=sys.stderr)
    sys.exit(0)

IFACE = "org.freedesktop.ScreenSaver"
# 历史路径与 freedesktop 规范路径都注册：Chromium 用前者，部分老程序仍用后者
PATHS = ("/org/freedesktop/ScreenSaver", "/ScreenSaver")
STATE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "idle-screensaver"
HEARTBEAT = STATE_DIR / "dbus-inhibit"
HEARTBEAT_MS = 1000  # 心跳间隔；idle-screensaver.sh 侧的阈值是它的 5 倍


class State:
    """两个对象路径共用一份抑制状态（cookie 编号与心跳文件才不会分裂）。"""

    def __init__(self):
        self.inhibitors = {}  # cookie -> (应用名, 原因, 总线唯一名)
        self.next_cookie = 1
        self.since = 0
        self.last_reset = 0.0


def write_heartbeat(st):
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        lines = "".join(
            f"{c}\t{app}\t{reason}\n"
            for c, (app, reason, _) in sorted(st.inhibitors.items())
        )
        tmp = HEARTBEAT.with_name(HEARTBEAT.name + ".tmp")
        tmp.write_text(lines)
        os.replace(tmp, HEARTBEAT)  # 原子替换，读方不会看到半截内容
    except OSError:
        pass


def sync(st):
    """抑制者增减后同步心跳文件；没有抑制者就删掉它。"""
    if st.inhibitors:
        write_heartbeat(st)
    else:
        st.since = 0
        HEARTBEAT.unlink(missing_ok=True)


class ScreenSaver(dbus.service.Object):
    def __init__(self, bus_name, path, state):
        super().__init__(bus_name, path)
        self.state = state

    @dbus.service.method(IFACE, in_signature="ss", out_signature="u",
                         sender_keyword="sender")
    def Inhibit(self, app, reason, sender=None):
        st = self.state
        cookie = st.next_cookie
        st.next_cookie += 1
        st.inhibitors[cookie] = (app or "", reason or "", sender)
        if not st.since:
            st.since = int(time.time())
        write_heartbeat(st)
        return cookie

    @dbus.service.method(IFACE, in_signature="u", out_signature="")
    def UnInhibit(self, cookie):
        if self.state.inhibitors.pop(cookie, None) is not None:
            sync(self.state)

    @dbus.service.method(IFACE, in_signature="", out_signature="b")
    def GetActive(self):
        return bool(self.state.inhibitors)

    @dbus.service.method(IFACE, in_signature="", out_signature="u")
    def GetActiveTime(self):
        st = self.state
        return int(time.time()) - st.since if st.inhibitors else 0

    @dbus.service.method(IFACE, in_signature="", out_signature="")
    def SimulateUserActivity(self):
        # xdg-screensaver reset 走这里。没有 API 能把 xprintidle 归零，
        # 就沿用它原本的 X11 手段（XResetScreenSaver）；1 秒节流防高频刷进程。
        st = self.state
        now = time.monotonic()
        if now - st.last_reset < 1.0:
            return
        st.last_reset = now
        try:
            subprocess.run(["xset", "s", "reset"], timeout=2,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except (OSError, subprocess.SubprocessError):
            pass

    def drop_sender(self, name, old_owner, new_owner):
        """客户端从总线消失（如浏览器崩溃）时清掉它遗留的 cookie。"""
        if new_owner or not old_owner:
            return  # 只关心「唯一名消失」，不管新名字出现
        owner = old_owner
        gone = [c for c, (_, _, s) in self.state.inhibitors.items() if s == owner]
        if not gone:
            return
        for c in gone:
            self.state.inhibitors.pop(c, None)
        sync(self.state)


def tick(st):
    if st.inhibitors:
        try:
            os.utime(HEARTBEAT, None)
        except OSError:
            write_heartbeat(st)
    return True  # 继续定时


def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    try:
        name = dbus.service.BusName(IFACE, bus=bus, do_not_queue=True)
    except dbus.exceptions.DBusException:
        return 0  # 已有服务提供同名接口，让位
    st = State()
    obj = ScreenSaver(name, PATHS[0], st)
    for path in PATHS[1:]:
        ScreenSaver(name, path, st)
    bus.add_signal_receiver(obj.drop_sender, signal_name="NameOwnerChanged",
                            dbus_interface="org.freedesktop.DBus",
                            path="/org/freedesktop/DBus")
    GLib.timeout_add(HEARTBEAT_MS, tick, st)
    try:
        GLib.MainLoop().run()
    finally:
        HEARTBEAT.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
