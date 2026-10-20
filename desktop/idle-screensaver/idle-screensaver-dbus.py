#!/usr/bin/env python3
# idle-screensaver-dbus.py - 提供 org.freedesktop.ScreenSaver 抑制接口，写心跳文件
# $XDG_RUNTIME_DIR/idle-screensaver/dbus-inhibit 供 idle-screensaver.sh 读取。
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
# 历史路径与规范路径都注册：Chromium 用前者，老程序仍用后者
PATHS = ("/org/freedesktop/ScreenSaver", "/ScreenSaver")
STATE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "idle-screensaver"
HEARTBEAT = STATE_DIR / "dbus-inhibit"
HEARTBEAT_MS = 1000  # idle-screensaver.sh 侧的阈值是它的 5 倍


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
        # xdg-screensaver reset 走这里：没有 API 能把 xprintidle 归零，只能 xset s reset；1 秒节流
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
            return  # 只关心唯一名消失
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
