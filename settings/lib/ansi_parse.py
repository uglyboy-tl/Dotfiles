#!/usr/bin/env python3
"""ANSI 解析核心模块（共享）

解析 ANSI 转义序列（SGR 颜色 + 光标左右移动），输出 (char, fg_hex, bold) cells。
两个转换器（ansi-to-ansi / ansi-to-pango）共享此模块。

用法:
    from ansi_parse import load_palette, parse_ansi_stream
"""

import argparse
import os
import re
import sys
import unicodedata

DEFAULT_PALETTE = {
    0: "#313244", 1: "#f38ba8", 2: "#a6e3a1", 3: "#f9e2af",
    4: "#89b4fa", 5: "#cba6f7", 6: "#94e2d5", 7: "#cdd6f4",
    8: "#6c7086", 9: "#f38ba8", 10: "#a6e3a1", 11: "#f9e2af",
    12: "#89b4fa", 13: "#f5c2e7", 14: "#94e2d5", 15: "#f5e0dc",
}

# 匹配 CSI 序列：ESC [ 参数 终止字母
CSI_RE = re.compile(r"\x1b\[([0-9;]*)([A-Za-z])")

COLOR_KEYS = {
    "dark_background": 0, "red": 1, "green": 2, "yellow": 3,
    "blue": 4, "magenta": 5, "cyan": 6, "foreground": 7,
    "muted": 8, "bright_red": 9, "bright_green": 10, "bright_yellow": 11,
    "bright_blue": 12, "bright_magenta": 13, "bright_cyan": 14,
    "bright_foreground": 15,
}


def load_palette(path):
    """从 colors.toml 加载调色板（兼容 key = "#hex" 格式）"""
    palette = dict(DEFAULT_PALETTE)
    if not path or not os.path.isfile(path):
        return palette
    vals = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if "=" not in line or line.startswith("#") or line.startswith(";"):
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if v.startswith("#") and len(v) == 7:
                vals[k] = v
    for name, idx in COLOR_KEYS.items():
        if name in vals:
            palette[idx] = vals[name]
    return palette


def color_256(n):
    """256 色索引 → #hex（仅处理 cube + grayscale）"""
    if n < 16:
        return None
    if n < 232:
        n -= 16
        r, g, b = n // 36, (n // 6) % 6, n % 6
        def conv(x):
            return 0 if x == 0 else 55 + x * 40
        return f"#{conv(r):02x}{conv(g):02x}{conv(b):02x}"
    v = 8 + (n - 232) * 10
    return f"#{v:02x}{v:02x}{v:02x}"


def cell_width(c):
    """单字符在终端中的显示宽度（1 或 2）"""
    return 2 if unicodedata.east_asian_width(c) in ("W", "F") else 1


def _parse_sgr(params, palette, fg, bold):
    """解析 SGR 参数，返回 (fg_hex, bold)"""
    codes = [int(x) for x in params.split(";") if x != ""] or [0]
    k = 0
    while k < len(codes):
        cd = codes[k]
        if cd == 0:
            fg, bold = None, False
        elif cd == 1:
            bold = True
        elif cd == 22:
            bold = False
        elif cd == 39:
            fg = None
        elif 30 <= cd <= 37:
            idx = cd - 30
            fg = palette.get(idx + 8 if bold else idx)
        elif 90 <= cd <= 97:
            fg = palette.get(cd - 90 + 8)
        elif cd == 38 and k + 1 < len(codes) and codes[k + 1] == 5 and k + 2 < len(codes):
            n256 = codes[k + 2]
            fg = palette.get(n256) if n256 < 16 else color_256(n256)
            k += 2
        elif cd == 38 and k + 1 < len(codes) and codes[k + 1] == 2 and k + 4 < len(codes):
            fg = f"#{codes[k + 2]:02x}{codes[k + 3]:02x}{codes[k + 4]:02x}"
            k += 4
        k += 1
    return fg, bold


def parse_ansi_stream(data, palette):
    """解析 ANSI 流，返回每行的 cells 列表。

    每行是 [(char, fg_hex_or_None, bold_bool), ...]
    dcol 按终端显示列递增（CJK=2），CJK 只写1个 cell + "\x00" 占位。
    """
    output_lines = []
    for raw in data.split("\n"):
        cells = []
        dcol = 0
        fg = None
        bold = False
        i = 0
        n = len(raw)

        while i < n:
            c = raw[i]
            if c == "\x1b" and i + 1 < n and raw[i + 1] == "[":
                m = CSI_RE.match(raw, i)
                if m:
                    params, final = m.group(1), m.group(2)
                    i = m.end()
                    if final == "C":
                        dcol += int(params or "1")
                    elif final == "D":
                        dcol = max(0, dcol - int(params or "1"))
                    elif final == "m":
                        fg, bold = _parse_sgr(params, palette, fg, bold)
                    elif final == "K":
                        del cells[dcol:]
                    continue

            cw = cell_width(c)
            while len(cells) <= dcol + cw - 1:
                cells.append((" ", None, False))
            cells[dcol] = (c, fg, bold)
            if cw == 2:
                cells[dcol + 1] = ("\x00", fg, bold)
            dcol += cw
            i += 1

        output_lines.append(cells)
    return output_lines


def run_cli(render_line, description="ANSI 转换器"):
    """共享 CLI 驱动：解析 --colors、读 stdin，逐行调用 render_line 输出。"""
    ap = argparse.ArgumentParser(description=description)
    ap.add_argument("--colors", help="colors.toml 路径（主题调色板）")
    args = ap.parse_args()

    palette = load_palette(args.colors)
    data = sys.stdin.buffer.read().decode("utf-8", "replace")
    for cells in parse_ansi_stream(data, palette):
        sys.stdout.write(render_line(cells) + "\n")


def strip_trailing_blank(cells):
    """原地移除行尾的空白与 CJK 占位符"""
    while cells and cells[-1][0] in (" ", "\x00"):
        cells.pop()


def iter_runs(cells, by_width=False):
    """把 cells 合并为连续 run，按 (fg, bold) 分组。

    by_width=True 时同时按显示宽度拆分（CJK/半角不混在同一 run）。
    yield (text, fg, bold)，text 已剔除 "\x00" 占位符。
    """
    i, n = 0, len(cells)
    while i < n:
        ch, fg, bold = cells[i]
        if ch == "\x00":
            i += 1
            continue
        w = cell_width(ch) if by_width else None
        j = i + 1
        while j < n:
            cj, fj, bj = cells[j]
            if fj != fg or bj != bold or cj == "\x00":
                break
            if by_width and cell_width(cj) != w:
                break
            j += 1
        text = "".join(c[0] for c in cells[i:j] if c[0] != "\x00")
        yield text, fg, bold
        i = j
