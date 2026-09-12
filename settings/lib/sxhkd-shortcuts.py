#!/usr/bin/env python3
# 解析 sxhkdrc，输出花括号展开后的 "键位<TAB>命令"
# 键位与命令的花括号按组对齐（命令多出的组复用最后一个键位组索引）
# 用法: sxhkd-shortcuts.py [sxhkdrc路径]
import itertools
import re
import sys


def split_top_commas(s):
    parts, depth, cur = [], 0, []
    for ch in s:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    parts.append("".join(cur))
    return parts


def expand_alt(part):
    if part == "_":  # sxhkd 中 _ 表示空
        return [""]
    m = re.fullmatch(r"(\d+)-(\d+)", part)
    if m:
        return [str(x) for x in range(int(m.group(1)), int(m.group(2)) + 1)]
    m = re.fullmatch(r"(.)-(.)", part)
    if m:
        return [chr(x) for x in range(ord(m.group(1)), ord(m.group(2)) + 1)]
    return [part]


def parse(s):
    """返回 (segments, groups)。segments 元素为 ('lit', 文本) 或 ('grp', 组号)。"""
    segs, groups = [], []
    i, lit = 0, []
    while i < len(s):
        if s[i] == "{":
            if lit:
                segs.append(("lit", "".join(lit)))
                lit = []
            depth, j = 1, i + 1
            while j < len(s) and depth:
                if s[j] == "{":
                    depth += 1
                elif s[j] == "}":
                    depth -= 1
                j += 1
            alts = []
            for p in split_top_commas(s[i + 1 : j - 1]):
                alts.extend(expand_alt(p))
            groups.append(alts)
            segs.append(("grp", len(groups) - 1))
            i = j
        else:
            lit.append(s[i])
            i += 1
    if lit:
        segs.append(("lit", "".join(lit)))
    return segs, groups


def render(segs, groups, pick):
    out = []
    for kind, val in segs:
        out.append(val if kind == "lit" else groups[val][pick(val)])
    return "".join(out)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "sxhkdrc"
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError as e:
        sys.exit(f"sxhkd-shortcuts: {e}")

    entries = []  # (key, [command lines])
    key, cmds = None, []
    for line in lines:
        stripped = line.strip()
        if line[:1] in ("\t", " ") and stripped:
            if key is not None:
                cmds.append(stripped)
        elif stripped and not stripped.startswith("#"):
            if key is not None:
                entries.append((key, cmds))
            key, cmds = stripped, []
        elif not stripped and key is not None:
            entries.append((key, cmds))
            key, cmds = None, []
    if key is not None:
        entries.append((key, cmds))

    for key, cmds in entries:
        command = " ".join(cmds)
        ksegs, kgroups = parse(key)
        csegs, cgroups = parse(command)
        n = len(kgroups)
        for combo in itertools.product(*[range(len(g)) for g in kgroups]):
            def pick(j, _combo=combo, _n=n):
                return _combo[min(j, _n - 1)] if _n else 0
            k = render(ksegs, kgroups, lambda idx, _c=combo: _c[idx])
            c = render(csegs, cgroups, pick)
            print(f"{k}\t{c}")


if __name__ == "__main__":
    main()
