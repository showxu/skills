#!/usr/bin/env python3
"""Render Apple-style app icons in each generation's style, with web icons, from DESIGN.md."""

from __future__ import annotations

import argparse
import base64
from collections import deque
import html
import json
import math
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zlib

PLATFORMS = ("iOS", "macOS", "watchOS")
RENDITIONS = ("Default", "Dark", "ClearLight", "ClearDark", "TintedLight", "TintedDark")
STYLES = ("liquid-glass", "flat", "mac-tile", "gloss")
STYLE_FIELDS = {"liquid-glass": {"groups", "design_generation"}, "flat": {"groups"},
                "mac-tile": {"groups", "unclipped"}, "gloss": {"groups"}}
GENERATIONS = (26, 27)
ENTRY_FIELDS = {"background", "gradient", "groups", "maskable_scale", "styles", "web_dark"}
GROUP_MATERIALS = ("shadow", "translucency", "blur-material", "refractivity", "blend-mode", "specular", "opacity")
GROUP_FIELDS = {"name", "layers", *GROUP_MATERIALS, *(f"{key}-specializations" for key in GROUP_MATERIALS)}
LAYER_FIELDS = {"source", "name", "fill", "fill-specializations", "opacity", "opacity-specializations"}
APPEARANCES = {"default": "light", "dark": "dark", "tinted": "tinted"}
MASKED_WEB_SIZES = (("favicon-16.png", 16), ("favicon-32.png", 32), ("icon-192.png", 192),
                    ("icon-512.png", 512), ("avatar-1024.png", 1024))
BLEND_MODES = ("normal", "plus-lighter", "plus-darker", "overlay", "multiply",
               "soft-light", "hard-light", "darken", "lighten", "screen")
SHADOW_KINDS = ("neutral", "chromatic", "layer-color", "none")
SAFE_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*\Z")

# Icon Composer mask, measured for design generations 26 and 27 (references/rendering.md):
# edge departure and control values per side, two mirrored cubics per corner.
CORNER = (0.396305, 0.230261, 0.152117, 0.076058)
# Apple's continuous corner per unit radius, read from SwiftUI
# RoundedRectangle(style: .continuous): three cubics from the departure on one
# edge (u along that edge, v along the next) to the same departure on the next.
CONTINUOUS = (1.528665, (((1.088490, 0), (0.868407, 0), (0.631494, 0.074911)),
                         ((0.372824, 0.169060), (0.169060, 0.372824), (0.074911, 0.631494)),
                         ((0, 0.868407), (0, 1.088490), (0, 1.528665))))
OVERRUN = 0.01                  # px by which two corners' departures must exceed their edge to need a blend
BLEND_HANDLE = 2 / 3            # share of the way to the tangents' intersection, as a quadratic would reach
EDGES = ("right", "bottom", "left", "top")  # the edge after each corner, clockwise from top-right
# Legacy geometry on the 1024 px canvas, measured against Apple's production templates
# (references/rendering.md); the gloss values are documented approximations.
FLAT_RADIUS = 229 / 1024        # continuous radius per side, iOS 7-18
MAC_TILE = (100, 824, 185.4)    # inset, side and continuous radius, macOS 11-15
MAC_SHADOW = (10, 10, 0.3)      # y offset, Gaussian deviation and black opacity
GLOSS_RADIUS = 10 / 57          # circular radius per side, iOS 1-6
GLOSS_PATH = "M0 0H1024V400Q512 620 0 400Z"
GLOSS_STOPS = (0.5, 0.1)        # white opacity at the top and at the bottom of the highlight

PNG_TOLERANCE = 1               # per-channel difference that drift checks treat as equal
LINT_SIZE = 256
LINT_DISPLAY = 32
ADVISED_GROUPS = 3
MIN_SEPARATION = 0.10           # OKLab lightness between a group and what it sits on
MIN_OVERLAP = 0.01              # share of the smaller group that makes two groups adjacent
CLIP_TOLERANCE = 0.005          # share of a group's artwork allowed outside the shape
FULL_BLEED = 0.95               # coverage at which a group is a background layer the shape crops
REVERSAL = -0.999               # cosine between joined tangents at which a path turns back on itself
REVERSAL_LENGTH = 0.5           # path units a reversal must retrace to be reported


def fail(message):
    raise ValueError(message)


