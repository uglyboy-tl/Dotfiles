#!/usr/bin/env python3
"""rofi 系统信息面板（点击 polybar 的 CPU 模块弹出，rofi 脚本模式原地刷新）。"""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp")
CACHE = RUNTIME_DIR / "rofi-sysinfo.json"
THEME = CONFIG_HOME / "rofi" / "sysinfo.rasi"
COLORS = CONFIG_HOME / "rofi" / "colors.rasi"
BRIGHTNESS_BIN = Path.home() / ".local" / "bin" / "brightness"
BARIFY_BIN = Path.home() / ".local" / "bin" / "barify"

COLS, ROWS = 6, 2
STEP = 5  # 音量/亮度单次步进（%）
SAMPLE_INTERVAL = 0.2  # 没有上次读数时的采样窗口
CACHE_MAX_AGE = 10  # 复用上次计数器的最大间隔（秒）
CACHE_MIN_AGE = 0.15  # 间隔太短会放大误差


def theme_color(name: str, fallback: str) -> str:
    """颜色取自主题渲染出的 colors.rasi，跟随主题。"""
    try:
        for line in COLORS.read_text().splitlines():
            if line.strip().startswith(f"{name}:"):
                return line.split(":", 1)[1].strip().rstrip(";")
    except OSError:
        pass
    return fallback


def label(text: str) -> str:
    return f"<span color='{theme_color('muted', '#9d9d9d')}'>{text}</span>"


def button(symbol: str, action: str) -> str:
    color = theme_color("accent", "#33b1ff")
    return f"<span color='{color}'>{symbol}</span>\0info\x1f{action}"


def read_cpu_times() -> list[int]:
    with open("/proc/stat") as f:
        return [int(x) for x in f.readline().split()[1:]]


def read_net_bytes(iface: str | None) -> tuple[int, int]:
    if not iface:
        return 0, 0
    base = Path("/sys/class/net") / iface / "statistics"
    try:
        return (
            int((base / "rx_bytes").read_text()),
            int((base / "tx_bytes").read_text()),
        )
    except OSError:
        return 0, 0


def default_iface() -> str | None:
    """默认路由所在网卡；没有默认路由则不显示速率。"""
    try:
        with open("/proc/net/route") as f:
            for line in list(f)[1:]:
                parts = line.split()
                if len(parts) > 1 and parts[1] == "00000000":
                    return parts[0]
    except OSError:
        pass
    return None


def cpu_percent(before: list[int], after: list[int]) -> float:
    idle = (after[3] + after[4]) - (before[3] + before[4])
    total = sum(after) - sum(before)
    return 0.0 if total <= 0 else 100.0 * (total - idle) / total


def sample_usage() -> tuple[float, float, str | None]:
    """返回 (CPU%, 网络 B/s, 网卡)；优先与缓存的上次读数做区间平均，否则实时双采样。"""
    iface = default_iface()
    now = time.time()
    cpu_before, net_before = read_cpu_times(), read_net_bytes(iface)

    cached = None
    try:
        data = json.loads(CACHE.read_text())
        if CACHE_MIN_AGE < now - data["ts"] < CACHE_MAX_AGE and data.get("iface") == iface:
            cached = data
    except (OSError, ValueError, KeyError, TypeError):
        pass

    if cached:
        span = now - cached["ts"]
        cpu = cpu_percent(cached["cpu"], cpu_before)
        net = (sum(net_before) - sum(cached["net"])) / span
    else:
        time.sleep(SAMPLE_INTERVAL)
        cpu_after, net_after = read_cpu_times(), read_net_bytes(iface)
        cpu = cpu_percent(cpu_before, cpu_after)
        net = (sum(net_after) - sum(net_before)) / SAMPLE_INTERVAL
        cpu_before, net_before, now = cpu_after, net_after, time.time()

    try:
        CACHE.write_text(
            json.dumps(
                {"ts": now, "cpu": cpu_before, "net": list(net_before), "iface": iface}
            )
        )
    except OSError:
        pass

    return cpu, net, iface


def mem_percent(key_used_from: str = "MemAvailable") -> float:
    info = {}
    with open("/proc/meminfo") as f:
        for line in f:
            name, value = line.split(":", 1)
            info[name] = int(value.split()[0])
    total = info["MemTotal"]
    used = total - info.get(key_used_from, info.get("MemFree", 0))
    return 100.0 * used / total


def swap_percent() -> float | None:
    info = {}
    with open("/proc/meminfo") as f:
        for line in f:
            name, value = line.split(":", 1)
            info[name] = int(value.split()[0])
    total = info.get("SwapTotal", 0)
    if not total:
        return None
    return 100.0 * (total - info.get("SwapFree", 0)) / total


