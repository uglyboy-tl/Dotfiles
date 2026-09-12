#!/usr/bin/env python3
# image_cache - fzf 预览图缓存引擎
#
# 把缩放后的预览 PNG 缓存到 $XDG_CACHE_HOME/image-cache/，供 img-preview.py 复用。
# 缓存键 = sha1(源路径 + mtime + 大小 + 目标尺寸)，源变化自动失效，写入时清理过期条目。
#
# 说明：rofi 侧直接用原图路径、由 rofi 自行加载缓存，不走本模块。
#
# CLI:
#   image_cache.py --from-image SRC [--max-w W] [--max-h H]   源图 → 缓存 PNG 路径
#   image_cache.py --prune [--max-age-days N]                  清理过期缓存
import argparse
import hashlib
import os
import shutil
import struct
import subprocess
import sys
import time
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")) / "image-cache"
DEFAULT_MAX_AGE_DAYS = 14


def cache_path(src, max_w=None, max_h=None):
    try:
        st = os.stat(src)
        raw = f"{os.path.realpath(src)}|{st.st_mtime_ns}|{st.st_size}|{max_w}x{max_h}"
    except OSError:
        raw = f"{src}|{max_w}x{max_h}"
    return CACHE_DIR / (hashlib.sha1(raw.encode("utf-8")).hexdigest()[:16] + ".png")


def _is_png_file(path):
    try:
        with open(path, "rb") as f:
            return f.read(8) == PNG_SIGNATURE
    except OSError:
        return False


def _parse_png_size(data):
    if not data.startswith(PNG_SIGNATURE) or len(data) < 24 or data[12:16] != b"IHDR":
        raise ValueError("not a PNG with IHDR")
    return struct.unpack(">II", data[16:24])


def _read_cached(cache):
    try:
        data = Path(cache).read_bytes()
        if data.startswith(PNG_SIGNATURE):
            return data
    except OSError:
        pass
    return None


def _write_atomic(cache, data):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        tmp = f"{cache}.{os.getpid()}.tmp"
        with open(tmp, "wb") as f:
            f.write(data)
        os.replace(tmp, cache)
    except OSError:
        pass


def _to_png(src, max_w, max_h):
    """转成 PNG 并按目标尺寸缩小（能缩小不放大）。

    PNG 且尺寸在目标 2 倍以内时直接用原字节，跳过 ImageMagick。
    """
    if _is_png_file(src):
        data = Path(src).read_bytes()
        try:
            w, h = _parse_png_size(data)
            if (not max_w or w <= max_w * 2) and (not max_h or h <= max_h * 2):
                return data
        except Exception:
            pass

    magick = shutil.which("magick") or shutil.which("convert")
    if magick:
        args = [magick, src, "-auto-orient"]
        if max_w or max_h:
            args += ["-resize", f"{max_w or ''}x{max_h or ''}>"]
        args += ["png:-"]
        try:
            proc = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=True)
            if proc.stdout.startswith(PNG_SIGNATURE):
                return proc.stdout
        except Exception:
            pass
    if _is_png_file(src):
        return Path(src).read_bytes()
    raise RuntimeError("cannot decode image")


def get_png_bytes(src, max_w=None, max_h=None):
    """源图 → 缓存 PNG 字节。"""
    cache = cache_path(src, max_w, max_h)
    data = _read_cached(cache)
    if data is None:
        data = _to_png(src, max_w, max_h)
        _write_atomic(cache, data)
        prune()
    return data


def prune(max_age_days=DEFAULT_MAX_AGE_DAYS):
    """清理过期的预览缓存（best-effort）。"""
    try:
        cutoff = time.time() - max_age_days * 86400
        for name in os.listdir(CACHE_DIR):
            p = CACHE_DIR / name
            try:
                if os.stat(p).st_mtime < cutoff:
                    os.remove(p)
            except OSError:
                pass
    except OSError:
        pass


def get_image_path(src, max_w=None, max_h=None):
    """源图 → 缓存 PNG 路径（调试/CLI 用）。"""
    get_png_bytes(src, max_w, max_h)
    return str(cache_path(src, max_w, max_h))


def main(argv=None):
    ap = argparse.ArgumentParser(prog="image_cache.py", description="fzf 预览图缓存")
    ap.add_argument("--from-image", metavar="SRC")
    ap.add_argument("--max-w", type=int)
    ap.add_argument("--max-h", type=int)
    ap.add_argument("--prune", action="store_true")
    ap.add_argument("--max-age-days", type=int, default=DEFAULT_MAX_AGE_DAYS)
    args = ap.parse_args(argv)

    if args.prune:
        prune(args.max_age_days)
        return 0
    if args.from_image:
        print(get_image_path(args.from_image, args.max_w, args.max_h), end="")
        return 0
    ap.error("需要 --from-image 或 --prune")
    return 2


if __name__ == "__main__":
    sys.exit(main())