def read_entries(path):
    text = path.read_text()
    section = re.search(r"^## Iconography\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    block = re.search(r"^```json\s*\n(.*?)^```\s*$", section[1], re.M | re.S) if section else None
    if not block:
        fail("DESIGN.md needs an Iconography section with a JSON block")
    entries = json.loads(block[1]).get("app_icons")
    if not isinstance(entries, dict) or not entries:
        fail("Iconography needs a nonempty app_icons object")
    for name in entries:
        if not SAFE_NAME.fullmatch(name):
            fail(f"invalid icon name: {name}")
    return entries


def color(value):
    if not isinstance(value, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        fail("background must be a six-digit hex color")
    return "srgb:" + ",".join(f"{int(value[i:i+2], 16)/255:.5f}" for i in (1, 3, 5)) + ",1.00000"


def layer_fill(value):
    if not isinstance(value, dict) or len(value) != 1 or next(iter(value)) not in ("solid", "automatic-gradient"):
        fail("layer fill needs exactly one solid or automatic-gradient color")
    kind, hex_color = next(iter(value.items()))
    if not isinstance(hex_color, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?", hex_color):
        fail("layer fill color must be #RRGGBB or #RRGGBBAA")
    rgba = hex_color + "FF" if len(hex_color) == 7 else hex_color
    return {kind: "srgb:" + ",".join(f"{int(rgba[i:i+2], 16)/255:.5f}" for i in (1, 3, 5, 7))}


def validate_svg(data):
    root = ET.fromstring(data)
    viewbox = [float(v) for v in re.split(r"[\s,]+", root.get("viewBox", "").strip()) if v]
    if root.tag.split("}")[-1] != "svg" or viewbox != [0, 0, 1024, 1024]:
        fail("SVG layers need viewBox=\"0 0 1024 1024\"")
    for node in root.iter():
        if node.tag.split("}")[-1] in {"text", "script", "foreignObject"}:
            fail("SVG layers must use outlined artwork without text or executable content")
        for key, value in node.attrib.items():
            if key.split("}")[-1] == "href" and not value.startswith(("#", "data:image/")):
                fail("SVG layers must not depend on external files or URLs")
            if "url(" in value and not re.fullmatch(r"url\(#[^)]+\)", value):
                fail("SVG paint references must be local fragment IDs")
    return root


def unit(value, label):
    if isinstance(value, bool) or not isinstance(value, (float, int)) or not 0 <= value <= 1:
        fail(f"{label} must be a number from 0 to 1")
    return value


def material(group):
    if "name" in group and (not isinstance(group["name"], str) or not group["name"]):
        fail("group name must be nonempty text")
    if "blur-material" in group:
        unit(group["blur-material"], "blur-material")
    if "opacity" in group:
        unit(group["opacity"], "group opacity")
    if "specular" in group and not isinstance(group["specular"], bool):
        fail("specular must be true or false")
    if "blend-mode" in group and group["blend-mode"] not in BLEND_MODES:
        fail(f"blend-mode must be one of {', '.join(BLEND_MODES)}")
    for key, fields in {"translucency": {"enabled", "value"},
                        "refractivity": {"enabled", "strength", "depth"},
                        "shadow": {"kind", "opacity"}}.items():
        if key not in group:
            continue
        obj = group[key]
        if not isinstance(obj, dict) or set(obj) != fields:
            fail(f"{key} needs exactly {', '.join(sorted(fields))}")
        if key == "shadow":
            if obj["kind"] not in SHADOW_KINDS:
                fail(f"shadow kind must be one of {', '.join(SHADOW_KINDS)}")
        elif not isinstance(obj["enabled"], bool):
            fail(f"{key}.enabled must be true or false")
        for field in fields - {"enabled", "kind"}:
            unit(obj[field], f"{key}.{field}")


def material_value(key, value):
    material({key: value})
    if key == "shadow" and value["kind"] == "chromatic":
        return {**value, "kind": "layer-color"}
    return value


def specialize(source, native, key, convert):
    """Encode one native property with its inherited value and appearance overrides."""
    field = f"{key}-specializations"
    if field not in source:
        return
    overrides = source[field]
    if not isinstance(overrides, dict) or not overrides or set(overrides) - APPEARANCES.keys():
        fail(f"{field} must map default, dark, or tinted to {key} values")
    # Scalar and specialized native properties are alternative encodings: the scalar
    # wins if both exist. An unqualified specialization carries the inherited value.
    values = [{"value": native.pop(key)}] if key in native else []
    for appearance, native_appearance in APPEARANCES.items():
        if appearance in overrides:
            try:
                value = convert(overrides[appearance])
            except ValueError as exc:
                fail(f"{field}.{appearance}: {exc}")
            values.append({"appearance": native_appearance, "value": value})
    native[field] = values


def entry_styles(spec):
    """Return the entry's style options, defaulting to Liquid Glass alone."""
    styles = spec.get("styles", {"liquid-glass": {}})
    if not isinstance(styles, dict) or not styles:
        fail("styles must be a nonempty object")
    for style, options in styles.items():
        if style not in STYLES:
            fail(f"unknown style: {style}; use one of {', '.join(STYLES)}")
        if not isinstance(options, dict):
            fail(f"style {style} must be an object")
        unknown = set(options) - STYLE_FIELDS[style]
        if unknown:
            fail(f"style {style} does not accept {sorted(unknown)}")
        generation = options.get("design_generation")
        if generation is not None and (isinstance(generation, bool) or generation not in GENERATIONS):
            fail(f"design_generation must be one of {', '.join(map(str, GENERATIONS))}")
    return styles


def select_style(spec, requested):
    styles = entry_styles(spec)
    if requested is None:
        if len(styles) != 1:
            fail(f"--style is required; the entry declares {', '.join(styles)}")
        return next(iter(styles))
    if requested not in styles:
        fail(f"the entry does not declare style {requested}")
    return requested


def prepare(spec, base, style):
    """Validate the entry for one style and load that style's layers."""
    if not isinstance(spec, dict):
        fail("an app icon entry must be an object")
    unknown = set(spec) - ENTRY_FIELDS
    if unknown:
        fail(f"unknown app icon fields: {sorted(unknown)}")
    fill = color(spec.get("background"))
    if not isinstance(spec.get("gradient", False), bool):
        fail("gradient must be true or false")
    if not isinstance(spec.get("web_dark", False), bool):
        fail("web_dark must be true or false")
    scale = spec.get("maskable_scale", 0.56)
    if not isinstance(scale, (float, int)) or not 0 < scale <= 0.56:
        fail("maskable_scale must be greater than zero and at most 0.56")
    styles = entry_styles(spec)
    if style not in styles:
        fail(f"the entry does not declare style {style}")
    options = styles[style]
    groups = options.get("groups", spec.get("groups"))
    if not isinstance(groups, list) or not 1 <= len(groups) <= 4:
        fail("supply between one and four foreground groups")
    unclipped = options.get("unclipped", [])
    if (not isinstance(unclipped, list) or len(set(unclipped)) != len(unclipped)
            or any(isinstance(i, bool) or not isinstance(i, int) or not 1 <= i <= len(groups)
                   for i in unclipped)):
        fail("unclipped must list distinct group positions from 1 to the number of groups")
    document = {"fill": {"automatic-gradient" if spec.get("gradient") else "solid": fill},
                "groups": [], "supported-platforms": {"circles": ["watchOS"], "squares": "shared"}}
    assets = {}
    loaded = []
    for gi, group in enumerate(groups):
        if not isinstance(group, dict) or set(group) - GROUP_FIELDS:
            fail(f"group {gi + 1} has unknown fields")
        material(group)
        layers = group.get("layers")
        if not isinstance(layers, list) or not layers:
            fail(f"group {gi + 1} needs layers")
        native = {k: v for k, v in group.items() if k != "layers" and not k.endswith("-specializations")}
        for key in GROUP_MATERIALS:
            if key in native:
                native[key] = material_value(key, native[key])
            specialize(group, native, key, lambda value: material_value(key, value))
        native["layers"] = []
        art = []
        for li, layer in enumerate(layers):
            if not isinstance(layer, dict) or set(layer) - LAYER_FIELDS:
                fail(f"group {gi + 1}, layer {li + 1}: unknown layer fields")
            native_material = {}
            if "fill" in layer:
                native_material["fill"] = layer_fill(layer["fill"])
            specialize(layer, native_material, "fill", layer_fill)
            if "opacity" in layer:
                unit(layer["opacity"], "layer opacity")
                native_material["opacity"] = layer["opacity"]
            specialize(layer, native_material, "opacity", lambda value: unit(value, "layer opacity"))
            source = layer.get("source")
            if "name" in layer and (not isinstance(layer["name"], str) or not layer["name"]):
                fail("layer name must be nonempty text")
            if not isinstance(source, str) or not source or Path(source).is_absolute():
                fail("layer sources must be paths relative to DESIGN.md")
            path = (base / source).resolve()
            if not path.is_file() or path.suffix.lower() not in {".svg", ".png"}:
                fail(f"missing or unsupported layer: {source}")
            data = path.read_bytes()
            suffix = path.suffix.lower()
            if suffix == ".svg":
                validate_svg(data)
            elif data[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", data[16:24]) != (1024, 1024):
                fail("PNG layers must be 1024 px square")
            filename = f"{gi + 1:02d}-{li + 1:02d}{suffix}"
            assets[filename] = data
            native["layers"].append({"image-name": filename, "name": layer.get("name", path.stem),
                                     **native_material})
            art.append((suffix, data))
        refractivities = [group.get("refractivity", {})] + list(group.get("refractivity-specializations", {}).values())
        if any(value.get("enabled") for value in refractivities):
            document["features"] = ["refractivity"]
        # Icon Composer lists the foremost layer and group first; SVG paints last on top.
        native["layers"].reverse()
        document["groups"].insert(0, native)
        loaded.append({"label": group.get("name", f"group {gi + 1}"), "art": art,
                       "clipped": gi + 1 not in unclipped,
                       "native_fill": any("fill" in layer or "fill-specializations" in layer for layer in layers)})
    return document, assets, loaded, options


def rounded_path(x, y, side, departure, segments):
    """A closed rounded square; each corner runs `segments` in its (u, v) frame."""
    out = []
    for (cx, cy), e1, e2 in (((x + side, y), (-1, 0), (0, 1)), ((x + side, y + side), (0, -1), (-1, 0)),
                             ((x, y + side), (1, 0), (0, -1)), ((x, y), (0, 1), (1, 0))):
        def at(u, v):
            return f"{cx+u*e1[0]+v*e2[0]:.2f} {cy+u*e1[1]+v*e2[1]:.2f}"
        out.append(("M" if not out else "L") + at(departure, 0))
        out.append("".join(f"C{at(*a)} {at(*b)} {at(*c)}" for a, b, c in segments))
    return "".join(out) + "Z"


def glass_path(x=0, y=0, side=1024):
    l, c1, c2, d = (v * side for v in CORNER)
    return rounded_path(x, y, side, l, (((c1, 0), (c2, 0), (d, d)), ((0, c2), (0, c1), (0, l))))


def continuous_path(x, y, side, radius):
    return continuous_rect(x, y, side, side, radius)


def cubic_point(cubic, t):
    s = 1 - t
    return tuple(s * s * s * a + 3 * s * s * t * b + 3 * s * t * t * c + t * t * t * d for a, b, c, d in zip(*cubic))


def split_cubic(cubic, t):
    """The parts of a cubic before and after parameter t (de Casteljau)."""
    def lerp(a, b):
        return tuple(p + (q - p) * t for p, q in zip(a, b))
    p0, p1, p2, p3 = cubic
    a, b, c = lerp(p0, p1), lerp(p1, p2), lerp(p2, p3)
    d, e = lerp(a, b), lerp(b, c)
    f = lerp(d, e)
    return (p0, a, d, f), (f, e, c, p3)


def corner_cubics():
    """The unit continuous corner as (start, control, control, end) cubics in its (u, v) frame."""
    start, cubics = (CONTINUOUS[0], 0), []
    for c1, c2, end in CONTINUOUS[1]:
        cubics.append((start, c1, c2, end))
        start = end
    return cubics


def corner_position(axis, target):
    """(cubic index, t) where the unit corner's u (axis 0, falling) or v (axis 1, rising) equals target."""
    for index, cubic in enumerate(corner_cubics()):
        first, last = cubic[0][axis], cubic[3][axis]
        if min(first, last) <= target <= max(first, last):
            low, high = 0.0, 1.0
            for _ in range(52):
                middle = (low + high) / 2
                if (cubic_point(cubic, middle)[axis] < target) == (last > first):
                    low = middle
                else:
                    high = middle
            return index, (low + high) / 2
    fail("corner position outside the curve")


def corner_piece(start, end):
    """The unit corner's cubics between two (cubic index, t) positions."""
    pieces = []
    for index, cubic in enumerate(corner_cubics()):
        low = start[1] if index == start[0] else 0.0
        high = end[1] if index == end[0] else 1.0
        if not start[0] <= index <= end[0] or high - low < 1e-12:
            continue
        if high < 1:
            cubic = split_cubic(cubic, high)[0]
        if low > 0:
            cubic = split_cubic(cubic, low / high)[1]
        pieces.append(cubic)
    return pieces


def continuous_corners(width, height, radii):
    """Radii in drawing order (top-right, bottom-right, bottom-left, top-left), each capped at half
    the shorter side, and how far each following edge's two corner departures exceed its length."""
    values = [radii] * 4 if isinstance(radii, (int, float)) else list(radii)
    if len(values) != 4 or any(isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v)
                               for v in (width, height, *values)):
        fail("a continuous rectangle needs a finite size and one or four finite radii")
    if width <= 0 or height <= 0 or min(values) < 0:
        fail("a continuous rectangle needs a positive size and radii of at least zero")
    limit = min(width, height) / 2
    top_left, top_right, bottom_right, bottom_left = (min(v, limit) for v in values)
    radii = (top_right, bottom_right, bottom_left, top_left)
    lengths = (height, width, height, width)
    return radii, [CONTINUOUS[0] * (radii[i] + radii[(i + 1) % 4]) - lengths[i] for i in range(4)]


def tangent_blend(p, p_direction, q, q_direction, box):
    """Cubic control points joining p, arriving along p_direction, to q, leaving along q_direction.

    Handles run toward the tangents' intersection and stop at the edge of `box` (x0, y0, x1, y1),
    so the blend stays inside it.
    """
    (dx, dy), (ex, ey) = p_direction, q_direction
    rx, ry = q[0] - p[0], q[1] - p[1]
    a = (rx * ey - ry * ex) / (dx * ey - dy * ex)
    meet = (p[0] + a * dx, p[1] + a * dy)

    def handle(origin):
        share = BLEND_HANDLE
        for axis in (0, 1):
            step = meet[axis] - origin[axis]
            bound = box[axis + 2] if step > 0 else box[axis]
            if step:
                share = min(share, max(0.0, (bound - origin[axis]) / step))
        return tuple(o + share * (m - o) for o, m in zip(origin, meet))
    return handle(p), handle(q)


def continuous_rect(x, y, width, height, radii):
    """Path data for a rectangle with Apple continuous corners of one or four radii.

    `radii` is one radius or (top-left, top-right, bottom-right, bottom-left), each capped at half
    the shorter side. Where an edge is shorter than its two corners' departures, each corner stops
    where the other leaves that edge and a tangent cubic joins them instead of a line that doubles
    back (references/rendering.md).
    """
    radii, excess = continuous_corners(width, height, radii)
    lengths = (height, width, height, width)
    frames = (((x + width, y), (-1, 0), (0, 1)), ((x + width, y + height), (0, -1), (-1, 0)),
              ((x, y + height), (1, 0), (0, -1)), ((x, y), (0, 1), (1, 0)))
    corners = []
    for i, ((cx, cy), e1, e2) in enumerate(frames):
        radius = radii[i]
        if not radius:
            corners.append([])
            continue
        start, end = (0, 0.0), (len(CONTINUOUS[1]) - 1, 1.0)
        if excess[i - 1] > OVERRUN:
            start = corner_position(0, (lengths[i - 1] - CONTINUOUS[0] * radii[i - 1]) / radius)
        if excess[i] > OVERRUN:
            end = corner_position(1, (lengths[i] - CONTINUOUS[0] * radii[(i + 1) % 4]) / radius)
        corners.append([tuple((cx + u * radius * e1[0] + v * radius * e2[0], cy + u * radius * e1[1] + v * radius * e2[1])
                              for u, v in cubic) for cubic in corner_piece(start, end)])

    def at(point):
        return f"{point[0]:.2f} {point[1]:.2f}"

    def join(i):
        """The connection from corner i to the start of the next corner."""
        after = corners[(i + 1) % 4]
        target = after[0][0] if after else frames[(i + 1) % 4][0]
        if excess[i] <= OVERRUN:
            return "L" + at(target)
        (_, _, c2, p), (q, c1, _, _) = corners[i][-1], after[0]
        h1, h2 = tangent_blend(p, (p[0] - c2[0], p[1] - c2[1]), q, (c1[0] - q[0], c1[1] - q[1]),
                               (x, y, x + width, y + height))
        return f"C{at(h1)} {at(h2)} {at(q)}"

    path = ["M" + at(corners[0][0][0] if corners[0] else frames[0][0])]
    for i, cubics in enumerate(corners):
        path.append("".join(f"C{at(b)} {at(c)} {at(d)}" for _, b, c, d in cubics))
        if i < 3:
            path.append(join(i))
    if excess[3] > OVERRUN:
        path.append(join(3))
    return "".join(path) + "Z"


def shape(style):
    """The style's icon outline on the 1024 px canvas."""
    if style == "liquid-glass":
        return f'<path d="{glass_path()}"/>'
    if style == "flat":
        return f'<path d="{continuous_path(0, 0, 1024, FLAT_RADIUS * 1024)}"/>'
    if style == "mac-tile":
        inset, side, radius = MAC_TILE
        return f'<path d="{continuous_path(inset, inset, side, radius)}"/>'
    radius = GLOSS_RADIUS * 1024
    return f'<rect width="1024" height="1024" rx="{radius:.2f}" ry="{radius:.2f}"/>'


def art_shape(style):
    """The style's outline in artwork coordinates, where mac-tile art fills the tile."""
    if style == "mac-tile":
        inset, side, radius = MAC_TILE
        return f'<path d="{continuous_path(0, 0, 1024, radius * 1024 / side)}"/>'
    return shape(style)


def image(suffix, data, extent=None):
    """An artwork layer; `extent` widens an SVG layer's viewport to (x, side) art units."""
    if extent is not None and suffix == ".svg":
        x, side = extent
        data = re.sub(rb"viewBox\s*=\s*([\"'])[^\"']*\1", f'viewBox="{x:.4f} {x:.4f} {side:.4f} {side:.4f}"'.encode(),
                      data, count=1)
    mime = "image/svg+xml" if suffix == ".svg" else "image/png"
    return f'<image width="1024" height="1024" href="data:{mime};base64,{base64.b64encode(data).decode()}"/>'


def background(spec):
    fill = spec["background"]
    if not spec.get("gradient"):
        return fill, ""
    top = "#" + "".join(f"{round(int(fill[i:i+2], 16) * 0.8 + 255 * 0.2):02x}" for i in (1, 3, 5))
    return "url(#fill)", (f'<linearGradient id="fill" x1="0" y1="0" x2="0" y2="1">'
                          f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{fill}"/>'
                          f'</linearGradient>')


def compose(style, spec, groups, masked=True, scale=1.0):
    """SVG for one style: the masked icon, or a full-bleed square for platform masks."""
    paint, gradient = background(spec)
    defs = [gradient, f'<clipPath id="shape">{shape(style)}</clipPath>']
    gloss = ""
    if style == "gloss":
        top, bottom = GLOSS_STOPS
        defs.append('<linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1">'
                    f'<stop offset="0" stop-color="#fff" stop-opacity="{top}"/>'
                    f'<stop offset="1" stop-color="#fff" stop-opacity="{bottom}"/></linearGradient>')
        gloss = f'<path d="{GLOSS_PATH}" fill="url(#gloss)"/>'
    if masked and style == "mac-tile":
        inset, side, radius = MAC_TILE
        dy, deviation, opacity = MAC_SHADOW
        defs.append('<filter id="shadow" x="-25%" y="-25%" width="150%" height="150%">'
                    f'<feGaussianBlur in="SourceAlpha" stdDeviation="{deviation}"/>'
                    f'<feOffset dy="{dy}" result="blur"/>'
                    f'<feFlood flood-color="#000" flood-opacity="{opacity}"/>'
                    '<feComposite in2="blur" operator="in"/>'
                    '<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>')
        fit = f"translate({inset} {inset}) scale({side / 1024})"
        # Art outside its own 0-1024 box shows only for unclipped groups, up to the canvas edge.
        margin = inset * 1024 / side
        body = [f'<path d="{continuous_path(inset, inset, side, radius)}" fill="{paint}"/>']
        for group in groups:
            if group["clipped"]:
                layers = "".join(image(*layer) for layer in group["art"])
                body.append(f'<g clip-path="url(#shape)"><g transform="{fit}">{layers}</g></g>')
            else:
                body.append("".join(image(*layer, extent=(-margin, 1024 + 2 * margin))
                                    for layer in group["art"]))
        content = f'<g filter="url(#shadow)">{"".join(body)}</g>'
    else:
        inset = 512 * (1 - scale)
        layers = "".join(image(*layer) for group in groups for layer in group["art"])
        content = (f'<rect width="1024" height="1024" fill="{paint}"/>'
                   f'<g transform="translate({inset} {inset}) scale({scale})">{layers}</g>{gloss}')
        if masked:
            content = f'<g clip-path="url(#shape)">{content}</g>'
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            f'<defs>{"".join(defs)}</defs>{content}</svg>\n')


def find_ictool(explicit=None):
    override = explicit or os.environ.get("IC_TOOL")
    candidates = [override] if override else []
    if not override:
        selected = subprocess.run(["xcode-select", "-p"], capture_output=True, text=True)
        if selected.returncode == 0:
            candidates.append(str(Path(selected.stdout.strip()).parent /
                                  "Applications/Icon Composer.app/Contents/Executables/ictool"))
        candidates.append(shutil.which("ictool"))
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            help_result = subprocess.run([candidate, "--help"], capture_output=True, text=True)
            if "--export-image" in help_result.stdout + help_result.stderr:
                return candidate
    fail("Icon Composer's export-capable ictool was not found; supply --ictool or IC_TOOL")


def run(args):
    result = subprocess.run(list(map(str, args)), capture_output=True, text=True)
    if result.returncode:
        fail(f"{Path(str(args[0])).name} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def png_payload(path, expected_size=None):
    """Ignore ancillary metadata while comparing the lossless encoded image data."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        fail(f"renderer did not produce PNG: {path.name}")
    if len(data) < 33 or data[12:16] != b"IHDR":
        fail(f"PNG is missing its image header: {path.name}")
    dimensions = struct.unpack(">II", data[16:24])
    if expected_size is not None and dimensions != (expected_size, expected_size):
        fail(f"PNG dimensions for {path.name}: expected {expected_size}x{expected_size}, "
             f"got {dimensions[0]}x{dimensions[1]}")
    pos, header, compressed = 8, b"", bytearray()
    while pos + 12 <= len(data):
        size, kind = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + size]
        if kind in {b"IHDR", b"PLTE", b"tRNS"}:
            header += kind + chunk
        elif kind == b"IDAT":
            compressed.extend(chunk)
        pos += size + 12
    return header + zlib.decompress(compressed)


def render_png(svg, target, size):
    run(["rsvg-convert", "-w", size, "-h", size, svg, "-o", target])
    png_payload(target, size)


def resize_png(source, target, size):
    wrapper = target.with_suffix(".svg")
    encoded = base64.b64encode(source.read_bytes()).decode()
    wrapper.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">'
                       f'<image width="1024" height="1024" href="data:image/png;base64,{encoded}"/></svg>\n')
    render_png(wrapper, target, size)
    wrapper.unlink()


def label(text, x, y, dark):
    fill = "#eeeeee" if dark else "#111111"
    return (f'<text x="{x}" y="{y}" text-anchor="middle" font-family="sans-serif" font-size="11" '
            f'fill="{fill}">{html.escape(text)}</text>')


def native_sheet(files):
    cell, row, width = 180, 220, 6 * 180
    height = len(PLATFORMS) * row * 2
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">']
    for bi, bg in enumerate(("#ffffff", "#0d1117")):
        top = bi * len(PLATFORMS) * row
        parts.append(f'<rect y="{top}" width="{width}" height="{len(PLATFORMS)*row}" fill="{bg}"/>')
        for pi, platform in enumerate(PLATFORMS):
            for ri, rendition in enumerate(RENDITIONS):
                y, x = top + pi * row, ri * cell
                source = "renditions/" + files[(platform, rendition)].name
                parts.append(f'<image x="{x+10}" y="{y+4}" width="160" height="160" href="{source}"/>')
                parts.append(f'<image x="{x+70}" y="{y+163}" width="32" height="32" href="{source}"/>')
                parts.append(label(f"{platform} · {rendition}", x + 90, y + 212, bi))
    return "".join(parts) + "</svg>\n"


def style_sheet(name):
    cells = ((f"{name}.svg", "Icon", None), ("web/apple-touch-icon.png", "Touch, full bleed", None),
             ("web/maskable-512.png", "Maskable, circle crop", "circle"))
    cell, row = 180, 220
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(cells) * cell}" height="{2 * row}">',
             '<defs><clipPath id="circle"><circle cx="80" cy="80" r="80"/></clipPath></defs>']
    for bi, bg in enumerate(("#ffffff", "#0d1117")):
        parts.append(f'<rect y="{bi * row}" width="{len(cells) * cell}" height="{row}" fill="{bg}"/>')
        for ci, (source, text, crop) in enumerate(cells):
            x, y = ci * cell, bi * row
            clip = f' clip-path="url(#{crop})"' if crop else ""
            parts.append(f'<g transform="translate({x+10} {y+4})"><image width="160" height="160" '
                         f'href="{source}"{clip}/></g>')
            parts.append(f'<image x="{x+74}" y="{y+167}" width="32" height="32" href="{source}"/>')
            parts.append(label(text, x + 90, y + 212, bi))
    return "".join(parts) + "</svg>\n"


def web_set(web, style, spec, groups, masked_source):
    """Write the web icons; masked sizes come from `masked_source`, a 1024 px PNG or SVG."""
    web.mkdir()
    (web / "favicon.svg").write_text(compose(style, spec, groups))
    (web / "touch.svg").write_text(compose(style, spec, groups, masked=False))
    (web / "maskable.svg").write_text(compose(style, spec, groups, masked=False,
                                              scale=spec.get("maskable_scale", 0.56)))
    for target, size in MASKED_WEB_SIZES:
        if masked_source.suffix == ".png":
            resize_png(masked_source, web / target, size)
        else:
            render_png(masked_source, web / target, size)
    render_png(web / "touch.svg", web / "apple-touch-icon.png", 180)
    render_png(web / "maskable.svg", web / "maskable-512.png", 512)


def write_manifest(out, data):
    data["files"] = sorted(str(p.relative_to(out)) for p in out.rglob("*") if p.is_file())
    (out / "manifest.json").write_text(json.dumps(data, indent=2) + "\n")


def build(name, spec, base, out, style="liquid-glass", ictool=None, document_only=False):
    document, assets, groups, options = prepare(spec, base, style)
    if style != "liquid-glass":
        if document_only:
            fail("--document-only applies to the liquid-glass style")
        out.mkdir()
        (out / f"{name}.svg").write_text(compose(style, spec, groups))
        web_set(out / "web", style, spec, groups, out / f"{name}.svg")
        (out / "contact-sheet.svg").write_text(style_sheet(name))
        run(["rsvg-convert", out / "contact-sheet.svg", "-o", out / "contact-sheet.png"])
        inset, side, radius = MAC_TILE
        geometry = {"flat": {"continuous_radius": FLAT_RADIUS},
                    "mac-tile": {"inset": inset, "side": side, "continuous_radius": radius,
                                 "shadow": dict(zip(("dy", "deviation", "opacity"), MAC_SHADOW))},
                    "gloss": {"circular_radius": round(GLOSS_RADIUS, 6), "highlight": GLOSS_PATH,
                              "highlight_opacity": list(GLOSS_STOPS)}}[style]
        write_manifest(out, {"style": style, "rendering": "style-rendering",
                             "renderer": run(["rsvg-convert", "--version"]), "geometry": geometry})
        return
    doc = out / f"{name}.icon"
    (doc / "Assets").mkdir(parents=True)
    (doc / "icon.json").write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n")
    for filename, data in assets.items():
        (doc / "Assets" / filename).write_bytes(data)
    if document_only:
        return
    generation = options.get("design_generation")
    renditions = out / "renditions"
    renditions.mkdir()
    files = {}
    for platform in PLATFORMS:
        size = 1088 if platform == "watchOS" else 1024
        for rendition in RENDITIONS:
            path = renditions / f"{platform}-{rendition}.png"
            args = [ictool, doc, "--export-image", "--output-file", path, "--platform", platform,
                    "--rendition", rendition, "--width", size, "--height", size, "--scale", 1]
            if generation is not None:
                args.extend(["--design-generation", generation])
            run(args)
            png_payload(path, size)
            files[(platform, rendition)] = path
    web_set(out / "web", style, spec, groups, files[("iOS", "Default")])
    if spec.get("web_dark", False):
        dark_web = out / "web" / "dark"
        dark_web.mkdir()
        for filename, size in MASKED_WEB_SIZES:
            resize_png(files[("iOS", "Dark")], dark_web / filename, size)
    (out / "contact-sheet.svg").write_text(native_sheet(files))
    run(["rsvg-convert", out / "contact-sheet.svg", "-o", out / "contact-sheet.png"])
    write_manifest(out, {"style": style, "rendering": "native", "renderer": run([ictool, "--version"]),
                         "design_generation": generation})


def compare(candidate, target):
    expected = {str(p.relative_to(candidate)): p for p in candidate.rglob("*") if p.is_file()}
    actual = {str(p.relative_to(target)): p for p in target.rglob("*") if p.is_file()}
    differences = 0
    for name in sorted(expected.keys() | actual.keys()):
        if name not in actual:
            status = "missing"
        elif name not in expected:
            status = "extra"
        else:
            if name.endswith(".png"):
                same = png_payload(expected[name]) == png_payload(actual[name]) or same_pixels(
                    expected[name], actual[name])
            else:
                same = expected[name].read_bytes() == actual[name].read_bytes()
            status = "same" if same else "drift"
        print(f"{status}\t{name}")
        differences += status != "same"
    return differences


def read_png(path):
    """Decode a non-interlaced 8- or 16-bit RGB or RGBA PNG into 8-bit RGBA pixels."""
    data = path.read_bytes()
    pos, idat, header = 8, b"", None
    while pos < len(data):
        length, kind = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"IDAT":
            idat += chunk
        pos += 12 + length
    width, height, depth, kind, _, _, interlace = header
    if depth not in (8, 16) or kind not in (2, 6) or interlace:
        fail(f"{path.name}: only non-interlaced 8- or 16-bit RGB or RGBA PNGs are supported")
    channels, octets = (4 if kind == 6 else 3), depth // 8
    bpp = channels * octets
    raw, stride = zlib.decompress(idat), width * bpp
    rows, prev = [], bytearray(stride)
    for y in range(height):
        method, line = raw[y * (stride + 1)], bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b, c = prev[i], prev[i - bpp] if i >= bpp else 0
            if method == 1:
                line[i] = (line[i] + a) & 255
            elif method == 2:
                line[i] = (line[i] + b) & 255
            elif method == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif method == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        prev = line
    pixels = []
    for line in rows:
        for x in range(width):
            px = line[x * bpp:(x + 1) * bpp:octets]
            pixels.append(tuple(px) if channels == 4 else (*px, 255))
    return width, height, pixels


def same_pixels(first, second):
    """Equal size and every channel within PNG_TOLERANCE; native exports vary by rounding."""
    try:
        (w1, h1, a), (w2, h2, b) = read_png(first), read_png(second)
    except (ValueError, TypeError, zlib.error, struct.error):
        return False
    return (w1, h1) == (w2, h2) and all(abs(x - y) <= PNG_TOLERANCE
                                        for p, q in zip(a, b) for x, y in zip(p, q))


def lightness(r, g, b):
    """OKLab lightness of an sRGB color."""
    def linear(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = linear(r), linear(g), linear(b)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s


def shape_widths(cover, size):
    """Widest stroke, in pixels, of each 8-connected shape in a size x size coverage mask."""
    inf = size * size
    dist = [0 if not c else inf for c in cover]
    for passes in ((range(size), range(size), ((-1, -1), (-1, 0), (-1, 1), (0, -1))),
                   (range(size - 1, -1, -1), range(size - 1, -1, -1), ((1, 1), (1, 0), (1, -1), (0, 1)))):
        rows, cols, offsets = passes
        for y in rows:
            for x in cols:
                i = y * size + x
                if not dist[i]:
                    continue
                best = dist[i]
                for dy, dx in offsets:
                    ny, nx = y + dy, x + dx
                    near = dist[ny * size + nx] if 0 <= ny < size and 0 <= nx < size else 0
                    best = min(best, near + 1)
                dist[i] = best
    seen, widths = [False] * inf, []
    for start in range(inf):
        if not cover[start] or seen[start]:
            continue
        seen[start], queue, deepest = True, deque([start]), 0
        while queue:
            i = queue.popleft()
            deepest = max(deepest, dist[i])
            y, x = divmod(i, size)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    j = ny * size + nx
                    if 0 <= ny < size and 0 <= nx < size and cover[j] and not seen[j]:
                        seen[j] = True
                        queue.append(j)
        widths.append(2 * deepest - 1)
    return widths


PATH_COMMAND = re.compile(r"[\s,]*([MmLlHhVvCcSsQqTtAaZz])")
PATH_NUMBER = re.compile(r"[\s,]*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)")
PATH_FLAG = re.compile(r"[\s,]*([01])")
PATH_ARITY = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7, "Z": 0}


def path_segments(data):
    """Subpaths of SVG path data as (segments, closed).

    Each segment is (start, start direction, end, end direction); arcs have no directions.
    Parsing stops at the first error, where SVG renderers stop drawing.
    """
    subpaths, segments, closed = [], [], False
    command, previous, position = None, None, 0
    current = start = control = (0.0, 0.0)

    def add(end, *points, directions=True):
        nonlocal current
        chain = [current, *points, end]
        if any(p != current for p in chain):
            first = next((p for p in chain[1:] if p != current), None)
            last = next((p for p in reversed(chain[:-1]) if p != end), None)
            segments.append((current, (first[0] - current[0], first[1] - current[1]) if directions else None,
                             end, (end[0] - last[0], end[1] - last[1]) if directions and last else None))
        current = end

    while True:
        match = PATH_COMMAND.match(data, position)
        if match:
            command, position = match[1], match.end()
            if command in "Zz":
                add(start)
                closed, command, previous = True, None, "Z"
            continue
        if command is None or not data[position:].strip(" \t\r\n,"):
            break
        values = []
        for index in range(PATH_ARITY[command.upper()]):
            match = (PATH_FLAG if command in "Aa" and index in (3, 4) else PATH_NUMBER).match(data, position)
            if not match:
                break
            values.append(float(match[1]))
            position = match.end()
        if len(values) < PATH_ARITY[command.upper()]:
            break
        relative = command.islower()
        kind = command.upper()

        def point(i):
            return (values[i] + current[0], values[i + 1] + current[1]) if relative else (values[i], values[i + 1])
        if kind == "M":
            if segments:
                subpaths.append((segments, closed))
            segments, closed = [], False
            current = start = control = point(0)
            command, previous = "l" if relative else "L", "M"
            continue
        if closed:
            subpaths.append((segments, closed))
            segments, closed, start = [], False, current
        if kind == "H":
            add((values[0] + current[0] if relative else values[0], current[1]))
        elif kind == "V":
            add((current[0], values[0] + current[1] if relative else values[0]))
        elif kind == "L":
            add(point(0))
        elif kind in "CS":
            first = point(0) if kind == "C" else (
                (2 * current[0] - control[0], 2 * current[1] - control[1]) if previous in ("C", "S") else current)
            second, end = (point(2), point(4)) if kind == "C" else (point(0), point(2))
            add(end, first, second)
            control = second
        elif kind in "QT":
            middle = point(0) if kind == "Q" else (
                (2 * current[0] - control[0], 2 * current[1] - control[1]) if previous in ("Q", "T") else current)
            add(point(2) if kind == "Q" else point(0), middle)
            control = middle
        else:
            add(point(5), directions=not values[0] or not values[1])
        previous = kind
    if segments:
        subpaths.append((segments, closed))
    return subpaths


def doubled_back(data):
    """(x, y, length) of the longest reversal in each path of an SVG layer: a joint where the
    outline turns back on itself, retracing at least REVERSAL_LENGTH path units."""
    found = []
    for node in ET.fromstring(data).iter():
        if node.tag.split("}")[-1] != "path":
            continue
        worst = None
        for segments, closed in path_segments(node.get("d", "")):
            joints = list(zip(segments, segments[1:])) + ([(segments[-1], segments[0])] if closed else [])
            for (a0, _, a1, incoming), (b0, outgoing, b1, _) in joints:
                if not incoming or not outgoing:
                    continue
                cosine = ((incoming[0] * outgoing[0] + incoming[1] * outgoing[1]) /
                          (math.hypot(*incoming) * math.hypot(*outgoing)))
                length = min(math.dist(a0, a1), math.dist(b0, b1))
                if cosine <= REVERSAL and length >= REVERSAL_LENGTH and (not worst or length > worst[2]):
                    worst = (*a1, length)
        if worst:
            found.append(worst)
    return found


def lint_findings(groups, outline, base_lightness, size, display_scale):
    """Findings for rendered groups.

    Each group carries `label`, `clipped`, and `pixels` (RGBA at size x size in artwork
    coordinates); `outline` is the style shape's coverage there; `display_scale` maps the
    artwork to the icon at LINT_DISPLAY px.
    """
    findings = []
    if len(groups) > ADVISED_GROUPS:
        findings.append(f"{len(groups)} groups; express the idea with fewer shapes")
    covers, lights = [], []
    for group in groups:
        cover = [p[3] >= 128 for p in group["pixels"]]
        covers.append(cover)
        opaque = [p for p, c in zip(group["pixels"], cover) if c]
        lights.append(sum(lightness(*p[:3]) for p in opaque) / len(opaque) if opaque else None)
        area = len(opaque)
        if not area:
            findings.append(f"{group['label']}: no visible artwork")
            continue
        outside = sum(1 for c, inside in zip(cover, outline) if c and not inside)
        if group["clipped"] and area < FULL_BLEED * size * size and outside > CLIP_TOLERANCE * area:
            findings.append(f"{group['label']}: {100 * outside / area:.1f}% of the artwork falls outside the shape")
        factor = LINT_DISPLAY / size * display_scale
        thin = [w * factor for w in shape_widths(cover, size) if w * factor < 1]
        if thin:
            findings.append(f"{group['label']}: {len(thin)} shape(s) narrower than 1 px at {LINT_DISPLAY} px "
                            f"(thinnest {min(thin):.2f} px)")
    for i, group in enumerate(groups):
        if lights[i] is None:
            continue
        if abs(lights[i] - base_lightness) < MIN_SEPARATION:
            findings.append(f"{group['label']}: lightness {lights[i]:.2f} is too close to the "
                            f"background {base_lightness:.2f} for Clear and Tinted appearances")
        for j in range(i):
            if lights[j] is None:
                continue
            shared = sum(1 for a, b in zip(covers[i], covers[j]) if a and b)
            smaller = min(sum(covers[i]), sum(covers[j]))
            if shared >= MIN_OVERLAP * smaller and abs(lights[i] - lights[j]) < MIN_SEPARATION:
                findings.append(f"{group['label']}: lightness {lights[i]:.2f} is too close to "
                                f"{groups[j]['label']} {lights[j]:.2f} where they overlap")
    return findings


def lint(spec, base, style, work, information=None):
    _, _, groups, _ = prepare(spec, base, style)
    if information is not None:
        information.extend(f"{group['label']}: Liquid Glass appearance is determined by layer fill; "
                           "lightness findings refer to SVG/PNG artwork used by other styles"
                           for group in groups if group["native_fill"])

    def raster(name, body):
        svg = work / f"{name}.svg"
        svg.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
                       f'viewBox="0 0 1024 1024">{body}</svg>\n')
        png = work / f"{name}.png"
        render_png(svg, png, LINT_SIZE)
        return read_png(png)[2]

    outline = [p[3] >= 128 for p in raster("outline", art_shape(style).replace("/>", ' fill="#000"/>'))]
    rendered = [{**group, "pixels": raster(f"group-{i}", "".join(image(*layer) for layer in group["art"]))}
                for i, group in enumerate(groups)]
    fill = spec["background"]
    base_lightness = lightness(*(int(fill[i:i+2], 16) for i in (1, 3, 5)))
    display_scale = MAC_TILE[1] / 1024 if style == "mac-tile" else 1
    findings = lint_findings(rendered, outline, base_lightness, LINT_SIZE, display_scale)
    for group in groups:
        for li, (suffix, data) in enumerate(group["art"]):
            if suffix == ".svg":
                findings += [f"{group['label']}: layer {li + 1} path doubles back {length:.1f} units at ({x:.1f}, {y:.1f}), "
                             "a stray segment that corners whose departures exceed their edge draw"
                             for x, y, length in doubled_back(data)]
    return findings


def sheet(entries, names, base, ictool, work):
    """A self-contained comparison of each named entry in each of its styles."""
    cells = [(name, style) for name in names for style in entry_styles(entries[name])]
    cell, row = 180, 230
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(cells) * cell}" height="{2 * row}">']
    renders = []
    for ci, (name, style) in enumerate(cells):
        spec = entries[name]
        document, assets, groups, options = prepare(spec, base, style)
        large, small = work / f"{ci}-160.png", work / f"{ci}-32.png"
        if style == "liquid-glass":
            if ictool is None:
                renders.append(None)
                continue
            doc = work / f"{ci}.icon"
            (doc / "Assets").mkdir(parents=True)
            (doc / "icon.json").write_text(json.dumps(document))
            for filename, data in assets.items():
                (doc / "Assets" / filename).write_bytes(data)
            native = work / f"{ci}-native.png"
            args = [ictool, doc, "--export-image", "--output-file", native, "--platform", "iOS",
                    "--rendition", "Default", "--width", 1024, "--height", 1024, "--scale", 1]
            if options.get("design_generation") is not None:
                args.extend(["--design-generation", options["design_generation"]])
            run(args)
            resize_png(native, large, 320)
            resize_png(native, small, 32)
        else:
            svg = work / f"{ci}.svg"
            svg.write_text(compose(style, spec, groups))
            render_png(svg, large, 320)
            render_png(svg, small, 32)
        renders.append(tuple("data:image/png;base64," + base64.b64encode(p.read_bytes()).decode()
                             for p in (large, small)))
    for bi, bg in enumerate(("#ffffff", "#0d1117")):
        parts.append(f'<rect y="{bi * row}" width="{len(cells) * cell}" height="{row}" fill="{bg}"/>')
        for ci, (name, style) in enumerate(cells):
            x, y = ci * cell, bi * row
            if renders[ci] is None:
                parts.append(label("not rendered: no ictool", x + 90, y + 84, bi))
            else:
                parts.append(f'<image x="{x+10}" y="{y+4}" width="160" height="160" href="{renders[ci][0]}"/>')
                parts.append(f'<image x="{x+74}" y="{y+167}" width="32" height="32" href="{renders[ci][1]}"/>')
            parts.append(label(name, x + 90, y + 212, bi))
            parts.append(label(style, x + 90, y + 225, bi))
    return "".join(parts) + "</svg>\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("design", type=Path, nargs="?")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--out", type=Path, help="write a new, dedicated output directory")
    mode.add_argument("--check", type=Path, help="regenerate privately and compare without modifying this directory")
    mode.add_argument("--lint", action="store_true", help="report measurable layer and contrast problems")
    mode.add_argument("--sheet", type=Path, help="write a new comparison SVG of the named entries in every style")
    mode.add_argument("--continuous-rect", nargs="+", type=float, metavar="N",
                      help="print path data for X Y WIDTH HEIGHT and one radius or four "
                           "(top-left, top-right, bottom-right, bottom-left); takes no DESIGN.md")
    parser.add_argument("--name", action="append", default=[])
    parser.add_argument("--style", choices=STYLES)
    parser.add_argument("--document-only", action="store_true")
    parser.add_argument("--ictool", help="path to Icon Composer's export-capable ictool")
    args = parser.parse_args()
    if (args.design is None) == (args.continuous_rect is None):
        parser.error("DESIGN.md is required, except with --continuous-rect, which takes none")
    try:
        if args.continuous_rect is not None:
            if len(args.continuous_rect) not in (5, 8):
                fail("--continuous-rect takes X Y WIDTH HEIGHT and one or four radii")
            x, y, width, height, *radii = args.continuous_rect
            radii = radii[0] if len(radii) == 1 else radii
            print(continuous_rect(x, y, width, height, radii))
            limit = min(width, height) / 2
            for radius in sorted({r for r in args.continuous_rect[4:] if r > limit}):
                print(f"info\tradius {radius:g} exceeds half the shorter side; using {limit:g}", file=sys.stderr)
            for edge, excess in zip(EDGES, continuous_corners(width, height, radii)[1]):
                if excess > OVERRUN:
                    print(f"info\t{edge} edge: corner departures exceed it by {excess:.2f}; "
                          "the corners end early and a tangent cubic joins them", file=sys.stderr)
            return 0
        entries = read_entries(args.design)
        if args.list:
            print("\n".join(entries))
            return 0
        unknown = [name for name in args.name if name not in entries]
        if not args.name or unknown:
            fail("--name must identify app_icons entries")
        if not args.sheet and len(args.name) != 1:
            fail("--name identifies exactly one entry outside --sheet")
        base = args.design.resolve().parent
        name = args.name[0]
        style = None if args.lint or args.sheet else select_style(entries[name], args.style)
        tool = find_ictool(args.ictool) if style == "liquid-glass" and not args.document_only else None
        if not args.document_only and not shutil.which("rsvg-convert"):
            fail("rsvg-convert is required for rendering, lint and contact sheets")
        if args.lint:
            styles = [args.style] if args.style else list(entry_styles(entries[name]))
            findings = []
            with tempfile.TemporaryDirectory(prefix=".app-icon-lint-") as temp:
                for style in styles:
                    if args.style:
                        select_style(entries[name], style)
                    information = []
                    findings += [f"{style}\t{text}" for text in lint(entries[name], base, style, Path(temp), information)]
                    for text in information:
                        print(f"info\t{style}\t{text}")
            print("\n".join(findings) if findings else "clean")
            return 1 if findings else 0
        if args.sheet:
            target = args.sheet.resolve()
            if target.exists():
                fail("sheet file exists; choose a new path")
            try:
                tool = find_ictool(args.ictool)
            except ValueError:
                if args.ictool:
                    raise
                tool = None
            with tempfile.TemporaryDirectory(prefix=".app-icon-sheet-") as temp:
                content = sheet(entries, args.name, base, tool, Path(temp))
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
            print(target)
            return 0
        target = (args.out or args.check).resolve()
        if args.out and target.exists():
            fail("output directory exists; use a fresh directory or --check to inspect drift")
        if args.check and not target.is_dir():
            fail("check target is not a directory")
        if args.out:
            target.parent.mkdir(parents=True, exist_ok=True)
        # Publishing needs a same-filesystem rename; checking must not write near the target.
        with tempfile.TemporaryDirectory(prefix=".app-icon-", dir=target.parent if args.out else None) as temp:
            candidate = Path(temp) / "output"
            build(name, entries[name], base, candidate, style, tool, args.document_only)
            if args.check:
                return 1 if compare(candidate, target) else 0
            candidate.rename(target)
        print(target)
        return 0
    except (ValueError, OSError, ET.ParseError, zlib.error, struct.error) as exc:
        parser.exit(1, f"error: {exc}\n")


if __name__ == "__main__":
    raise SystemExit(main())
