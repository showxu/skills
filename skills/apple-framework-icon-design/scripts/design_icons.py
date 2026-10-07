#!/usr/bin/env python3
"""Render framework-style icons from the Iconography section of a DESIGN.md.

Usage:
  design_icons.py DESIGN.md --list
  design_icons.py DESIGN.md --out DIR [--name NAME ...] [--size 1024] [--png]
  design_icons.py DESIGN.md --check NAME=FILE [NAME=FILE ...]
  design_icons.py DESIGN.md --tints
  design_icons.py DESIGN.md --sheet sheet.svg [--name NAME ...]
  design_icons.py --fidelity REFDIR

The Iconography section holds one fenced ```json block:
  {"icons": {"<name>": {<stack_logo Spec fields>}, ...}}
Colors may be written as "oklch(L C h)", hex strings, or [L, C, h] lists.

--check regenerates each icon and compares it byte for byte with FILE;
exit 1 on any difference. --tints prints each icon's hue and a light glow
color for social cards. --fidelity compares each style's silhouette and
lightness ramp with reference PNGs named icon-<name>.png in REFDIR.
"""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from stack_logo import DEPTH, Spec, icon_group, icon_svg, oklch  # noqa: E402

SHEET_BACKGROUNDS = ("#ffffff", "#0d1117")
SHEET_LARGE, SHEET_SMALL, SHEET_CELL = 160, 40, 190

OKLCH = re.compile(r"^\s*oklch\(\s*([\d.]+)%?\s+([\d.]+)\s+(-?[\d.]+)(?:deg)?\s*\)\s*$")


def iconography(text: str) -> dict:
    lines = text.splitlines()
    start = next((i for i, line in enumerate(lines) if re.match(r"^##\s+Iconography\s*$", line)), None)
    if start is None:
        raise SystemExit("error: DESIGN.md has no '## Iconography' section")
    block, inside = [], False
    for line in lines[start + 1:]:
        if not inside and re.match(r"^##\s", line):
            break
        if not inside and re.match(r"^\s*```json\s*$", line):
            inside = True
            continue
        if inside and re.match(r"^\s*```\s*$", line):
            return json.loads("\n".join(block))
        if inside:
            block.append(line)
    raise SystemExit("error: the Iconography section has no ```json block")


def convert(value):
    if isinstance(value, str):
        match = OKLCH.match(value)
        if match:
            lightness = float(match.group(1))
            if "%" in value.split()[0]:
                lightness /= 100
            return [lightness, float(match.group(2)), float(match.group(3))]
        return value
    if isinstance(value, list):
        return [convert(v) for v in value]
    if isinstance(value, dict):
        return {k: convert(v) for k, v in value.items()}
    return value


def specs(design: pathlib.Path) -> dict[str, Spec]:
    data = iconography(design.read_text())
    icons = data.get("icons") or {}
    if not icons:
        raise SystemExit("error: the Iconography block has no icons")
    known = set(Spec.__dataclass_fields__)
    result = {}
    for name, fields in icons.items():
        unknown = set(fields) - known
        if unknown:
            raise SystemExit(f"error: {name}: unknown fields {sorted(unknown)}")
        result[name] = Spec(**convert(fields))
    return result


def sheet(table: dict[str, Spec], names: list[str]) -> str:
    """Light and dark rows; each icon at header size with its table size below."""
    row = SHEET_LARGE + SHEET_SMALL + 60
    width = len(names) * SHEET_CELL + 20
    defs, body = [], []
    for r, background in enumerate(SHEET_BACKGROUNDS):
        top = r * row
        body.append(f'<rect y="{top}" width="{width}" height="{row}" fill="{background}"/>')
        for i, name in enumerate(names):
            cx = 10 + i * SHEET_CELL + SHEET_CELL / 2
            for size, cy, tag in ((SHEET_LARGE, top + 15 + SHEET_LARGE / 2, "l"),
                                  (SHEET_SMALL, top + 40 + SHEET_LARGE + SHEET_SMALL / 2, "s")):
                d, b = icon_group(table[name], cx, cy, size, f"{tag}{r}x{i}")
                defs.append(d)
                body.append(b)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {2 * row}" width="{width}" '
            f'height="{2 * row}"><defs>{"".join(defs)}</defs>{"".join(body)}</svg>\n')


