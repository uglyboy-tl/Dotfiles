#!/usr/bin/env python3
"""ANSI → Pango 转换器（rofi 用）

将含 ANSI 转义码（SGR 颜色 + 光标左右移动）的终端输出转为 rofi 的 Pango markup。
供 lib/show.sh 的 show_gui 在只读窗中展示带颜色的命令输出。

用法:
  fastfetch --pipe false | ansi-to-pango.py --colors colors.toml
"""

from ansi_parse import cell_width, strip_trailing_blank, iter_runs, run_cli

LETTER_SPACING = 900  # Pango 单位，1024=1pt


def xml_escape(t):
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def render_line_pango(cells, spacing=LETTER_SPACING):
    """将 cells 渲染为 Pango markup 行"""
    if not cells:
        return "\u00a0"

    strip_trailing_blank(cells)
    if not cells:
        return "\u00a0"

    out = []
    for text, fg, bold in iter_runs(cells, by_width=True):
        w = cell_width(text[0])
        attrs = [f'letter_spacing="{spacing * w}"']
        if fg:
            attrs.append(f'foreground="{fg}"')
        if bold:
            attrs.append('weight="bold"')
        body = xml_escape(text.replace(" ", "\u00a0"))
        out.append("<span " + " ".join(attrs) + ">" + body + "</span>")
    return "".join(out)


if __name__ == "__main__":
    run_cli(render_line_pango, "ANSI → Pango 转换器")
