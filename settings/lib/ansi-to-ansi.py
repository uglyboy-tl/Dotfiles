#!/usr/bin/env python3
"""ANSI → ANSI 转换器（fzf preview 用）

将含光标左右移动(ESC[nC/D)的终端输出转为纯 SGR 颜色输出。
光标移动被替换为精确的空格填充，使 fzf preview 能正确显示对齐布局。

用法:
  fastfetch --pipe false | ansi-to-ansi.py --colors colors.toml
"""

from ansi_parse import strip_trailing_blank, iter_runs, run_cli


def fg_to_ansi(hex_color):
    """#hex → SGR 38;2;r;g;b"""
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f"\033[38;2;{r};{g};{b}m"


def render_line_ansi(cells):
    """将 cells 渲染为带 ANSI 颜色的字符串"""
    if not cells:
        return ""

    strip_trailing_blank(cells)
    if not cells:
        return ""

    out = []
    prev = (None, False)
    for text, fg, bold in iter_runs(cells):
        if (fg, bold) != prev:
            out.append("\033[0m")
            if bold:
                out.append("\033[1m")
            if fg:
                out.append(fg_to_ansi(fg))
            prev = (fg, bold)
        out.append(text)
    out.append("\033[0m")
    return "".join(out)


if __name__ == "__main__":
    run_cli(render_line_ansi, "ANSI → ANSI 转换器")
