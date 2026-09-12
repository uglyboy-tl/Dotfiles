#!/usr/bin/env python3
# img-preview - 在 fzf 预览窗格用 kitty 图形协议显示图片（Unicode 占位符）
#
# 用途: 由 selectors.sh 的 fzf 选择器调用；读 fzf 提供的
#       FZF_PREVIEW_COLUMNS / FZF_PREVIEW_LINES 决定显示尺寸。
# 用法: img-preview.py <图片路径>
# 依赖: python3；非 PNG 图片需要 ImageMagick（magick 或 convert）
#
# 逻辑源自 kittytgp <https://github.com/AnswerDotAI/kittytgp>，Apache-2.0，
# 见同目录 LICENSE.kittytgp。此处仅内联变音符表并裁剪 CLI。
import argparse
import base64
import math
import os
import secrets
import shutil
import struct
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO

try:
    import fcntl
    import termios
except ImportError:  # pragma: no cover
    fcntl = None
    termios = None

PLACEHOLDER = "\U0010EEEE"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
DEFAULT_CHUNK_SIZE = 4096


@dataclass(frozen=True)
class TerminalGeometry:
    cols: int
    rows: int
    cell_width_px: int
    cell_height_px: int


_DIACRITICS_HEX = """0305
030D
030E
0310
0312
033D
033E
033F
0346
034A
034B
034C
0350
0351
0352
0357
035B
0363
0364
0365
0366
0367
0368
0369
036A
036B
036C
036D
036E
036F
0483
0484
0485
0486
0487
0592
0593
0594
0595
0597
0598
0599
059C
059D
059E
059F
05A0
05A1
05A8
05A9
05AB
05AC
05AF
05C4
0610
0611
0612
0613
0614
0615
0616
0617
0657
0658
0659
065A
065B
065D
065E
06D6
06D7
06D8
06D9
06DA
06DB
06DC
06DF
06E0
06E1
06E2
06E4
06E7
06E8
06EB
06EC
0730
0732
0733
0735
0736
073A
073D
073F
0740
0741
0743
0745
0747
0749
074A
07EB
07EC
07ED
07EE
07EF
07F0
07F1
07F3
0816
0817
0818
0819
081B
081C
081D
081E
081F
0820
0821
0822
0823
0825
0826
0827
0829
082A
082B
082C
082D
0951
0953
0954
0F82
0F83
0F86
0F87
135D
135E
135F
17DD
193A
1A17
1A75
1A76
1A77
1A78
1A79
1A7A
1A7B
1A7C
1B6B
1B6D
1B6E
1B6F
1B70
1B71
1B72
1B73
1CD0
1CD1
1CD2
1CDA
1CDB
1CE0
1DC0
1DC1
1DC3
1DC4
1DC5
1DC6
1DC7
1DC8
1DC9
1DCB
1DCC
1DD1
1DD2
1DD3
1DD4
1DD5
1DD6
1DD7
1DD8
1DD9
1DDA
1DDB
1DDC
1DDD
1DDE
1DDF
1DE0
1DE1
1DE2
1DE3
1DE4
1DE5
1DE6
1DFE
20D0
20D1
20D4
20D5
20D6
20D7
20DB
20DC
20E1
20E7
20E9
20F0
2CEF
2CF0
2CF1
2DE0
2DE1
2DE2
2DE3
2DE4
2DE5
2DE6
2DE7
2DE8
2DE9
2DEA
2DEB
2DEC
2DED
2DEE
2DEF
2DF0
2DF1
2DF2
2DF3
2DF4
2DF5
2DF6
2DF7
2DF8
2DF9
2DFA
2DFB
2DFC
2DFD
2DFE
2DFF
A66F
A67C
A67D
A6F0
A6F1
A8E0
A8E1
A8E2
A8E3
A8E4
A8E5
A8E6
A8E7
A8E8
A8E9
A8EA
A8EB
A8EC
A8ED
A8EE
A8EF
A8F0
A8F1
AAB0
AAB2
AAB3
AAB7
AAB8
AABE
AABF
AAC1
FE20
FE21
FE22
FE23
FE24
FE25
FE26
10A0F
10A38
1D185
1D186
1D187
1D188
1D189
1D1AA
1D1AB
1D1AC
1D1AD
1D242
1D243
1D244"""


