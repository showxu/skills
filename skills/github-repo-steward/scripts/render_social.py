#!/usr/bin/env python3
"""Render a 1280x640 outlined social card from a project-owned JSON recipe."""

import argparse
from html import escape
import json
from pathlib import Path
import re
import sys
from xml.etree import ElementTree as ET

from presentation import load_spec, plain, sha256, write_or_check


class Face:
    def __init__(self, path):
        from fontTools.ttLib import TTFont
        self.font = TTFont(path)
        self.glyphs = self.font.getGlyphSet()
        self.cmap = self.font.getBestCmap()
        self.units = self.font["head"].unitsPerEm

    def glyph_names(self, text):
        for char in text:
            if ord(char) not in self.cmap:
                raise ValueError(f"Font does not cover U+{ord(char):04X}")
            yield self.cmap[ord(char)]

    def width(self, text, size):
        return sum(self.glyphs[name].width for name in self.glyph_names(text)) * size / self.units

    def outline(self, text, size, x, y, color):
        from fontTools.pens.svgPathPen import SVGPathPen
        paths = []
        scale = size / self.units
        for name in self.glyph_names(text):
            pen = SVGPathPen(self.glyphs)
            self.glyphs[name].draw(pen)
            if commands := pen.getCommands():
                paths.append(f'<path d="{commands}" transform="translate({x:.3f} {y:.3f}) scale({scale:.7f} {-scale:.7f})"/>')
            x += self.glyphs[name].width * scale
        return f'<g fill="{escape(color, quote=True)}">' + "".join(paths) + '</g>'


def fit_title(title, measure, width, maximum=72, minimum=40):
    if not title or minimum <= 0 or maximum < minimum or width <= 0:
        raise ValueError("Invalid title or title fitting bounds")
    for size in range(maximum, minimum - 1, -1):
        if measure(title, size) <= width:
            return [title], size
    # A line break replaces a whole separator run, never leaves a dangling hyphen.
    candidates = [(title[:m.start()], title[m.end():]) for m in re.finditer(r"[-/]+", title)
                  if m.start() and m.end() < len(title)]
    for size in range(maximum, minimum - 1, -1):
        fits = [(abs(measure(a, size) - measure(b, size)), a, b) for a, b in candidates
                if max(measure(a, size), measure(b, size)) <= width]
        if fits:
            _, first, second = min(fits)
            return [first, second], size
    raise ValueError("Title cannot fit at its stated minimum; revise the composition")


def wrap_about(value, measure, width):
    lines = []
    line = ""
    for word in value.split():
        if measure(word, 32) > width:
            raise ValueError("About contains an unbreakable word wider than the text area")
        candidate = (line + " " + word).strip()
        if line and measure(candidate, 32) > width:
            lines.append(line)
            line = word
        else:
            line = candidate
    if line:
        lines.append(line)
    if not lines or len(lines) > 3:
        raise ValueError("Complete About must fit at 32 px in at most three lines")
    return lines


def icon_svg(path, x, y, size):
    root = ET.fromstring(path.read_text())
    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise ValueError("Icon must be SVG")
    for node in root.iter():
        if node.tag.rsplit("}", 1)[-1] in {"script", "foreignObject"}:
            raise ValueError("Icon must be static SVG")
        for key, value in node.attrib.items():
            if key.lower().startswith("on") or (key.rsplit("}", 1)[-1] == "href" and not value.startswith("#")):
                raise ValueError("Icon must be self-contained SVG")
    if "viewBox" not in root.attrib:
        raise ValueError("Icon needs a viewBox")
    root.attrib.update(x=str(x), y=str(y), width=str(size), height=str(size))
    return ET.tostring(root, encoding="unicode")


def render(spec, base):
    for key in ("owner", "title", "about"):
        plain(spec[key])
    for key in ("background", "ink", "muted"):
        if key in spec and not re.fullmatch(r"#[0-9a-fA-F]{6}", spec[key]):
            raise ValueError(f"{key} must be a six-digit hex color")
    title_font = Face(base / spec["font_title"])
    body_font = Face(base / spec["font_body"])
    # This required receipt is not a determination of redistribution permission.
    license_path = base / spec["font_license"]
    if not license_path.is_file():
        raise ValueError("Provide the selected fonts' license receipt")
    x, width = float(spec.get("text_x", 512)), float(spec.get("text_width", 704))
    padding, icon_size = float(spec.get("padding", 64)), float(spec.get("icon_size", 384))
    if min(x, width, padding, icon_size) < 0 or x + width > 1280 - padding or padding + icon_size > x or icon_size > 640 - 2 * padding:
        raise ValueError("Card composition exceeds the canvas or overlaps its icon")
    titles, size = fit_title(spec["title"], title_font.width, width,
                             int(spec.get("title_max", 72)), int(spec.get("title_min", 40)))
    about = wrap_about(spec["about"], body_font.width, width)
    if body_font.width(spec["owner"], 28) > width:
        raise ValueError("Owner label exceeds the text area")
    block_height = 28 + 24 + len(titles) * size * 1.15 + 24 + len(about) * 44
    if block_height > 640 - 2 * padding:
        raise ValueError("Text block exceeds the card height")
    y = (640 - block_height) / 2 + 28
    ink, muted = spec.get("ink", "#000000"), spec.get("muted", "#444444")
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="640" viewBox="0 0 1280 640" role="img" aria-labelledby="title desc">',
           '<title id="title">' + escape(spec["title"]) + '</title>',
           '<desc id="desc">' + escape(spec["about"]) + '</desc>',
           '<rect width="1280" height="640" fill="' + spec.get("background", "#ffffff") + '"/>',
           icon_svg(base / spec["icon"], padding, (640 - icon_size) / 2, icon_size),
           body_font.outline(spec["owner"], 28, x, y, ink)]
    y += 24
    for line in titles:
        y += size * 1.15
        svg.append(title_font.outline(line, size, x, y, ink))
    y += 24
    for line in about:
        y += 44
        svg.append(body_font.outline(line, 32, x, y, muted))
    svg += ['</svg>', '']
    layout = {"canvas": [1280, 640], "title": spec["title"], "title_lines": titles,
              "title_size": size, "title_min": int(spec.get("title_min", 40)),
              "about_lines": about, "about_size": 32,
              "inputs": {key: sha256(base / spec[key]) for key in
                         ("icon", "font_title", "font_body", "font_license")}}
    if "design_sha256" in spec:
        layout["design_sha256"] = spec["design_sha256"]
    return "\n".join(svg), layout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec, base = load_spec(args.spec)
    svg, layout = render(spec, base)
    write_or_check(args.output, svg, args.check)
    write_or_check(args.output.with_suffix(".layout.json"), json.dumps(layout, indent=2) + "\n", args.check)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, ImportError) as error:
        sys.exit(str(error))
