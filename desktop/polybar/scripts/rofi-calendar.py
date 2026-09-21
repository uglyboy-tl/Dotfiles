#!/usr/bin/env python3
"""rofi 月历弹出。

点击 polybar 的 date 模块时调用；Esc 或点窗口外关闭。
顶部按钮：« 上一年，‹ 上一月，󰃭 今天，› 下一月，» 下一年（可点击）。
键盘：←/→ 翻月，[ / ] 翻年，Ctrl+t 回到今天，回车选中日期。
"""

import calendar
import datetime
import locale
import os
import subprocess

CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
THEME = os.path.join(CONFIG_HOME, "rofi", "calendar.rasi")

WEEKDAYS = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
OUT_MARK = "·"
BLANK = " "

PREV_YEAR, PREV_MONTH, TODAY, NEXT_MONTH, NEXT_YEAR = "«", "‹", "󰃭", "›", "»"
# 与 7 个星期列对齐的顶部按钮行
TOOLBAR = [PREV_YEAR, PREV_MONTH, BLANK, TODAY, BLANK, NEXT_MONTH, NEXT_YEAR]

BUTTONS = {PREV_YEAR, PREV_MONTH, NEXT_MONTH, NEXT_YEAR, TODAY}


def month_grid(year, month):
    """构造月历网格。

    rofi 的 listview 按“列优先”填充，所以这里按列生成：
    每列依次是 按钮行、星期名、该列各周的日号（非本月为占位符）。
    返回 (entries, rows, today_index)。
    """
    weeks = calendar.Calendar(firstweekday=0).monthdatescalendar(year, month)
    rows = len(weeks) + 2

    entries = []
    for col in range(7):
        entries.append(TOOLBAR[col])
        entries.append(WEEKDAYS[col])
        for week in weeks:
            d = week[col]
            entries.append(str(d.day) if d.month == month else OUT_MARK)

    # 选中停留在“今天那个日号”（其它月份若没有该日号，则取当月最后一天）
    today = datetime.date.today()
    target = min(today.day, calendar.monthrange(year, month)[1])
    selected_index = None
    for w, week in enumerate(weeks):
        for col, d in enumerate(week):
            if d.month == month and d.day == target:
                selected_index = col * rows + 2 + w
    return entries, rows, selected_index


def run_rofi(prompt, entries, rows, selected_row):
    cmd = [
        "rofi", "-dmenu", "-no-custom",
        "-theme", THEME,
        "-theme-str", f"listview {{ lines: {rows}; }}",
        "-p", prompt,
        "-selected-row", str(selected_row or 0),
        # 按钮行中的按钮格（排除空白）标记为 active，主题里单独上色
        "-a", ",".join(str(c * rows) for c in range(7) if TOOLBAR[c] != BLANK),
        # 屏蔽默认键位，只保留下面 5 个自定义键 + Esc，避免误触
        "-kb-cancel", "Escape",
        "-kb-primary-paste", "",
        "-kb-secondary-paste", "",
        "-kb-clear-line", "",
        "-kb-move-front", "",
        "-kb-move-end", "",
        "-kb-move-char-back", "Control+b",
        "-kb-move-char-forward", "Control+f",
        "-kb-remove-word-back", "",
        "-kb-remove-word-forward", "",
        "-kb-remove-char-back", "",
        "-kb-remove-char-forward", "",
        "-kb-remove-to-eol", "",
        "-kb-remove-to-sol", "",
        "-kb-accept-entry", "",
        "-kb-accept-custom", "",
        "-kb-accept-alt", "",
        "-kb-delete-entry", "",
        "-kb-row-up", "",
        "-kb-row-down", "",
        "-kb-row-tab", "",
        "-kb-row-first", "",
        "-kb-row-last", "",
        "-kb-row-select", "",
        "-kb-page-prev", "",
        "-kb-page-next", "",
        "-kb-mode-next", "",
        "-kb-mode-previous", "",
        "-kb-mode-complete", "",
        "-kb-custom-1", "Left",
        "-kb-custom-2", "Right",
        "-kb-custom-3", "bracketleft",
        "-kb-custom-4", "bracketright",
        "-kb-custom-5", "Control+t",
    ]
    proc = subprocess.run(
        cmd, input="\n".join(entries), text=True, capture_output=True
    )
    return proc.returncode, proc.stdout.strip()


def prev_month(view):
    return (view - datetime.timedelta(days=1)).replace(day=1)


def next_month(view):
    return (view + datetime.timedelta(days=32)).replace(day=1)


def main():
    try:
        locale.setlocale(locale.LC_TIME, "")
    except locale.Error:
        pass

    today = datetime.date.today()
    view = today.replace(day=1)

    while True:
        entries, rows, selected_row = month_grid(view.year, view.month)
        code, chosen = run_rofi(
            view.strftime("%Y 年 %m 月"), entries, rows, selected_row
        )

        if code == 1:  # Esc
            return
        if code == 10 or chosen == PREV_MONTH:  # ← / ‹
            view = prev_month(view)
        elif code == 11 or chosen == NEXT_MONTH:  # → / ›
            view = next_month(view)
        elif code == 12 or chosen == PREV_YEAR:  # [ / «
            view = view.replace(year=view.year - 1)
        elif code == 13 or chosen == NEXT_YEAR:  # ] / »
            view = view.replace(year=view.year + 1)
        elif code == 14 or chosen == TODAY:  # Ctrl+t / 󰃭
            view = today.replace(day=1)
        elif code == 0 and chosen.isdigit():
            print(view.replace(day=int(chosen)).isoformat())
            return
        elif code == 0:
            return  # 点到空白/星期名，忽略并关闭
        else:
            return  # 未知返回码，避免死循环


if __name__ == "__main__":
    main()
