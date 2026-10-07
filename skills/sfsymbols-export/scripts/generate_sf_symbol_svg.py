#!/usr/bin/env python3
"""Generate square SVG assets from the local SF Symbols fallback font."""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path


DEFAULT_FONT = Path(
    "/Applications/SF Symbols.app/Contents/Resources/Fonts/SFSymbolsFallback.otf"
)


def import_fonttools():
    try:
        from fontTools.pens.boundsPen import BoundsPen
        from fontTools.pens.svgPathPen import SVGPathPen
        from fontTools.ttLib import TTFont
    except ModuleNotFoundError as error:
        raise SystemExit(
            "fontTools is required. Install outside the repo, for example:\n"
            "  python3 -m pip install --target /tmp/codex-fonttools fonttools\n"
            "Then run with:\n"
            "  PYTHONPATH=/tmp/codex-fonttools python3 "
            "scripts/generate_sf_symbol_svg.py ..."
        ) from error
    return BoundsPen, SVGPathPen, TTFont


def clean_color(raw: str) -> str:
    value = raw.strip()
    if value.startswith("#"):
        value = value[1:]
    if not re.fullmatch(r"[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?", value):
        raise SystemExit(f"invalid hex color: {raw}")
    return f"#{value.upper()}"


def resolve_glyph_name(requested: str, glyph_names: set[str]) -> str:
    candidates = [
        requested,
        f"{requested}.tag.color",
        f"{requested}.color",
        f"{requested}.tag.fill.color",
        f"{requested}.fill.color",
        f"{requested}.crop.color",
        f"{requested}.badge.color",
    ]
    for candidate in candidates:
        if candidate in glyph_names:
            return candidate

    contains = sorted(name for name in glyph_names if requested in name)
    if len(contains) == 1:
        return contains[0]
    if contains:
        preview = "\n".join(f"  {name}" for name in contains[:40])
        more = "" if len(contains) <= 40 else f"\n  ... {len(contains) - 40} more"
        raise SystemExit(
            f"multiple glyphs match {requested!r}; pass one exact glyph name:\n"
            f"{preview}{more}"
        )
    raise SystemExit(f"no SF Symbols glyph found for {requested!r}")


def symbol_svg(
    glyph_set,
    glyph_name: str,
    pixel_size: int,
    color: str,
    margin: float,
    viewbox_size: float = 64.0,
) -> str:
    BoundsPen, SVGPathPen, _ = import_fonttools()
    glyph = glyph_set[glyph_name]

    bounds_pen = BoundsPen(glyph_set)
    glyph.draw(bounds_pen)
    if bounds_pen.bounds is None:
        raise SystemExit(f"glyph has no drawable bounds: {glyph_name}")
    x_min, y_min, x_max, y_max = bounds_pen.bounds

    path_pen = SVGPathPen(glyph_set)
    glyph.draw(path_pen)
    path = path_pen.getCommands()

    available = viewbox_size - margin * 2
    width = x_max - x_min
    height = y_max - y_min
    scale = available / max(width, height)
    tx = margin + (available - width * scale) / 2 - x_min * scale
    ty = margin + (available - height * scale) / 2 + y_max * scale

    label = html.escape(glyph_name, quote=True)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{pixel_size}" '
        f'height="{pixel_size}" viewBox="0 0 64 64" fill="none" '
        f'role="img" aria-label="{label}">\n'
        f'  <path d="{path}" fill="{color}" '
        f'transform="translate({tx:.4f} {ty:.4f}) '
        f'scale({scale:.6f} {-scale:.6f})"/>\n'
        f"</svg>\n"
    )


def list_matches(font_path: Path, query: str, limit: int) -> int:
    _, _, TTFont = import_fonttools()
    font = TTFont(str(font_path))
    matches = sorted(name for name in font.getGlyphOrder() if query in name)
    for name in matches[:limit]:
        print(name)
    if len(matches) > limit:
        print(f"... {len(matches) - limit} more", file=sys.stderr)
    return 0 if matches else 1


def generate(args: argparse.Namespace) -> int:
    _, _, TTFont = import_fonttools()
    font_path = Path(args.font).expanduser()
    if not font_path.exists():
        raise SystemExit(f"SF Symbols font not found: {font_path}")

    font = TTFont(str(font_path))
    glyph_names = set(font.getGlyphOrder())
    glyph_name = args.glyph_name or resolve_glyph_name(args.symbol, glyph_names)
    if glyph_name not in glyph_names:
        raise SystemExit(f"glyph not found: {glyph_name}")

    glyph_set = font.getGlyphSet(location={"wght": args.weight})
    out_dir = Path(args.out_dir).expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    color = clean_color(args.color)

    small = out_dir / f"{args.basename}-small.svg"
    large = out_dir / f"{args.basename}-large.svg"
    small.write_text(
        symbol_svg(glyph_set, glyph_name, args.small_size, color, args.margin),
        encoding="utf-8",
    )
    large.write_text(
        symbol_svg(glyph_set, glyph_name, args.large_size, color, args.margin),
        encoding="utf-8",
    )

    print(f"glyph: {glyph_name}")
    print(f"small: {small}")
    print(f"large: {large}")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a local SF Symbols glyph into square SVG assets."
    )
    parser.add_argument("symbol", nargs="?", help="SF Symbols glyph or query name")
    parser.add_argument("--list", metavar="QUERY", help="list matching glyph names")
    parser.add_argument("--limit", type=int, default=40, help="max --list results")
    parser.add_argument("--glyph-name", help="exact glyph name to export")
    parser.add_argument("--font", default=str(DEFAULT_FONT), help="SF Symbols font path")
    parser.add_argument("--out-dir", default="assets", help="output directory")
    parser.add_argument("--basename", default="icon", help="output file basename")
    parser.add_argument("--small-size", type=int, default=64, help="small SVG width")
    parser.add_argument("--large-size", type=int, default=512, help="large SVG width")
    parser.add_argument("--color", default="#111827", help="hex fill color")
    parser.add_argument("--margin", type=float, default=5.5, help="64-viewBox margin")
    parser.add_argument("--weight", type=float, default=400, help="SF symbol weight")
    args = parser.parse_args(argv)
    if args.list:
        return args
    if not args.symbol and not args.glyph_name:
        parser.error("provide a symbol, --glyph-name, or --list QUERY")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.list:
        return list_matches(Path(args.font).expanduser(), args.list, args.limit)
    return generate(args)


if __name__ == "__main__":
    raise SystemExit(main())
