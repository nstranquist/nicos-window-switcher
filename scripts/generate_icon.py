#!/usr/bin/env python3
"""Write a simple 1024 PNG and compile AppIcon.icns. No third-party deps."""

from __future__ import annotations

import struct
import subprocess
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Resources"
BUILD = ROOT / ".build" / "iconset"


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, size: int, rgb: tuple[int, int, int]) -> None:
    raw = b""
    r, g, b = rgb
    row = bytes([0]) + bytes([r, g, b]) * size
    raw = row * size
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    payload = b"\x89PNG\r\n\x1a\n"
    payload += png_chunk(b"IHDR", ihdr)
    payload += png_chunk(b"IDAT", zlib.compress(raw, 9))
    payload += png_chunk(b"IEND", b"")
    path.write_bytes(payload)


def main() -> None:
    RESOURCES.mkdir(parents=True, exist_ok=True)
    BUILD.mkdir(parents=True, exist_ok=True)
    src = BUILD / "icon-1024.png"
    write_png(src, 1024, (36, 99, 235))
    iconset = BUILD / "AppIcon.iconset"
    if iconset.exists():
        for child in iconset.iterdir():
            child.unlink()
    else:
        iconset.mkdir()
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    for px, name in sizes:
        dest = iconset / name
        subprocess.run(["sips", "-z", str(px), str(px), str(src), "--out", str(dest)], check=True, capture_output=True)
    icns = RESOURCES / "AppIcon.icns"
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(icns)], check=True)
    print(icns)


if __name__ == "__main__":
    main()
