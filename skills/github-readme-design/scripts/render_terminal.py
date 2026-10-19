#!/usr/bin/env python3
"""Render light and dark SVGs from a real successful command recording."""

import argparse
from html import escape
import json
import math
from pathlib import Path
import re
import sys
import unicodedata

from presentation import load_spec, plain, write_or_check


THEMES = {
    "light": dict(surface="#ffffff", bar="#eeeeee", border="#888888", prompt="#333333",
                  command="#111111", output="#333333", dim="#555555"),
    "dark": dict(surface="#111111", bar="#222222", border="#888888", prompt="#dddddd",
                 command="#ffffff", output="#dddddd", dim="#bbbbbb"),
}


def cells(value):
    return sum(0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in value)


def render(record, spec, theme):
    title = plain(record["title"])
    if not record["commands"]:
        raise ValueError("A terminal demo needs a recorded command")
    lines = []
    for item in record["commands"]:
        if item["exit_code"] != 0:
            raise ValueError("Record successful commands for this renderer")
        lines.append(("command", plain(item["command"])))
        lines.extend(("output", plain(line)) for line in item["stdout"].split("\n"))
        lines.append(("output", ""))
    lines.pop()
    font = float(spec.get("font_size", 14))
    line_height = float(spec.get("line_height", 21))
    padding = float(spec.get("padding", 20))
    radius = float(spec.get("radius", 10))
    bar = float(spec.get("title_height", 34))
    if font <= 0 or line_height < font or padding < 0 or radius < 0 or bar < font + 4:
        raise ValueError("Invalid terminal dimensions")
    color = dict(THEMES[theme], **spec.get(theme, {}))
    if any(not re.fullmatch(r"#[0-9a-fA-F]{6}", value) for value in color.values()):
        raise ValueError("Terminal colors must be six-digit hex colors")
    width = max(float(spec.get("min_width", 560)), cells(title) * font * .67 + 2 * padding,
                max(cells(value) + (2 if role == "command" else 0) for role, value in lines) * font * .67 + 2 * padding)
    width = math.ceil(width)
    height = math.ceil(bar + padding * 2 + len(lines) * line_height)
    family = escape(spec.get("font_family", "ui-monospace, monospace"), quote=True)
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title">',
           f'<title id="title">{escape(title)}</title>',
           f'<rect x="0.5" y="0.5" width="{width-1}" height="{height-1}" rx="{radius}" fill="{color["surface"]}" stroke="{color["border"]}"/>',
           f'<path d="M {radius} 0.5 H {width-radius} Q {width-.5} .5 {width-.5} {radius} V {bar} H .5 V {radius} Q .5 .5 {radius} .5 Z" fill="{color["bar"]}"/>',
           f'<path d="M 0 {bar} H {width}" stroke="{color["border"]}"/>',
           f'<g font-family="{family}" font-size="{font}" fill="{color["output"]}">',
           f'<text x="{width/2}" y="{(bar+font)/2-2}" text-anchor="middle" fill="{color["dim"]}">{escape(title)}</text>']
    for index, (role, value) in enumerate(lines):
        y = bar + padding + font + index * line_height
        if role == "command":
            content = f'<tspan fill="{color["prompt"]}">$ </tspan><tspan fill="{color["command"]}">{escape(value)}</tspan>'
        else:
            content = escape(value)
        svg.append(f'<text x="{padding}" y="{y}" xml:space="preserve">{content}</text>')
    return "\n".join(svg + ['</g>', '</svg>', ''])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record", required=True, type=Path)
    parser.add_argument("--spec", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec, _ = load_spec(args.spec)
    record = json.loads(args.record.read_text())
    values = {theme: render(record, spec, theme) for theme in THEMES}
    for theme, value in values.items():
        write_or_check(args.output_dir / f"Demo-{theme}.svg", value, args.check)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError) as error:
        sys.exit(str(error))