def temp_c() -> int | None:
    """CPU 温度：优先 CPU 专用 zone，回退到第一个可用 zone。"""
    preferred = ("x86_pkg_temp", "coretemp", "cpu-thermal", "k10temp")
    zones = {}
    for zone in sorted(Path("/sys/class/thermal").glob("thermal_zone*")):
        try:
            zones[zone.joinpath("type").read_text().strip()] = zone
        except OSError:
            continue

    chosen = next((zones[name] for name in preferred if name in zones), None)
    if chosen is None and zones:
        chosen = next(iter(zones.values()))
    if chosen is None:
        return None

    try:
        return round(int(chosen.joinpath("temp").read_text().strip()) / 1000)
    except (OSError, ValueError):
        return None


def volume() -> str | None:
    try:
        out = subprocess.run(
            ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
            check=False, capture_output=True,
            text=True,
            timeout=1,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return None
    if "MUTED" in out:
        return "静音"
    match = re.search(r"([\d.]+)", out)
    return f"{round(float(match.group(1)) * 100)}%" if match else None


def brightness() -> str | None:
    """ddcutil 单次往返约 300ms，只读 brightness 脚本维护的状态文件。"""
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    try:
        return f"{int((state / 'brightness' / 'current').read_text().strip())}%"
    except (OSError, ValueError):
        return None


def uptime_text() -> str:
    with open("/proc/uptime") as f:
        seconds = int(float(f.read().split()[0]))
    days, rest = divmod(seconds, 86400)
    return f"{days}d{rest // 3600}h" if days else f"{rest // 3600}h"


def human_rate(bytes_per_sec: float) -> str:
    for unit in ("B", "K", "M", "G"):
        if bytes_per_sec < 1024:
            digits = 0 if unit == "B" else 1
            return f"{bytes_per_sec:.{digits}f}{unit}/s"
        bytes_per_sec /= 1024
    return f"{bytes_per_sec:.1f}T/s"


def handle(action: str) -> None:
    # 音量走 barify 而非直接 wpctl：一并弹 dunst 指示条并自动取消静音。
    commands = {
        "vol-down": [str(BARIFY_BIN), "v", "d"],
        "vol-up": [str(BARIFY_BIN), "v", "i"],
        "bri-down": [str(BRIGHTNESS_BIN), "down"],
        "bri-up": [str(BRIGHTNESS_BIN), "up"],
    }
    command = commands.get(action)
    if not command:
        return
    try:
        subprocess.run(
            command, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3
        )
    except (OSError, subprocess.SubprocessError):
        pass


def render() -> str:
    cpu, net, iface = sample_usage()
    mem = mem_percent()
    swap = swap_percent()
    temp = temp_c()
    vol = volume()
    bri = brightness()
    up = uptime_text()

    cells = [
        [
            f"{label('CPU')} {cpu:.0f}%",
            f"{label('RAM')} {mem:.0f}%",
            f"{label('TEMP')} {f'{temp}°C' if temp is not None else '--'}",
            f"{label('NET')} {human_rate(net) if iface else '--'}",
            f"{label('SWAP')} {f'{swap:.0f}%' if swap is not None else '--'}",
            f"{label('UP')} {up}",
        ],
        [
            button("−", "vol-down"),
            f"{label('VOL')} {vol or '--'}",
            button("+", "vol-up"),
            button("−", "bri-down"),
            f"{label('BRI')} {bri or '--'}",
            button("+", "bri-up"),
        ],
    ]

    lines = [
        "\0markup-rows\x1ftrue",
        "\0no-custom\x1ftrue",
        "\0keep-selection",
    ]
    lines += [cells[row][col] for col in range(COLS) for row in range(ROWS)]
    return "\n".join(lines) + "\n"


def emit() -> None:
    """rofi 以脚本模式调用时走这里：处理动作后输出新列表。"""
    action = os.environ.get("ROFI_INFO") or ""
    if action and os.environ.get("ROFI_RETV") == "1":
        handle(action)
    sys.stdout.write(render())


def launch() -> None:
    subprocess.run(
        [
            "rofi",
            "-show",
            "sysinfo",
            "-modi",
            f"sysinfo:{Path(__file__).resolve()}",
            "-theme",
            str(THEME),
            "-kb-cancel",
            "Escape",
        ],
        check=False,
    )


def main() -> None:
    # 被 rofi 调用时 ROFI_RETV 必定存在；否则是用户/ polybar 直接启动
    if "ROFI_RETV" in os.environ:
        emit()
    else:
        launch()


if __name__ == "__main__":
    main()
