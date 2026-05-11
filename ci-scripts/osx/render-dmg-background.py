#!/usr/bin/env python3
"""DMG window background: light/white canvas + curved arrow (no deps)."""
from __future__ import annotations

import math
import struct
import sys
import zlib


def _write_png(path: str, w: int, h: int, rows: list[bytearray]) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    comp = zlib.compress(raw, 9)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    out = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", comp) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: render-dmg-background.py OUT.png", file=sys.stderr)
        return 2
    out = sys.argv[1]
    w, h = 1200, 700
    rows = [bytearray(w * 4) for _ in range(h)]

    def bg_at(x: int, y: int) -> tuple[int, int, int]:
        t = x / max(1, w - 1)
        u = y / max(1, h - 1)
        # Soft white / cool grey (readable with dark icon labels)
        r = int(252 - 8 * t - 4 * u)
        g = int(252 - 6 * t - 6 * u)
        b = int(255 - 4 * t - 8 * u)
        return (max(245, r), max(245, g), min(255, b))

    for y in range(h):
        for x in range(w):
            r, g, b = bg_at(x, y)
            i = x * 4
            rows[y][i : i + 4] = bytes((r, g, b, 255))

    def blend(px: int, py: int, col: tuple[int, int, int, int]) -> None:
        if not (0 <= px < w and 0 <= py < h):
            return
        i = px * 4
        br, bgc, bb = rows[py][i], rows[py][i + 1], rows[py][i + 2]
        cr, cg, cb, a = col
        t = a / 255.0
        rows[py][i : i + 4] = bytes(
            (
                int(br * (1 - t) + cr * t),
                int(bgc * (1 - t) + cg * t),
                int(bb * (1 - t) + cb * t),
                255,
            )
        )

    def disk(cx: float, cy: float, rad: float, col: tuple[int, int, int, int]) -> None:
        r0 = int(rad) + 2
        x0 = max(0, int(cx - r0))
        x1 = min(w - 1, int(cx + r0))
        y0 = max(0, int(cy - r0))
        y1 = min(h - 1, int(cy + r0))
        rr = rad * rad
        for yy in range(y0, y1 + 1):
            for xx in range(x0, x1 + 1):
                if (xx - cx) ** 2 + (yy - cy) ** 2 <= rr:
                    blend(xx, yy, col)

    def tri(ax: float, ay: float, bx: float, by: float, cx: float, cy: float, col: tuple[int, int, int, int]) -> None:
        minx = max(0, int(min(ax, bx, cx) - 2))
        maxx = min(w - 1, int(max(ax, bx, cx) + 2))
        miny = max(0, int(min(ay, by, cy) - 2))
        maxy = min(h - 1, int(max(ay, by, cy) + 2))
        for yy in range(miny, maxy + 1):
            for xx in range(minx, maxx + 1):
                v0x, v0y = bx - ax, by - ay
                v1x, v1y = cx - ax, cy - ay
                v2x, v2y = xx - ax, yy - ay
                d00 = v0x * v0x + v0y * v0y
                d01 = v0x * v1x + v0y * v1y
                d11 = v1x * v1x + v1y * v1y
                d20 = v2x * v0x + v2y * v0y
                d21 = v2x * v1x + v2y * v1y
                denom = d00 * d11 - d01 * d01
                if abs(denom) < 1e-6:
                    continue
                v = (d11 * d20 - d01 * d21) / denom
                wgt = (d00 * d21 - d01 * d20) / denom
                u = 1.0 - v - wgt
                if v >= -1e-4 and wgt >= -1e-4 and u >= -1e-4:
                    blend(xx, yy, col)

    # Bezier from left to right (control pulls curve upward)
    x0, y0 = 220.0, 360.0
    x1, y1 = 520.0, 200.0
    x2, y2 = 980.0, 360.0
    n = 160
    shaft_col = (255, 165, 40, 240)
    edge_col = (200, 100, 15, 150)
    for i in range(n + 1):
        t = i / n
        bx = (1 - t) * (1 - t) * x0 + 2 * (1 - t) * t * x1 + t * t * x2
        by = (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * y1 + t * t * y2
        disk(bx, by, 26, edge_col)
    for i in range(n + 1):
        t = i / n
        bx = (1 - t) * (1 - t) * x0 + 2 * (1 - t) * t * x1 + t * t * x2
        by = (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * y1 + t * t * y2
        disk(bx, by, 20, shaft_col)

    # Arrow head at curve end (t=1): derivative B'(1) = 2*(P2 - P1)
    tang = math.atan2(2.0 * (y2 - y1), 2.0 * (x2 - x1))
    tipx = x2 + math.cos(tang) * 72
    tipy = y2 + math.sin(tang) * 72
    bx = x2 - math.cos(tang) * 28 + math.cos(tang + math.pi / 2) * 52
    by = y2 - math.sin(tang) * 28 + math.sin(tang + math.pi / 2) * 52
    cx = x2 - math.cos(tang) * 28 - math.cos(tang + math.pi / 2) * 52
    cy = y2 - math.sin(tang) * 28 - math.sin(tang + math.pi / 2) * 52
    tri(tipx, tipy, bx, by, cx, cy, (255, 140, 30, 250))

    # Subtle footer band
    for yy in range(520, 532):
        for xx in range(120, w - 120):
            blend(xx, yy, (220, 220, 230, 40))

    _write_png(out, w, h, rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