def _load_diacritics():
    out = tuple(chr(int(h, 16)) for h in _DIACRITICS_HEX.split())
    if not out:
        raise RuntimeError("no diacritics")
    return out


DIACRITICS = _load_diacritics()

def _parse_png_size(data: bytes) -> tuple[int, int]:
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("input is not a PNG file")
    if len(data) < 24:
        raise ValueError("PNG is too short")
    ihdr_len = struct.unpack(">I", data[8:12])[0]
    if ihdr_len != 13 or data[12:16] != b"IHDR":
        raise ValueError("PNG does not start with an IHDR chunk")
    width, height = struct.unpack(">II", data[16:24])
    if width <= 0 or height <= 0:
        raise ValueError("PNG has invalid dimensions")
    return width, height


def _read_png(path_or_bytes: str | os.PathLike[str] | bytes) -> tuple[bytes, int, int]:
    if isinstance(path_or_bytes, bytes):
        data = path_or_bytes
    else:
        data = Path(path_or_bytes).read_bytes()
    width, height = _parse_png_size(data)
    return data, width, height


def _ioctl_winsize(fileno: int) -> tuple[int, int, int, int] | None:
    if fcntl is None or termios is None:
        return None
    try:
        packed = fcntl.ioctl(fileno, termios.TIOCGWINSZ, struct.pack("HHHH", 0, 0, 0, 0))
        rows, cols, xpixel, ypixel = struct.unpack("HHHH", packed)
    except OSError:
        return None
    return rows, cols, xpixel, ypixel