# Reference icons per style, by file stem in the reference directory. They
# are compared as images only; nothing is traced from them.
STYLE_REFERENCES = {
    "stacked": ("cloudkit", "core-ml", "arkit", "realitykit", "scenekit", "widgetkit"),
    "volumetric": ("create-ml", "metal", "testflight", "xcode-cloud", "reality-composer-pro",
                   "app-intents", "swift-charts"),
    "flat": ("swiftui", "shareplay", "focus"),
}
FIDELITY_SIZE = 256
RAMP_SAMPLES = 12


def read_png(path: pathlib.Path) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    """Decode a non-interlaced 8- or 16-bit RGB or RGBA PNG into 8-bit RGBA pixels."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"error: {path}: not a PNG")
    pos, idat, header = 8, b"", None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"IDAT":
            idat += chunk
        pos += 12 + length
    width, height, depth, color, _, _, interlace = header
    if depth not in (8, 16) or color not in (2, 6) or interlace:
        raise SystemExit(f"error: {path}: only non-interlaced 8- or 16-bit RGB or RGBA PNGs are supported")
    channels, octets = (4 if color == 6 else 3), depth // 8
    bpp = channels * octets
    raw, stride = zlib.decompress(idat), width * bpp
    rows, prev = [], bytearray(stride)
    for y in range(height):
        kind, line = raw[y * (stride + 1)], bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b, c = prev[i], prev[i - bpp] if i >= bpp else 0
            if kind == 1:
                line[i] = (line[i] + a) & 255
            elif kind == 2:
                line[i] = (line[i] + b) & 255
            elif kind == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif kind == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        prev = line
    pixels = []
    for line in rows:
        for x in range(width):
            px = line[x * bpp:(x + 1) * bpp:octets]  # high byte of each sample
            pixels.append(tuple(px) if channels == 4 else (*px, 255))
    return width, height, pixels


def oklab(r: int, g: int, b: int) -> tuple[float, float, float]:
    def linear(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = linear(r), linear(g), linear(b)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def ramp(style: str, size: int, pixels) -> list[tuple[float, float, float]]:
    """OKLab samples down the sides of a slab, or down a tile's left margin."""
    opaque = [i for i, p in enumerate(pixels) if p[3] > 0]
    if not opaque:
        raise SystemExit("error: cannot measure a fully transparent reference")
    xs, ys = [i % size for i in opaque], [i // size for i in opaque]
    left, right, top, bottom = min(xs), max(xs), min(ys), max(ys)
    if style == "stacked":
        x, y0, y1 = (left + right) // 2, bottom - DEPTH * (right - left), bottom - 2
    else:
        side = right - left
        x, y0, y1 = left + round(0.05 * side), top + 0.15 * side, bottom - 0.15 * side
    out = []
    for k in range(RAMP_SAMPLES):
        r, g, b, _ = pixels[round(y0 + (y1 - y0) * k / (RAMP_SAMPLES - 1)) * size + x]
        out.append(oklab(r, g, b))
    return out


def render(spec: Spec, size: int, work: pathlib.Path) -> list:
    svg, png = work / "icon.svg", work / "icon.png"
    svg.write_text(icon_svg(spec, size))
    subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), str(svg), "-o", str(png)], check=True)
    return read_png(png)[2]


