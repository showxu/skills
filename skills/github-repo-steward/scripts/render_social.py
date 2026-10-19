#!/usr/bin/env python3
"""Render a 1280x640 outlined social card from a project-owned JSON recipe."""

import argparse
import base64
import binascii
from html import escape
from io import BytesIO
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


def raster_info(data):
    from PIL import Image
    mime_types = {"PNG": "image/png", "JPEG": "image/jpeg", "WEBP": "image/webp"}
    try:
        with Image.open(BytesIO(data), formats=list(mime_types)) as image:
            mime, dimensions = mime_types[image.format], image.size
            image.verify()
        with Image.open(BytesIO(data), formats=list(mime_types)) as image:
            for frame in range(getattr(image, "n_frames", 1)):
                image.seek(frame)
                image.load()
    except (OSError, SyntaxError, EOFError) as error:
        raise ValueError("Raster icon must be a valid PNG, JPEG or WebP image") from error
    return mime, dimensions


DIRECT_REFERENCES = {"href", "src", "base", "data", "poster", "action", "formaction", "handler"}
URL_PRESENTATION = {"fill", "stroke", "filter", "clip-path", "mask", "marker", "marker-start",
                    "marker-mid", "marker-end", "cursor", "color-profile", "background",
                    "background-image", "list-style", "list-style-image", "shape-inside",
                    "shape-outside", "shape-subtract", "offset-path"}
CSS_IMAGE_FUNCTIONS = {"image", "image-set", "-webkit-image-set"}


def fragment_reference(value):
    if not value.startswith("#"):
        raise ValueError("Icon must be self-contained SVG; only fragment URLs are allowed")


def css_references(value, strict=False):
    from tinycss2 import parse_component_value_list

    def check(tokens, image_context=False):
        tokens = [token for token in tokens if token.type not in {"whitespace", "comment"}]
        for index, token in enumerate(tokens):
            if token.type == "error" and (strict or token.kind == "bad-url"):
                raise ValueError("Icon must be self-contained SVG with valid CSS references")
            if token.type == "string" and image_context:
                fragment_reference(token.value)
            if token.type == "url":
                fragment_reference(token.value)
            elif token.type == "at-keyword" and token.lower_value == "import":
                target = tokens[index + 1] if index + 1 < len(tokens) else None
                if target is not None and target.type == "string":
                    fragment_reference(target.value)
                elif not (target is not None and (target.type == "url" or
                          (target.type == "function" and target.lower_name == "url"))):
                    raise ValueError("Icon must be self-contained SVG with a fragment CSS import")
            elif token.type == "function":
                arguments = [item for item in token.arguments if item.type not in {"whitespace", "comment"}]
                if image_context and token.lower_name in {"var", "env", "attr"}:
                    raise ValueError("Icon must be self-contained SVG with literal fragment URLs")
                if token.lower_name in {"url", "src"}:
                    if len(arguments) != 1 or arguments[0].type != "string":
                        raise ValueError("Icon must be self-contained SVG with literal fragment URLs")
                    fragment_reference(arguments[0].value)
                # type() strings describe MIME types, rather than image sources.
                sources = token.lower_name in CSS_IMAGE_FUNCTIONS or (image_context and token.lower_name != "type")
                check(arguments, sources)
            elif hasattr(token, "content"):
                check(token.content, image_context)

    check(parse_component_value_list(value, skip_comments=True))


def icon_svg(path, x, y, size):
    data = path.read_bytes()
    try:
        root = ET.fromstring(data)
    except ET.ParseError:
        mime, (width, height) = raster_info(data)
        if width != height:
            raise ValueError(f"Raster icon must be square; got {width}x{height} pixels")
        if width < size:
            raise ValueError(f"Raster icon must be at least {size:g}x{size:g} pixels; got {width}x{height}")
        uri = f"data:{mime};base64," + base64.b64encode(data).decode("ascii")
        return f'<image x="{x}" y="{y}" width="{size}" height="{size}" href="{uri}"/>'
    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise ValueError("Icon must be SVG, PNG, JPEG or WebP")
    for node in root.iter():
        tag = node.tag.rsplit("}", 1)[-1]
        if tag in {"script", "foreignObject", "text"}:
            raise ValueError("Icon must be static SVG with outlined lettering")
        if tag == "style":
            css_references("".join(node.itertext()), strict=True)
        if tag in {"set", "animate", "animateColor", "animateMotion", "animateTransform"}:
            target = node.get("attributeName", "").strip().rsplit(":", 1)[-1].lower()
            if (target in DIRECT_REFERENCES | URL_PRESENTATION | {"style", "attributename"}
                    or target.startswith(("marker-", "on"))):
                raise ValueError("Icon must be self-contained SVG; animation cannot change references")
        for key, value in node.attrib.items():
            attribute = key.rsplit("}", 1)[-1]
            if attribute.lower().startswith("on"):
                raise ValueError("Icon must be self-contained SVG")
            if attribute != "href":
                if attribute in DIRECT_REFERENCES and not (attribute == "base" and not value):
                    fragment_reference(value)
                # Metadata and geometry need URL checks without requiring valid CSS.
                css_references(value, strict=attribute == "style" or attribute in URL_PRESENTATION)
            if attribute == "href" and not value.startswith("#"):
                match = re.fullmatch(r"data:(image/(?:png|jpeg|webp));base64,(.+)", value)
                if tag != "image" or not match:
                    raise ValueError("Icon must be self-contained SVG")
                try:
                    embedded = base64.b64decode(match[2], validate=True)
                except binascii.Error as error:
                    raise ValueError("Embedded raster image needs valid base64 data") from error
                mime, _ = raster_info(embedded)
                if mime != match[1]:
                    raise ValueError("Embedded raster image format must match its data URI")
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
    owner_font = Face(base / spec["font_owner"]) if "font_owner" in spec else body_font
    owner_size = float(spec.get("owner_size", 28))
    if owner_size <= 0:
        raise ValueError("Owner font size must be positive")
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
    if owner_font.width(spec["owner"], owner_size) > width:
        raise ValueError("Owner label exceeds the text area")
    block_height = owner_size + 24 + len(titles) * size * 1.15 + 24 + len(about) * 44
    if block_height > 640 - 2 * padding:
        raise ValueError("Text block exceeds the card height")
    y = (640 - block_height) / 2 + owner_size
    ink, muted = spec.get("ink", "#000000"), spec.get("muted", "#444444")
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="640" viewBox="0 0 1280 640" role="img" aria-labelledby="title desc">',
           '<title id="title">' + escape(spec["title"]) + '</title>',
           '<desc id="desc">' + escape(spec["about"]) + '</desc>',
           '<rect width="1280" height="640" fill="' + spec.get("background", "#ffffff") + '"/>',
           icon_svg(base / spec["icon"], padding, (640 - icon_size) / 2, icon_size),
           owner_font.outline(spec["owner"], owner_size, x, y, ink)]
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
    if "font_owner" in spec:
        layout["inputs"]["font_owner"] = sha256(base / spec["font_owner"])
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