def _tmux_cell_size() -> tuple[int, int] | None:
    if not os.environ.get("TMUX"):
        return None
    try:
        proc = subprocess.run(
            ["tmux", "display-message", "-p", "#{client_cell_width} #{client_cell_height}"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except Exception:
        return None
    parts = proc.stdout.strip().split()
    if len(parts) != 2:
        return None
    try:
        width, height = (int(parts[0]), int(parts[1]))
    except ValueError:
        return None
    if width <= 0 or height <= 0:
        return None
    return width, height


def _geometry_from_fileno(
    fileno: int,
    *,
    cell_width_px: int | None,
    cell_height_px: int | None,
) -> TerminalGeometry | None:
    winsize = _ioctl_winsize(fileno)
    if winsize is None:
        return None
    rows, cols, xpixel, ypixel = winsize
    if cols <= 0 or rows <= 0:
        return None
    if cell_width_px is not None and cell_height_px is not None:
        return TerminalGeometry(cols=cols, rows=rows, cell_width_px=cell_width_px, cell_height_px=cell_height_px)
    if xpixel > 0 and ypixel > 0:
        return TerminalGeometry(
            cols=cols,
            rows=rows,
            cell_width_px=max(1, xpixel // cols),
            cell_height_px=max(1, ypixel // rows),
        )
    tmux_cell = _tmux_cell_size()
    if tmux_cell is not None:
        return TerminalGeometry(cols=cols, rows=rows, cell_width_px=tmux_cell[0], cell_height_px=tmux_cell[1])
    return None


def get_terminal_geometry(
    fileno: int,
    *,
    cell_width_px: int | None = None,
    cell_height_px: int | None = None,
) -> TerminalGeometry:
    geom = _geometry_from_fileno(fileno, cell_width_px=cell_width_px, cell_height_px=cell_height_px)
    if geom is not None:
        return geom
    try:
        with open("/dev/tty", "rb", buffering=0) as tty:
            geom = _geometry_from_fileno(tty.fileno(), cell_width_px=cell_width_px, cell_height_px=cell_height_px)
    except OSError:
        geom = None
    if geom is not None:
        return geom
    size = shutil.get_terminal_size(fallback=(80, 24))
    if cell_width_px is not None and cell_height_px is not None:
        return TerminalGeometry(
            cols=size.columns,
            rows=size.lines,
            cell_width_px=cell_width_px,
            cell_height_px=cell_height_px,
        )
    raise RuntimeError("unable to determine terminal cell size; pass --cell-size, --cols, or --rows")


def _fit_cells(
    image_width_px: int,
    image_height_px: int,
    geometry: TerminalGeometry,
    *,
    cols: int | None,
    rows: int | None,
    newline: bool,
) -> tuple[int, int]:
    if cols is not None and cols <= 0:
        raise ValueError("cols must be positive")
    if rows is not None and rows <= 0:
        raise ValueError("rows must be positive")

    cw = geometry.cell_width_px
    ch = geometry.cell_height_px

    if cols is not None and rows is not None:
        return cols, rows
    if cols is not None:
        rows = math.ceil((image_height_px * cols * cw) / (image_width_px * ch))
        return max(1, cols), max(1, rows)
    if rows is not None:
        cols = math.ceil((image_width_px * rows * ch) / (image_height_px * cw))
        return max(1, cols), max(1, rows)

    avail_cols = max(1, geometry.cols)
    avail_rows = max(1, geometry.rows - (1 if newline else 0))
    scale = min(
        (avail_cols * cw) / image_width_px,
        (avail_rows * ch) / image_height_px,
        1.0,
    )
    width_px = max(1, math.ceil(image_width_px * scale))
    height_px = max(1, math.ceil(image_height_px * scale))
    return max(1, math.ceil(width_px / cw)), max(1, math.ceil(height_px / ch))


def _tmux_passthrough_enabled() -> bool | None:
    "Effective `allow-passthrough` for this pane (inherited options included), or None when tmux cannot be asked."
    try:
        out = subprocess.run(["tmux", "show-options", "-pAqv", "allow-passthrough"],
                             capture_output=True, text=True, timeout=1)
        return out.stdout.strip() in ("on", "all")
    except Exception:
        return None


_warned_passthrough = False


def _warn_passthrough_off() -> None:
    "Warn (once) when tmux would silently swallow the graphics transmit -- the classic invisible-images cause."
    global _warned_passthrough
    if _warned_passthrough or _tmux_passthrough_enabled() is not False: return
    _warned_passthrough = True
    print("kittytgp: tmux 'allow-passthrough' is off (the default since tmux 3.3a), so image data "
          "cannot reach your terminal and placeholders will show nothing.\nFix now:  tmux set -g allow-passthrough on\n"
          "Persist:  add 'set -g allow-passthrough on' to ~/.tmux.conf", file=sys.stderr)


def _resolve_passthrough(mode: str) -> str:
    if mode not in {"auto", "none", "tmux"}:
        raise ValueError("passthrough must be 'auto', 'none', or 'tmux'")
    if mode == "auto":
        mode = "tmux" if os.environ.get("TMUX") else "none"
    if mode == "tmux": _warn_passthrough_off()
    return mode


def _wrap_tmux_passthrough(seq: bytes) -> bytes:
    return b"\x1bPtmux;" + seq.replace(b"\x1b", b"\x1b\x1b") + b"\x1b\\"


def _graphics_apc(control: str, payload: bytes, *, passthrough: str) -> bytes:
    seq = b"\x1b_G" + control.encode("ascii") + b";" + payload + b"\x1b\\"
    return _wrap_tmux_passthrough(seq) if passthrough == "tmux" else seq


def _iter_transmit_chunks(
    png_data: bytes,
    *,
    cols: int,
    rows: int,
    image_id: int,
    chunk_size: int,
    passthrough: str,
) -> list[bytes]:
    encoded = base64.standard_b64encode(png_data)
    chunks = [encoded[i : i + chunk_size] for i in range(0, len(encoded), chunk_size)] or [b""]
    out: list[bytes] = []
    for i, chunk in enumerate(chunks):
        more = 1 if i < len(chunks) - 1 else 0
        meta = f"a=T,f=100,q=2,U=1,i={image_id},c={cols},r={rows}," if i == 0 else ""
        out.append(_graphics_apc(f"{meta}m={more}", chunk, passthrough=passthrough))
    return out


def _placeholder_grid(cols: int, rows: int, image_id: int) -> str:
    if rows > len(DIACRITICS):
        raise ValueError(f"too many rows for kitty Unicode placeholders: {rows} > {len(DIACRITICS)}")
    if cols <= 0 or rows <= 0:
        raise ValueError("cols and rows must be positive")
    r = (image_id >> 16) & 255
    g = (image_id >> 8) & 255
    b = image_id & 255
    prefix = f"\x1b[38;2;{r};{g};{b}m"
    line_fill = PLACEHOLDER * max(0, cols - 1)
    lines = [PLACEHOLDER + DIACRITICS[row] + line_fill for row in range(rows)]
    return prefix + "\n".join(lines) + "\x1b[39m"


def normalize_image_id(image_id: int | None) -> int:
    if image_id is None:
        return secrets.randbelow((1 << 24) - 1) + 1
    image_id &= 0xFFFFFFFF
    if image_id == 0:
        raise ValueError("image_id must be non-zero")
    if image_id >= (1 << 24):
        raise ValueError("image_id must fit in 24 bits for this minimal renderer")
    return image_id


def render_parts(
    png: str | os.PathLike[str] | bytes,
    *,
    cols: int | None = None,
    rows: int | None = None,
    image_id: int | None = None,
    passthrough: str = "auto",
    cell_width_px: int | None = None,
    cell_height_px: int | None = None,
    chunk_size: int = DEFAULT_CHUNK_SIZE,
    fileno: int | None = None,
) -> tuple[bytes, str]:
    """The kitty transmit bytes and the placeholder-grid text, separately.

    For apps that route control bytes and printable text differently (e.g. a
    compositor that writes the transmit raw but treats the placeholder grid as
    ordinary repaintable text). With explicit ``cols`` and ``rows`` no terminal
    is consulted, so this also works fully headless."""
    if chunk_size <= 0:
        raise ValueError("chunk_size must be positive")
    png_data, image_width_px, image_height_px = _read_png(png)
    image_id = normalize_image_id(image_id)
    passthrough = _resolve_passthrough(passthrough)
    if cols is None or rows is None:
        geometry = get_terminal_geometry(
            sys.stdout.buffer.fileno() if fileno is None else fileno,
            cell_width_px=cell_width_px,
            cell_height_px=cell_height_px,
        )
        cols, rows = _fit_cells(image_width_px, image_height_px, geometry, cols=cols, rows=rows, newline=False)
    pieces = _iter_transmit_chunks(
        png_data, cols=cols, rows=rows, image_id=image_id, chunk_size=chunk_size, passthrough=passthrough)
    return b"".join(pieces), _placeholder_grid(cols, rows, image_id)


KITTY_PROBE_ID = 4242


def kitty_probe(passthrough: str = "auto") -> bytes:
    """Bytes probing kitty-graphics support: a tiny ``a=q`` query (answered only by
    supporting terminals) followed by DA1 (answered by every terminal, fencing the
    probe: once the DA1 reply arrives, a silent query means no support)."""
    passthrough = _resolve_passthrough(passthrough)
    q = _graphics_apc(f"i={KITTY_PROBE_ID},s=1,v=1,a=q,t=d,f=24", b"AAAA", passthrough=passthrough)
    return q + b"\x1b[c"


def kitty_supported(response: bytes) -> bool:
    "True when `response` (bytes read after `kitty_probe` until the DA1 reply) contains the graphics reply."
    return f"\x1b_Gi={KITTY_PROBE_ID}".encode("ascii") in response


def _tmux_client_term(env) -> str:
    "The attached tmux client's terminal name (e.g. 'xterm-ghostty'), '' outside tmux or on any failure."
    if not env.get("TMUX"): return ""
    try:
        out = subprocess.run(["tmux", "display-message", "-p", "#{client_termname}"],
                             capture_output=True, text=True, timeout=1)
        return out.stdout.strip()
    except Exception:
        return ""


def kitty_env_hint(env=None) -> bool:
    """Environment evidence of kitty-graphics support, for where probe replies cannot
    arrive (tmux does not route terminal responses to panes). Checks terminal id vars
    (KITTY_WINDOW_ID, GHOSTTY_RESOURCES_DIR survive into tmux panes), TERM/TERM_PROGRAM
    (though tmux overwrites both), and finally asks tmux what its attached client is."""
    if env is None: env = os.environ
    term, prog = env.get("TERM", ""), env.get("TERM_PROGRAM", "").lower()
    if (env.get("KITTY_WINDOW_ID") or env.get("GHOSTTY_RESOURCES_DIR")
            or "kitty" in term or "ghostty" in term or prog in ("ghostty", "wezterm")): return True
    client = _tmux_client_term(env)
    return "kitty" in client or "ghostty" in client


def build_render_bytes(
    png: str | os.PathLike[str] | bytes,
    *,
    cols: int | None = None,
    rows: int | None = None,
    image_id: int | None = None,
    passthrough: str = "auto",
    cell_width_px: int | None = None,
    cell_height_px: int | None = None,
    chunk_size: int = DEFAULT_CHUNK_SIZE,
    newline: bool = True,
    out: BinaryIO | None = None,
) -> bytes:
    if chunk_size <= 0:
        raise ValueError("chunk_size must be positive")

    png_data, image_width_px, image_height_px = _read_png(png)
    image_id = normalize_image_id(image_id)
    passthrough = _resolve_passthrough(passthrough)

    if cols is None or rows is None:
        stream = out or sys.stdout.buffer
        geometry = get_terminal_geometry(
            stream.fileno(),
            cell_width_px=cell_width_px,
            cell_height_px=cell_height_px,
        )
        cols, rows = _fit_cells(
            image_width_px,
            image_height_px,
            geometry,
            cols=cols,
            rows=rows,
            newline=newline,
        )

    pieces = _iter_transmit_chunks(
        png_data,
        cols=cols,
        rows=rows,
        image_id=image_id,
        chunk_size=chunk_size,
        passthrough=passthrough,
    )
    pieces.append(_placeholder_grid(cols, rows, image_id).encode("utf-8"))
    if newline:
        pieces.append(b"\n")
    return b"".join(pieces)


DELETE_ALL = b"\x1b_Ga=d,d=A\x1b\\"


def _is_png_file(path):
    try:
        with open(path, "rb") as f:
            return f.read(8) == PNG_SIGNATURE
    except OSError:
        return False


def _prepare_png(path, max_w, max_h):
    """转成 PNG 并缩到不超过 max_w x max_h（能缩小不放大）。

    PNG 且尺寸在目标 2 倍以内时直接用原字节，跳过 ImageMagick 子进程——
    字体样张等缓存图因此可以秒出，避免 fzf 快速移动时预览被掐断。
    """
    if _is_png_file(path):
        with open(path, "rb") as f:
            data = f.read()
        try:
            w, h = _parse_png_size(data)
            if w <= max_w * 2 and h <= max_h * 2:
                return data
        except Exception:
            pass

    magick = shutil.which("magick") or shutil.which("convert")
    if magick:
        try:
            proc = subprocess.run(
                [magick, path, "-auto-orient", "-resize", f"{max_w}x{max_h}>", "png:-"],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                check=True,
            )
            if proc.stdout.startswith(PNG_SIGNATURE):
                return proc.stdout
        except Exception:
            pass
    if _is_png_file(path):
        with open(path, "rb") as f:
            return f.read()
    raise RuntimeError("cannot decode image")


def _fallback(path):
    try:
        proc = subprocess.run(["file", "--brief", "--dereference", "--mime", "--", path],
                              stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        text = proc.stdout.strip()
    except Exception:
        text = ""
    print(text or path)


def main(argv=None):
    parser = argparse.ArgumentParser(prog="img-preview.py", description="kitty image preview for fzf")
    parser.add_argument("image")
    args = parser.parse_args(argv)
    path = args.image

    if not path or not os.path.isfile(path):
        return 0
    if not kitty_env_hint():
        _fallback(path)
        return 0

    try:
        pcols = int(os.environ.get("FZF_PREVIEW_COLUMNS") or 0)
        prows = int(os.environ.get("FZF_PREVIEW_LINES") or 0)
    except ValueError:
        pcols = prows = 0

    try:
        geom = get_terminal_geometry(sys.stdout.buffer.fileno())
    except Exception:
        geom = TerminalGeometry(cols=80, rows=24, cell_width_px=10, cell_height_px=20)

    if pcols <= 0:
        pcols = geom.cols
    if prows <= 0:
        prows = max(1, geom.rows - 1)

    preview = TerminalGeometry(
        cols=pcols,
        rows=prows,
        cell_width_px=geom.cell_width_px,
        cell_height_px=geom.cell_height_px,
    )

    try:
        png = _prepare_png(path, pcols * geom.cell_width_px, prows * geom.cell_height_px)
        _data, img_w, img_h = _read_png(png)
        cols, rows = _fit_cells(img_w, img_h, preview, cols=None, rows=None, newline=True)
        payload = build_render_bytes(png, cols=cols, rows=rows, passthrough="none", newline=True)
        out = sys.stdout.buffer
        out.write(DELETE_ALL)
        out.write(payload)
        out.flush()
    except Exception:
        _fallback(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