def fidelity(refdir: pathlib.Path) -> None:
    if not refdir.is_dir():
        raise SystemExit(f"error: reference directory does not exist: {refdir}")
    if not shutil.which("rsvg-convert"):
        raise SystemExit("error: rsvg-convert not found")
    candidates = {"stacked": ({"mode": "deepen"}, {"mode": "glow"}),
                  "tile": ({"mode": "deepen"}, {"mode": "glow"}, {"face": "light"}, {"face": "graphite"})}
    print("style\treference\tsilhouette_iou\tramp_dL\tramp_match")
    incomplete = []
    with tempfile.TemporaryDirectory() as tmp:
        work = pathlib.Path(tmp)
        for style, names in STYLE_REFERENCES.items():
            found = [n for n in names if (refdir / f"icon-{n}.png").is_file()]
            if not found:
                print(f"{style}\t-\tno references in {refdir}")
                incomplete.append(style)
                continue
            ours = render(Spec(style=style), FIDELITY_SIZE, work)
            ious = []
            for name in found:
                width, height, ref = read_png(refdir / f"icon-{name}.png")
                if (width, height) != (FIDELITY_SIZE, FIDELITY_SIZE):
                    print(f"{style}\t{name}\tskipped: not {FIDELITY_SIZE}x{FIDELITY_SIZE}")
                    continue
                inter = sum(min(a[3], b[3]) for a, b in zip(ref, ours))
                union = sum(max(a[3], b[3]) for a, b in zip(ref, ours))
                ious.append(inter / union)
                target = ramp(style, FIDELITY_SIZE, ref)
                hue = math.degrees(math.atan2(sum(s[2] for s in target), sum(s[1] for s in target))) % 360
                best = None
                for extra in candidates["stacked" if style == "stacked" else "tile"]:
                    mine = ramp(style, FIDELITY_SIZE, render(Spec(style=style, hue=hue, **extra), FIDELITY_SIZE, work))
                    dl = sum(abs(a[0] - b[0]) for a, b in zip(target, mine)) / RAMP_SAMPLES
                    if best is None or dl < best[0]:
                        best = (dl, next(iter(extra.values())))
                print(f"{style}\t{name}\t{ious[-1]:.4f}\t{best[0]:.3f}\t{best[1]}")
            if ious:
                print(f"{style}\tmean\t{sum(ious) / len(ious):.4f}")
            else:
                incomplete.append(style)
    if incomplete:
        raise SystemExit(f"error: no measurable references for: {', '.join(incomplete)}")


def main(argv):
    parser = argparse.ArgumentParser(description="Render framework-style icons from a DESIGN.md.")
    parser.add_argument("design", type=pathlib.Path, nargs="?")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true", help="list icon names")
    mode.add_argument("--out", type=pathlib.Path, help="write NAME.svg files to this directory")
    mode.add_argument("--check", nargs="+", metavar="NAME=FILE", help="compare regenerated icons with files")
    mode.add_argument("--tints", action="store_true", help="print hue and glow color per icon")
    mode.add_argument("--sheet", type=pathlib.Path, help="write a light and dark contact sheet SVG")
    mode.add_argument("--fidelity", type=pathlib.Path, metavar="REFDIR",
                      help="compare each style with reference PNGs in REFDIR")
    parser.add_argument("--name", action="append", default=[], help="only these icons (with --out or --sheet)")
    parser.add_argument("--size", type=int, default=1024)
    parser.add_argument("--png", action="store_true", help="also write NAME.png with rsvg-convert")
    args = parser.parse_args(argv)

    if args.fidelity:
        fidelity(args.fidelity)
        return
    if args.design is None:
        parser.error("DESIGN.md is required")
    table = specs(args.design)
    if args.list:
        print("\n".join(table))
        return
    if args.tints:
        print(json.dumps({n: {"hue": s.hue, "glow": oklch(0.93, 0.03, s.hue)} for n, s in table.items()}, indent=2))
        return
    if args.check:
        drift = 0
        for item in args.check:
            name, _, file = item.partition("=")
            if name not in table:
                print(f"missing\t{name}\tnot in DESIGN.md")
                drift += 1
                continue
            if not file or not pathlib.Path(file).is_file():
                print(f"missing\t{name}\t{file or 'no file specified'}")
                drift += 1
                continue
            same = pathlib.Path(file).read_text() == icon_svg(table[name], args.size)
            print(f"{'same' if same else 'drift'}\t{name}\t{file}")
            drift += not same
        sys.exit(1 if drift else 0)

    names = args.name or list(table)
    missing = [n for n in names if n not in table]
    if missing:
        raise SystemExit(f"error: not in DESIGN.md: {', '.join(missing)}")
    if args.sheet:
        args.sheet.write_text(sheet(table, names))
        print(args.sheet)
        return
    if args.png and not shutil.which("rsvg-convert"):
        raise SystemExit("error: rsvg-convert not found")
    args.out.mkdir(parents=True, exist_ok=True)
    for name in names:
        svg_path = args.out / f"{name}.svg"
        svg_path.write_text(icon_svg(table[name], args.size))
        if args.png:
            subprocess.run(["rsvg-convert", "-w", str(args.size), "-h", str(args.size), str(svg_path),
                            "-o", str(args.out / f"{name}.png")], check=True)
        print(svg_path)


if __name__ == "__main__":
    main(sys.argv[1:])
