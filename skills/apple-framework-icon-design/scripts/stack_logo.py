#!/usr/bin/env python3
"""Framework-style icon generator.

Three styles share one palette, glyph library and continuous corner:

stacked:    a rounded square slab seen from above at an isometric angle,
            built from contiguous color bands, with a gradient top face, a
            faint texture and a glyph lying on the face (or standing on it
            as 3D objects).
volumetric: a front-facing tile with an extruded glyph, glass panels and an
            optional grid backdrop.
flat:       a front-facing gradient tile with a flat glyph.

Everything is emitted as SVG paths, so no fonts are involved.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import sys
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Color


def _oklab_to_linear_srgb(L: float, a: float, b: float) -> tuple[float, float, float]:
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def _gamma(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def oklch(L: float, C: float, h: float) -> str:
    """Hex color for OKLCH, reducing chroma until it fits in sRGB."""
    for _ in range(60):
        a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
        rgb = _oklab_to_linear_srgb(L, a, b)
        if all(-1e-4 <= c <= 1 + 1e-4 for c in rgb):
            break
        C *= 0.94
    return "#" + "".join(f"{round(max(0, min(1, _gamma(max(0, c)))) * 255):02x}" for c in rgb)


_oklch = oklch


@dataclass
class Palette:
    face_back: str
    face_front: str
    bands: list[str]  # top band first
    glyph: str = "#ffffff"
    glyph_shadow: str = "#000000"
    texture: str = "#ffffff"


def _hue_rules(hue: float, drift: int | None) -> tuple[float, int]:
    """Lightness lift for yellow-greens, and the hue drift direction."""
    lift = 0.05 * max(0.0, 1 - abs(((hue - 105 + 180) % 360) - 180) / 45)
    # Drift toward violet/magenta; warm hues drifting toward yellow turn brown.
    if drift is None:
        drift = -1 if (hue % 360) < 120 or (hue % 360) >= 330 else 1
    return lift, drift


def tile_ramp(hue: float, mode: str, vivid: float = 1.0, tone: float = 0.0,
              drift: int | None = None) -> tuple[str, str]:
    """Top and bottom of a front-facing tile, fitted on Apple framework tiles.

    deepen: a light top deepening and gaining chroma downward (SwiftUI, Metal).
    glow:   a deep top brightening toward a luminous bottom.
    """
    lift, drift = _hue_rules(hue, drift)
    light = _oklch(0.73 + lift + tone, 0.15 * vivid, hue - 8 * drift)
    deep = _oklch(0.56 + lift + tone, 0.19 * vivid, hue + 14 * drift)
    if mode == "glow":
        return deep, _oklch(0.80 + lift + tone, 0.13 * vivid, hue - 8 * drift)
    return light, deep


def palette_for(hue: float, mode: str, bands: int, vivid: float = 1.0, tone: float = 0.0,
                drift: int | None = None) -> Palette:
    """Derive a palette from one hue.

    The sides read as one continuous ramp: the first band continues the face
    front, then every band steps the same way in lightness while the hue
    drifts in one direction (measured on Apple's CloudKit and Core ML icons).

    deepen: bands darken and gain chroma (CloudKit).
    glow:   face darkens from back to front, bands brighten toward a luminous
            bottom edge (Core ML).
    vivid:  chroma multiplier; purples and pinks have far more sRGB headroom
            than blues and look pastel at the same chroma.
    tone:   lightness offset for the whole ramp, so continuity is kept.
    drift:  hue direction override (+1 / -1).
    """
    def oklch(L, C, h):  # noqa: E306
        return _oklch(L + tone, C * vivid, h)

    lift, drift = _hue_rules(hue, drift)
    n = max(1, bands - 1)
    if mode == "glow":
        face_back = oklch(0.82 + lift, 0.12, hue - 20 * drift)
        face_front = oklch(0.60 + lift, 0.12, hue + 20 * drift)
        ramp = [
            oklch(0.66 + lift + 0.20 * (i / n) ** 1.2, 0.10 + 0.03 * i / n, hue + (12 - 30 * i / n) * drift)
            for i in range(bands)
        ]
        return Palette(face_back, face_front, ramp, glyph_shadow=oklch(0.38, 0.10, hue + 18 * drift))
    face_back = oklch(0.84 + lift, 0.12, hue - 6 * drift)
    face_front = oklch(0.76 + lift, 0.15, hue + 4 * drift)
    ramp = [
        oklch(0.77 + lift - 0.21 * (i / n) ** 1.2, 0.12 + 0.07 * i / n, hue + (2 + 30 * i / n) * drift)
        for i in range(bands)
    ]
    return Palette(face_back, face_front, ramp, glyph_shadow=oklch(0.40, 0.12, hue + 10 * drift))


# ---------------------------------------------------------------------------
# Geometry (Apple framework icon proportions, fitted against reference art)

K = 0.75          # vertical squash of the top face
DEPTH = 0.36      # stack depth as a fraction of icon width
WIDTH = 0.88      # icon width as a fraction of the canvas
VERT = math.sqrt(1 - K * K)  # screen length of a vertical unit, relative to a horizontal one

# Continuous corner: two mirrored cubics per corner, leaving each straight
# edge with zero curvature. Values are fractions of the side, measured from
# the corner: where the curve leaves the edge, the two control points on the
# edge, and the diagonal point. At scale 1 this is the app icon mask.
CORNER = (0.396305, 0.230261, 0.152117, 0.076058)
TILE_CORNER = 1.0   # front-facing tiles
SLAB_CORNER = 0.70  # top face of the stacked slab
TILE_SIZE = 0.906   # front-facing tile side as a fraction of the canvas


def to_screen(x: float, y: float, cx: float, cy: float, scale: float) -> tuple[float, float]:
    return cx + (x - y) / math.sqrt(2) * scale, cy + (x + y) / math.sqrt(2) * K * scale


def _cubic(p0, p1, p2, p3, steps: int) -> list[tuple[float, float]]:
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append(tuple(u**3 * a + 3 * u * u * t * b + 3 * u * t * t * c + t**3 * d
                         for a, b, c, d in zip(p0, p1, p2, p3)))
    return pts


def _corners(x: float, y: float, w: float, h: float, scale: float):
    """Yield, clockwise from the top right, a point function for each corner.

    Corners are sized from the shorter side, so a rectangle keeps the corner
    of the square that fits it.
    """
    l, c1, c2, d = (v * scale * min(w, h) for v in CORNER)
    for (cx, cy), e1, e2 in (((x + w, y), (-1, 0), (0, 1)), ((x + w, y + h), (0, -1), (-1, 0)),
                             ((x, y + h), (1, 0), (0, -1)), ((x, y), (0, 1), (1, 0))):
        def at(u: float, v: float, cx=cx, cy=cy, e1=e1, e2=e2) -> tuple[float, float]:
            return cx + u * e1[0] + v * e2[0], cy + u * e1[1] + v * e2[1]
        yield at, (l, c1, c2, d)


def continuous_square(scale: float, steps: int = 12) -> list[tuple[float, float]]:
    """Outline of a unit square centred on the origin, clockwise with y down."""
    pts = []
    for at, (l, c1, c2, d) in _corners(-0.5, -0.5, 1.0, 1.0, scale):
        pts += _cubic(at(l, 0), at(c1, 0), at(c2, 0), at(d, d), steps)
        pts += _cubic(at(d, d), at(0, c2), at(0, c1), at(0, l), steps)[1:]
    return pts


def tile_path(x: float, y: float, w: float, h: float | None = None, scale: float = TILE_CORNER) -> str:
    """SVG path of a front-facing tile or panel with continuous corners."""
    parts = []
    for at, (l, c1, c2, d) in _corners(x, y, w, w if h is None else h, scale):
        def p(u: float, v: float) -> str:
            px, py = at(u, v)
            return f"{px:.2f} {py:.2f}"
        parts.append(("M" if not parts else "L") + p(l, 0))
        parts.append(f"C{p(c1, 0)} {p(c2, 0)} {p(d, d)}C{p(0, c2)} {p(0, c1)} {p(0, l)}")
    return "".join(parts) + "Z"


def path_d(pts, close: bool = True) -> str:
    d = "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in pts)
    return d + (" Z" if close else "")


def front_half(pts):
    left = min(range(len(pts)), key=lambda i: (pts[i][0], -pts[i][1]))
    right = max(range(len(pts)), key=lambda i: (pts[i][0], pts[i][1]))
    n = len(pts)
    a = [pts[(left + i) % n] for i in range(((right - left) % n) + 1)]
    b = [pts[(left - i) % n] for i in range(((left - right) % n) + 1)]
    return a if sum(p[1] for p in a) / len(a) > sum(p[1] for p in b) / len(b) else b


def band(pts, thickness: float):
    edge = front_half(pts)
    return edge + [(x, y + thickness) for x, y in reversed(edge)]


# ---------------------------------------------------------------------------
# Glyphs, unit box [-1, 1], y down

GLYPHS: dict[str, dict] = {
    "prompt": {"style": "stroke", "d": "M-0.78 -0.55 L-0.16 0 L-0.78 0.55 M0.08 0.60 L0.82 0.60", "width": 0.24},
    "shebang": {
        "style": "stroke",
        "d": "M-0.50 -0.72 L-0.66 0.72 M-0.06 -0.72 L-0.22 0.72 M-0.92 -0.26 L0.12 -0.26 M-0.98 0.26 L0.06 0.26 M0.66 -0.76 L0.66 0.28",
        "dots": [(0.66, 0.70, 0.14)],
        "width": 0.19,
    },
    "braces": {
        "style": "stroke",
        "d": (
            "M-0.42 -0.86 C-0.74 -0.86 -0.68 -0.52 -0.68 -0.30 C-0.68 -0.10 -0.80 0 -0.96 0 "
            "C-0.80 0 -0.68 0.10 -0.68 0.30 C-0.68 0.52 -0.74 0.86 -0.42 0.86 "
            "M0.42 -0.86 C0.74 -0.86 0.68 -0.52 0.68 -0.30 C0.68 -0.10 0.80 0 0.96 0 "
            "C0.80 0 0.68 0.10 0.68 0.30 C0.68 0.52 0.74 0.86 0.42 0.86 "
            "M0.24 -0.34 L-0.24 0.34"
        ),
        "dots": [(-0.22, -0.28, 0.11), (0.22, 0.28, 0.11)],
        "width": 0.17,
    },
    "toggle": {
        "style": "stroke",
        "d": "M-0.42 -0.44 H0.42 A0.44 0.44 0 0 1 0.42 0.44 H-0.42 A0.44 0.44 0 0 1 -0.42 -0.44 Z",
        "dots": [(0.42, 0, 0.28)],
        "width": 0.16,
    },
    "cycle": {
        "style": "stroke",
        "d": (
            "M-0.74 -0.10 A0.76 0.76 0 0 1 0.52 -0.56 "
            "M0.74 0.10 A0.76 0.76 0 0 1 -0.52 0.56 "
            "M0.24 -0.66 L0.56 -0.54 L0.60 -0.88 "
            "M-0.24 0.66 L-0.56 0.54 L-0.60 0.88"
        ),
        "width": 0.18,
    },
    "box": {
        "style": "stroke",
        "d": "M-0.76 -0.56 H0.76 V0.72 H-0.76 Z M-0.76 -0.14 H0.76 M-0.20 -0.56 V0.06 L0 -0.08 L0.20 0.06 V-0.56",
        "width": 0.16,
    },
    "spark": {
        "style": "fill",
        "d": (
            "M-0.15 -0.92 C-0.07 -0.38 0.06 -0.25 0.58 -0.15 C0.06 -0.05 -0.07 0.08 -0.15 0.62 "
            "C-0.23 0.08 -0.36 -0.05 -0.88 -0.15 C-0.36 -0.25 -0.23 -0.38 -0.15 -0.92 Z "
            "M0.60 0.24 C0.63 0.48 0.68 0.53 0.92 0.57 C0.68 0.61 0.63 0.66 0.60 0.90 "
            "C0.57 0.66 0.52 0.61 0.28 0.57 C0.52 0.53 0.57 0.48 0.60 0.24 Z"
        ),
    },
    "cylinder": {
        "style": "stroke",
        "d": (
            "M-0.62 -0.16 A0.62 0.22 0 0 0 0.62 -0.16 A0.62 0.22 0 0 0 -0.62 -0.16 "
            "M-0.62 -0.16 V0.62 A0.62 0.22 0 0 0 0.62 0.62 V-0.16 "
            "M-0.62 0.24 A0.62 0.22 0 0 0 0.62 0.24 "
            "M0 -1.0 V-0.44 M-0.22 -0.64 L0 -0.42 L0.22 -0.64"
        ),
        "width": 0.15,
    },
    "tag": {
        "style": "stroke",
        "d": "M-0.94 0 L-0.40 -0.58 H0.72 A0.14 0.14 0 0 1 0.86 -0.44 V0.44 A0.14 0.14 0 0 1 0.72 0.58 H-0.40 Z",
        "dots": [(-0.36, 0, 0.14)],
        "width": 0.16,
    },
    "mug": {
        "style": "stroke",
        "d": (
            "M-0.64 -0.30 H0.36 V0.62 A0.18 0.18 0 0 1 0.18 0.80 H-0.46 A0.18 0.18 0 0 1 -0.64 0.62 Z "
            "M0.36 -0.10 H0.60 A0.18 0.18 0 0 1 0.78 0.08 V0.30 A0.18 0.18 0 0 1 0.60 0.48 H0.36 "
            "M-0.32 0.02 V0.48 M0.04 0.02 V0.48"
        ),
        "dots": [(-0.44, -0.48, 0.21), (-0.12, -0.58, 0.25), (0.20, -0.46, 0.20)],
        "width": 0.15,
    },
    "tiles": {
        "style": "fill",
        "rects": [(-0.82, -0.82, 0.74, 0.74), (0.08, -0.82, 0.74, 0.74), (-0.82, 0.08, 0.74, 0.74), (0.08, 0.08, 0.74, 0.74)],
        "round": 0.18,
    },
}


def _xf(d: str, s: float, tx: float, ty: float) -> str:
    """Scale and move an M/L-only path."""
    out, nums = [], d.replace("M", " M ").replace("L", " L ").split()
    i = 0
    while i < len(nums):
        tok = nums[i]
        if tok in ("M", "L"):
            out.append(f"{tok}{float(nums[i + 1]) * s + tx:.3f} {float(nums[i + 2]) * s + ty:.3f}")
            i += 3
        else:
            i += 1
    return " ".join(out)


def _arc_union(circles: list[tuple[float, float, float]], base: float) -> str:
    """Outline of left-to-right overlapping circles sitting on a flat base line."""
    def meet(c1, c2):
        (x1, y1, r1), (x2, y2, r2) = c1, c2
        dx, dy = x2 - x1, y2 - y1
        d = math.hypot(dx, dy)
        a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
        h = math.sqrt(max(0.0, r1 * r1 - a * a))
        mx, my = x1 + a * dx / d, y1 + a * dy / d
        pts = [(mx + h * dy / d, my - h * dx / d), (mx - h * dy / d, my + h * dx / d)]
        return min(pts, key=lambda p: p[1])

    def base_hit(c, side):
        x, y, r = c
        return (x + side * math.sqrt(max(0.0, r * r - (base - y) ** 2)), base)

    pts = [base_hit(circles[0], -1)] + [meet(a, b) for a, b in zip(circles, circles[1:])] + [base_hit(circles[-1], 1)]
    d = f"M{pts[0][0]:.3f} {pts[0][1]:.3f}"
    for c, p0, p1 in zip(circles, pts, pts[1:]):
        a0 = math.atan2(p0[1] - c[1], p0[0] - c[0])
        a1 = math.atan2(p1[1] - c[1], p1[0] - c[0])
        sweep = (a1 - a0) % (2 * math.pi)
        d += f" A{c[2]} {c[2]} 0 {1 if sweep > math.pi else 0} 1 {p1[0]:.3f} {p1[1]:.3f}"
    return d + " Z"


def _loop(n: int, radius: float, node: float, gap: float, head: float) -> tuple[str, list]:
    """n nodes on a circle joined clockwise by arrowed arcs."""
    d, dots = [], []
    for i in range(n):
        a = math.radians(-90 + 360 * i / n)
        if node:
            dots.append((radius * math.cos(a), radius * math.sin(a), node))
        a0, a1 = a + gap, a + math.radians(360 / n) - gap
        p0 = (radius * math.cos(a0), radius * math.sin(a0))
        p1 = (radius * math.cos(a1), radius * math.sin(a1))
        large = 1 if a1 - a0 > math.pi else 0
        d.append(f"M{p0[0]:.3f} {p0[1]:.3f} A{radius} {radius} 0 {large} 1 {p1[0]:.3f} {p1[1]:.3f}")
        tx, ty = -math.sin(a1), math.cos(a1)  # clockwise tangent
        for side in (1, -1):
            hx = p1[0] - head * (tx * 0.8 - side * ty * 0.6)
            hy = p1[1] - head * (ty * 0.8 + side * tx * 0.6)
            d.append(f"M{hx:.3f} {hy:.3f} L{p1[0]:.3f} {p1[1]:.3f}")
    return " ".join(d), dots


_CLOUD = _arc_union([(-0.52, 0.22, 0.34), (-0.04, -0.06, 0.50), (0.52, 0.18, 0.38)], 0.56)
_LOOP_D, _LOOP_DOTS = _loop(3, 0.62, 0.17, 0.42, 0.20)
_RING_D, _ = _loop(1, 0.70, 0, 0.50, 0.26)

GLYPHS.update({
    "cloud_prompt": {
        "style": "stroke",
        "d": _CLOUD + " " + _xf("M-0.78 -0.55 L-0.16 0 L-0.78 0.55 M0.08 0.60 L0.82 0.60", 0.36, 0.0, 0.16),
        "width": 0.13,
    },
    "loop3": {"style": "stroke", "d": _LOOP_D, "dots": _LOOP_DOTS, "width": 0.15},
    "ring": {"style": "stroke", "d": _RING_D, "width": 0.17},
    "brackets": {
        "style": "stroke",
        "d": "M-0.86 -0.36 V-0.86 H-0.36 M0.36 -0.86 H0.86 V-0.36 M0.86 0.36 V0.86 H0.36 M-0.36 0.86 H-0.86 V0.36",
        "width": 0.10,
    },
    "dashed_plus": {
        "style": "stroke",
        "d": "M-0.62 -0.80 H0.62 A0.18 0.18 0 0 1 0.80 -0.62 V0.62 A0.18 0.18 0 0 1 0.62 0.80 H-0.62 A0.18 0.18 0 0 1 -0.80 0.62 V-0.62 A0.18 0.18 0 0 1 -0.62 -0.80 Z",
        "dash": "0.26 0.18",
        "extra": "M-0.26 -0.26 L0.26 0.26 M0.26 -0.26 L-0.26 0.26",  # reads as + once laid flat at 45 degrees
        "width": 0.14,
    },
    "copy": {
        "style": "stroke",
        "d": (
            "M-0.30 -0.80 H0.62 A0.18 0.18 0 0 1 0.80 -0.62 V0.30 "
            "M-0.62 -0.46 H0.28 A0.18 0.18 0 0 1 0.46 -0.28 V0.62 A0.18 0.18 0 0 1 0.28 0.80 "
            "H-0.62 A0.18 0.18 0 0 1 -0.80 0.62 V-0.28 A0.18 0.18 0 0 1 -0.62 -0.46 Z"
        ),
        "width": 0.15,
    },
    "one_zero": {
        "style": "stroke",
        "d": (
            "M-0.86 -0.36 L-0.62 -0.58 V0.58 "
            "M0.18 -0.30 A0.30 0.30 0 0 1 0.78 -0.30 V0.30 A0.30 0.30 0 0 1 0.18 0.30 Z"
        ),
        "dots": [(-0.22, 0.50, 0.11)],
        "width": 0.17,
    },
    "toggle_on": {
        "style": "fill",
        "d": "M-0.42 -0.46 H0.42 A0.46 0.46 0 0 1 0.42 0.46 H-0.42 A0.46 0.46 0 0 1 -0.42 -0.46 Z",
        "knock": [(0.42, 0, 0.34)],
    },
    "chevrons": {"style": "stroke", "d": "M-0.74 -0.58 L-0.14 0 L-0.74 0.58 M0.08 -0.58 L0.68 0 L0.08 0.58", "width": 0.22},
    "arrow": {"style": "stroke", "d": "M-0.86 0 H-0.18 M0.06 -0.52 L0.70 0 L0.06 0.52", "width": 0.22},
    "letter_s": {
        "style": "stroke",
        "d": "M0.56 -0.58 C0.36 -0.84 -0.60 -0.86 -0.58 -0.36 C-0.56 0.02 0.58 -0.04 0.58 0.36 C0.60 0.86 -0.38 0.84 -0.60 0.58",
        "width": 0.24,
    },
    "fast_forward": {
        "style": "fill",
        "d": "M-0.86 -0.58 L-0.04 0 L-0.86 0.58 Z M0.02 -0.58 L0.84 0 L0.02 0.58 Z",
    },
})


def _rrect(x: float, y: float, w: float, h: float, r: float) -> str:
    r = min(r, w / 2, h / 2)
    return (
        f"M{x + r:.3f} {y:.3f} H{x + w - r:.3f} A{r} {r} 0 0 1 {x + w:.3f} {y + r:.3f} "
        f"V{y + h - r:.3f} A{r} {r} 0 0 1 {x + w - r:.3f} {y + h:.3f} H{x + r:.3f} "
        f"A{r} {r} 0 0 1 {x:.3f} {y + h - r:.3f} V{y + r:.3f} A{r} {r} 0 0 1 {x + r:.3f} {y:.3f} Z"
    )


def glyph_markup(g: dict, color: str, opacity: float, fills: list[str] | None = None, accent: str | None = None) -> str:
    parts = []
    stroke = f'fill="none" stroke="{color}" stroke-width="{g.get("width", 0.16)}" stroke-linecap="round" stroke-linejoin="round"'
    if g.get("d"):
        if g["style"] == "stroke":
            dash = f' stroke-dasharray="{g["dash"]}"' if g.get("dash") else ""
            parts.append(f'<path d="{g["d"]}" {stroke}{dash}/>')
        else:
            parts.append(f'<path d="{g["d"]}" fill="{color}"/>')
    if g.get("extra"):
        parts.append(f'<path d="{g["extra"]}" {stroke}/>')
    for i, (x, y, w, h) in enumerate(g.get("rects", [])):
        fill = fills[i % len(fills)] if fills else color
        parts.append(f'<path d="{_rrect(x, y, w, h, g.get("round", 0.1))}" fill="{fill}"/>')
    for x, y, r in g.get("dots", []):
        parts.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>')
    for x, y, r in g.get("knock", []):
        parts.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{accent or color}"/>')
    inner = "".join(parts)
    if g.get("transform"):
        inner = f'<g transform="{g["transform"]}">{inner}</g>'
    return f'<g opacity="{opacity}">{inner}</g>'


# ---------------------------------------------------------------------------
# Textures in face-local coordinates (square side = 1, centered)


def texture_markup(kind: str, color: str, seed: int = 7) -> str:
    if kind == "dots":
        cells = [f'<circle cx="{x / 12:.3f}" cy="{y / 12:.3f}" r="0.010"/>' for x in range(-6, 7) for y in range(-6, 7)]
        return f'<g fill="{color}">' + "".join(cells) + "</g>"
    if kind == "grid":
        lines = [f"M{i / 10:.2f} -0.6 V0.6 M-0.6 {i / 10:.2f} H0.6" for i in range(-5, 6)]
        return f'<path d="{" ".join(lines)}" stroke="{color}" stroke-width="0.005" fill="none"/>'
    if kind == "lines":
        lines = [f"M{i / 14:.3f} -0.8 L{i / 14 - 0.8:.3f} 0" for i in range(-14, 26)]
        return f'<path d="{" ".join(lines)}" stroke="{color}" stroke-width="0.006" fill="none" transform="translate(0.4 0.4)"/>'
    if kind == "rings":
        return "".join(f'<circle r="{r / 11:.3f}" fill="none" stroke="{color}" stroke-width="0.005"/>' for r in range(1, 9))
    if kind == "constellation":
        rnd = random.Random(seed)
        pts = [(rnd.uniform(-0.48, 0.48), rnd.uniform(-0.48, 0.48)) for _ in range(46)]
        segs = set()
        for i, p in enumerate(pts):
            near = sorted(range(len(pts)), key=lambda j: (pts[j][0] - p[0]) ** 2 + (pts[j][1] - p[1]) ** 2)[1:3]
            for j in near:
                segs.add(tuple(sorted((i, j))))
        d = " ".join(f"M{pts[i][0]:.3f} {pts[i][1]:.3f} L{pts[j][0]:.3f} {pts[j][1]:.3f}" for i, j in segs)
        dots = "".join(f'<circle cx="{x:.3f}" cy="{y:.3f}" r="{rnd.uniform(0.004, 0.009):.4f}"/>' for x, y in pts)
        return f'<path d="{d}" stroke="{color}" stroke-width="0.0035" fill="none"/><g fill="{color}">{dots}</g>'
    return ""


# ---------------------------------------------------------------------------
# Icon


STYLES = ("stacked", "volumetric", "flat")
# Per-style defaults for fields left unset. Rotation is relative to the
# glyph's own axes: -45 is upright; on the slab, -90 reads along the
# up-right edge like text on the face.
STYLE_DEFAULTS = {
    "stacked": {"glyph_rotation": -90, "glyph_relief": 0.018, "texture_opacity": 0.30},
    "volumetric": {"glyph_rotation": -45, "glyph_relief": 0.045, "texture_opacity": 0.18},
    "flat": {"glyph_rotation": -45, "glyph_relief": 0, "texture_opacity": 0.18},
}


@dataclass
class Spec:
    hue: float = 250
    style: str = "stacked"       # stacked | volumetric | flat
    mode: str = "deepen"         # deepen | glow
    bands: int = 3
    glyph: str = "none"
    glyph_rotation: float | None = None  # degrees; default per style
    glyph_scale: float = 0.31
    texture: str = "none"
    blocks: list[list[float]] = field(default_factory=list)  # 3D blocks: [x, y, height, half-size?]
    band_hues: list[float] = field(default_factory=list)  # optional explicit per-band hues
    face: str = ""               # "graphite" for a dark neutral face, "light" for a white one
    neutral_bands: bool | str = False  # graphite bands; "glow" brightens downward
    glyph_hue: float | None = None  # colored glyph instead of white
    glyph_fills: list[float] = field(default_factory=list)  # hues for multi-color glyph parts
    custom_glyph: dict | None = None
    glyph_offset: list[float] = field(default_factory=list)  # [x, y] on the face, side = 1
    glyph_relief: float | None = None  # raised or extruded thickness as a fraction of the icon size; 0 lays it flat
    glyph_color: str = ""
    glyph_gradient: list[str] = field(default_factory=list)  # two colors across the glyph
    texture_opacity: float | None = None  # default per style
    face_colors: list[str] = field(default_factory=list)  # [back, front]; on a tile, [top, bottom]
    band_colors: list[str] = field(default_factory=list)  # top band first
    objects: list[dict] = field(default_factory=list)  # slab: standing 3D objects (draw_object); tile: panels (draw_panel)
    vivid: float = 1.0
    tone: float = 0.0
    drift: int | None = None
    glyph_side: str | list = ""   # side color of a raised glyph
    texture_color: str | list = ""
    fill_lightness: float = 0.80  # lightness of multi-color glyph parts


def _object_colors(color, hue: float) -> tuple[str, str, str]:
    """(top, left, right) faces; light comes from the upper left."""
    if color is None or color == "white":
        return "#ffffff", oklch(0.95, 0.008, hue), oklch(0.80, 0.016, hue)
    if isinstance(color, dict):
        h = color["tint"]
        return "#ffffff", oklch(0.92, 0.035, h), oklch(0.74, 0.08, h)
    if isinstance(color, (int, float)):
        return oklch(0.90, 0.11, color), oklch(0.80, 0.15, color), oklch(0.62, 0.15, color)
    return tuple(color)


def draw_object(o: dict, project, scale: float, hue: float, uid: str, defs: list) -> str:
    """One standing object. Positions and sizes are in face units (side = 1).

    kind: cube | glass | cylinder | sphere | cone
    x, y: base center; s: half-size (cube, glass) or radius; h: height
    color: "white", a hue, {"tint": hue} or [top, left, right]
    rings: cylinder ring heights as fractions; inner: hue of a cube inside a glass cube
    """
    kind, x, y = o["kind"], o.get("x", 0.0), o.get("y", 0.0)
    s, h = o.get("s", 0.1), o.get("h", 0.2)
    top, left, right = _object_colors(o.get("color"), hue)
    hp = h * scale * VERT
    out = []
    if kind in ("cube", "glass"):
        a, b, c, d = (project(x - s, y - s), project(x + s, y - s), project(x + s, y + s), project(x - s, y + s))
        up = lambda q, k=1.0: (q[0], q[1] - hp * k)  # noqa: E731
        lf, rf, tf = [d, c, up(c), up(d)], [c, b, up(b), up(c)], [up(a), up(b), up(c), up(d)]
        if kind == "cube":
            out += [f'<path d="{path_d(lf)}" fill="{left}"/>', f'<path d="{path_d(rf)}" fill="{right}"/>',
                    f'<path d="{path_d(tf)}" fill="{top}"/>']
        else:
            sw = scale * 0.008
            if o.get("inner") is not None:
                out.append(draw_object({"kind": "cube", "x": x, "y": y, "s": s * 0.45, "h": h * 0.45,
                                        "color": o["inner"]}, lambda px, py: (project(px, py)[0], project(px, py)[1] - hp * 0.275),
                                       scale, hue, uid, defs))
            hidden = f"M{path_d([a, b], False)[1:]} M{path_d([a, d], False)[1:]} M{path_d([a, up(a)], False)[1:]}"
            out.append(f'<path d="{hidden}" stroke="#ffffff" stroke-opacity="0.45" stroke-width="{sw:.2f}" fill="none"/>')
            for pts, op in ((lf, 0.22), (rf, 0.10), (tf, 0.34)):
                out.append(f'<path d="{path_d(pts)}" fill="#ffffff" fill-opacity="{op}" stroke="#ffffff" '
                           f'stroke-opacity="0.95" stroke-width="{sw:.2f}" stroke-linejoin="round"/>')
        return "".join(out)
    px, py = project(x, y)
    rx, ry = s * scale, s * scale * K
    gid = f"{uid}-o{len(defs)}"
    defs.append(
        f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{px - rx:.1f}" y1="0" x2="{px + rx:.1f}" y2="0">'
        f'<stop offset="0" stop-color="{left}"/><stop offset="0.35" stop-color="{top}"/><stop offset="1" stop-color="{right}"/></linearGradient>'
    )
    if kind == "cylinder":
        out.append(f'<path d="M{px - rx:.2f} {py:.2f} A{rx:.2f} {ry:.2f} 0 0 0 {px + rx:.2f} {py:.2f} '
                   f'L{px + rx:.2f} {py - hp:.2f} L{px - rx:.2f} {py - hp:.2f} Z" fill="url(#{gid})"/>')
        for f in o.get("rings", []):
            yy = py - hp * f
            out.append(f'<path d="M{px - rx:.2f} {yy:.2f} A{rx:.2f} {ry:.2f} 0 0 0 {px + rx:.2f} {yy:.2f}" fill="none" '
                       f'stroke="{right}" stroke-width="{scale * 0.012:.2f}"/>')
        out.append(f'<ellipse cx="{px:.2f}" cy="{py - hp:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="{top}"/>')
    elif kind == "cone":
        ty = -ry * ry / hp
        tx = rx * math.sqrt(max(0.0, 1 - (ty / ry) ** 2))
        out.append(f'<path d="M{px:.2f} {py - hp:.2f} L{px + tx:.2f} {py + ty:.2f} A{rx:.2f} {ry:.2f} 0 1 1 {px - tx:.2f} {py + ty:.2f} Z" '
                   f'fill="url(#{gid})"/>')
    elif kind == "sphere":
        r = s * scale
        sy = py - s * scale * VERT
        defs.append(
            f'<radialGradient id="{gid}s" gradientUnits="userSpaceOnUse" cx="{px:.1f}" cy="{sy:.1f}" r="{r:.1f}" '
            f'fx="{px - r * 0.35:.1f}" fy="{sy - r * 0.40:.1f}">'
            f'<stop offset="0" stop-color="{top}"/><stop offset="0.55" stop-color="{left}"/><stop offset="1" stop-color="{right}"/></radialGradient>'
        )
        out.append(f'<circle cx="{px:.2f}" cy="{sy:.2f}" r="{r:.2f}" fill="url(#{gid}s)"/>')
    return "".join(out)


def _object_height(o: dict, scale: float) -> float:
    if o["kind"] == "sphere":
        return o.get("s", 0.1) * scale * (1 + VERT)
    return o.get("h", 0.2) * scale * VERT


def _object_top(o: dict, scale: float) -> float:
    """Highest screen point of an object relative to the face center, in pixels (negative is up)."""
    x, y, s = o.get("x", 0.0), o.get("y", 0.0), o.get("s", 0.1)
    reach = s * math.sqrt(2) if o["kind"] in ("cube", "glass") else s
    return ((x + y) / math.sqrt(2) - reach) * K * scale - _object_height(o, scale)


def _setting(spec: Spec, name: str):
    value = getattr(spec, name)
    return STYLE_DEFAULTS[spec.style][name] if value is None else value


def _resolve(c):
    return oklch(*c) if isinstance(c, (list, tuple)) else c


def _palette(spec: Spec) -> Palette:
    pal = palette_for(spec.hue, spec.mode, spec.bands, spec.vivid, spec.tone, spec.drift)
    if spec.band_hues:
        pal.bands = [oklch(0.78 - 0.04 * i, 0.15, h) for i, h in enumerate(spec.band_hues)]
    if spec.neutral_bands == "glow":  # ARKit: graphite that brightens downward from the face
        pal.bands = [oklch(0.39 + 0.19 * (i / max(1, spec.bands - 1)) ** 1.2, 0.006, 260) for i in range(spec.bands)]
    elif spec.neutral_bands:
        pal.bands = [oklch(0.50 - 0.20 * i / max(1, spec.bands - 1), 0.008, 260) for i in range(spec.bands)]
    if spec.band_colors:
        pal.bands = [_resolve(c) for c in spec.band_colors]
    if spec.face == "graphite":
        pal.face_back, pal.face_front = oklch(0.42, 0.012, 260), oklch(0.27, 0.012, 260)
        pal.glyph_shadow = "#000000"
    elif spec.face == "light":
        pal.face_back, pal.face_front = "#ffffff", oklch(0.93, 0.006, 260)
        pal.glyph = oklch(0.62, 0.16, spec.hue)
        pal.glyph_shadow = oklch(0.45, 0.06, spec.hue)
        pal.texture = oklch(0.70, 0.03, spec.hue)
    if spec.face_colors:
        pal.face_back, pal.face_front = (_resolve(c) for c in spec.face_colors)
    if spec.glyph_hue is not None:
        pal.glyph = oklch(0.86, 0.17, spec.glyph_hue)
    if spec.glyph_color:
        pal.glyph = _resolve(spec.glyph_color)
    if spec.texture_color:
        pal.texture = _resolve(spec.texture_color)
    return pal


def icon_group(spec: Spec, cx: float, cy: float, size: float, uid: str) -> tuple[str, str]:
    if spec.style not in STYLES:
        raise ValueError(f"unknown style {spec.style!r}; expected one of {', '.join(STYLES)}")
    if spec.style == "stacked":
        return _slab_group(spec, _palette(spec), cx, cy, size, uid)
    return _tile_group(spec, _palette(spec), cx, cy, size, uid)


def _slab_group(spec: Spec, pal: Palette, cx: float, cy: float, size: float, uid: str) -> tuple[str, str]:
    unit = continuous_square(SLAB_CORNER)
    raw = [((x - y) / math.sqrt(2), (x + y) / math.sqrt(2) * K) for x, y in unit]
    span_x = max(p[0] for p in raw) - min(p[0] for p in raw)
    span_y = max(p[1] for p in raw) - min(p[1] for p in raw)
    width = size * WIDTH
    for _ in range(2):  # shrink once if standing objects make the composition taller than the canvas
        scale = width / span_x
        face_h = span_y * scale
        depth = width * DEPTH
        objects = list(spec.objects) + [
            {"kind": "cube", "x": b[0], "y": b[1], "h": b[2] * width / (scale * VERT),
             "s": b[3] if len(b) > 3 else 0.085, "color": {"tint": spec.hue}}
            for b in spec.blocks
        ]
        rel_top = min([-face_h / 2] + [_object_top(o, scale) for o in objects])
        rel_bottom = face_h / 2 + depth
        if rel_bottom - rel_top <= size * 0.98:
            break
        width *= size * 0.98 / (rel_bottom - rel_top)
    top_y = cy - (rel_top + rel_bottom) / 2

    face = [to_screen(x, y, cx, top_y, scale) for x, y in unit]
    half_w = width / 2
    defs, body = [], []

    # Bands, bottom first, contiguous.
    t = depth / spec.bands
    for i in reversed(range(spec.bands)):
        y = top_y + i * t
        pts = [(x, py + i * t) for x, py in face]
        body.append(f'<path d="{path_d(band(pts, t))}" fill="{pal.bands[i]}"/>')
        # Side shading: lighter on the left face, darker on the right face.
        shade = f"{uid}-sh{i}"
        defs.append(
            f'<linearGradient id="{shade}" gradientUnits="userSpaceOnUse" x1="{cx - half_w:.1f}" y1="0" x2="{cx + half_w:.1f}" y2="0">'
            f'<stop offset="0" stop-color="#ffffff" stop-opacity="0.16"/>'
            f'<stop offset="0.40" stop-color="#ffffff" stop-opacity="0.04"/>'
            f'<stop offset="0.60" stop-color="#000000" stop-opacity="0.06"/>'
            f'<stop offset="1" stop-color="#000000" stop-opacity="0.20"/></linearGradient>'
        )
        body.append(f'<path d="{path_d(band(pts, t))}" fill="url(#{shade})"/>')
        # Thin rim where this band meets the one above.
        body.append(
            f'<path d="{path_d(front_half(pts), close=False)}" fill="none" stroke="#ffffff" '
            f'stroke-opacity="0.30" stroke-width="{size * 0.0035:.2f}"/>'
        )

    # Top face.
    defs.append(
        f'<linearGradient id="{uid}-face" gradientUnits="userSpaceOnUse" x1="{cx - half_w * 0.35:.1f}" y1="{top_y - face_h / 2:.1f}" '
        f'x2="{cx + half_w * 0.35:.1f}" y2="{top_y + face_h / 2:.1f}">'
        f'<stop offset="0" stop-color="{pal.face_back}"/><stop offset="1" stop-color="{pal.face_front}"/></linearGradient>'
    )
    body.append(f'<path d="{path_d(face)}" fill="url(#{uid}-face)"/>')
    defs.append(f'<clipPath id="{uid}-clip"><path d="{path_d(face)}"/></clipPath>')
    iso = f"translate({cx:.2f} {top_y:.2f}) scale(1 {K}) rotate(45)"
    tex = texture_markup(spec.texture, pal.texture)
    if tex:
        body.append(f'<g clip-path="url(#{uid}-clip)" opacity="{_setting(spec, "texture_opacity")}"><g transform="{iso} scale({scale:.2f})">{tex}</g></g>')
    defs.append(
        f'<radialGradient id="{uid}-sheen" gradientUnits="userSpaceOnUse" cx="{cx - half_w * 0.30:.1f}" cy="{top_y - face_h * 0.35:.1f}" r="{half_w:.1f}">'
        f'<stop offset="0" stop-color="#ffffff" stop-opacity="0.28"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>'
    )
    body.append(f'<path d="{path_d(face)}" fill="url(#{uid}-sheen)"/>')
    body.append(
        f'<path d="{path_d(face)}" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="{size * 0.004:.2f}" clip-path="url(#{uid}-clip)"/>'
    )

    # Glyph lying on the face, optionally raised into a thin slab.
    g = spec.custom_glyph or GLYPHS.get(spec.glyph)
    if g:
        gs = scale * spec.glyph_scale
        ox, oy = to_screen(*(spec.glyph_offset or (0.0, 0.0)), cx, top_y, scale)
        tf = f"translate({ox:.2f} {oy:.2f}) scale(1 {K}) rotate({45 + _setting(spec, 'glyph_rotation')}) scale({gs:.2f})"
        fills = [oklch(spec.fill_lightness, 0.16, h) for h in spec.glyph_fills] or None
        color = pal.glyph
        if spec.glyph_gradient:
            defs.append(
                f'<linearGradient id="{uid}-gg" gradientUnits="userSpaceOnUse" x1="-1" y1="-1" x2="1" y2="1">'
                f'<stop offset="0" stop-color="{spec.glyph_gradient[0]}"/><stop offset="1" stop-color="{spec.glyph_gradient[1]}"/></linearGradient>'
            )
            color = f"url(#{uid}-gg)"
        shadow_fills = [pal.glyph_shadow] if fills else None
        relief = _setting(spec, "glyph_relief")
        if relief:
            rp = relief * size
            if spec.glyph_side:
                side = _resolve(spec.glyph_side)
            elif spec.glyph_hue is not None:
                side = oklch(0.60, 0.15, spec.glyph_hue)
            elif spec.glyph_gradient:
                side = oklch(0.50, 0.16, spec.hue)
            elif spec.face == "graphite":
                side = oklch(0.68, 0.01, 260)
            else:
                side = oklch(0.80, 0.08, spec.hue)
            side_fills = [oklch(spec.fill_lightness - 0.22, 0.14, h) for h in spec.glyph_fills] or None
            defs.append(
                f'<filter id="{uid}-gblur" x="-30%" y="-30%" width="160%" height="160%">'
                f'<feGaussianBlur stdDeviation="{size * 0.006:.2f}"/></filter>'
            )
            body.append(
                f'<g filter="url(#{uid}-gblur)" opacity="0.45"><g transform="translate({size * 0.004:.2f} {size * 0.006:.2f})">'
                f'<g transform="{tf}">{glyph_markup(g, pal.glyph_shadow, 1.0, shadow_fills, pal.glyph_shadow)}</g></g></g>'
            )
            steps = max(3, math.ceil(rp / 0.7))
            for k in range(steps):
                body.append(
                    f'<g transform="translate(0 {-rp * k / steps:.2f})"><g transform="{tf}">'
                    f'{glyph_markup(g, side, 1.0, side_fills, side)}</g></g>'
                )
            body.append(
                f'<g transform="translate(0 {-rp:.2f})"><g transform="{tf}">'
                f'{glyph_markup(g, color, 1.0, fills, pal.face_front)}</g></g>'
            )
        else:
            body.append(
                f'<g transform="translate(0 {size * 0.008:.2f})" opacity="0.35"><g transform="{tf}">'
                f'{glyph_markup(g, pal.glyph_shadow, 1.0, shadow_fills, pal.glyph_shadow)}</g></g>'
            )
            body.append(f'<g transform="{tf}">{glyph_markup(g, color, 0.95, fills, pal.face_front)}</g>')

    # Standing objects: soft contact shadows, then back to front.
    if objects:
        project = lambda px, py: to_screen(px, py, cx, top_y, scale)  # noqa: E731
        defs.append(
            f'<filter id="{uid}-oblur" x="-50%" y="-50%" width="200%" height="200%">'
            f'<feGaussianBlur stdDeviation="{size * 0.012:.2f}"/></filter>'
        )
        shadows = []
        for o in objects:
            px, py = project(o.get("x", 0.0) + 0.03, o.get("y", 0.0) + 0.01)
            r = o.get("s", 0.1) * scale * (1.45 if o["kind"] in ("cube", "glass") else 1.15)
            shadows.append(f'<ellipse cx="{px:.2f}" cy="{py:.2f}" rx="{r:.2f}" ry="{r * K:.2f}"/>')
        body.append(
            f'<g clip-path="url(#{uid}-clip)"><g filter="url(#{uid}-oblur)" fill="{pal.glyph_shadow}" opacity="0.40">'
            + "".join(shadows) + "</g></g>"
        )
        for o in sorted(objects, key=lambda o: o.get("x", 0.0) + o.get("y", 0.0)):
            body.append(draw_object(o, project, scale, spec.hue, uid, defs))

    return "".join(defs), "".join(body)


def _tile_colors(spec: Spec, pal: Palette) -> tuple[str, str]:
    """Top and bottom of a tile's vertical gradient."""
    if spec.face_colors or spec.face in ("graphite", "light"):
        return pal.face_back, pal.face_front
    return tile_ramp(spec.hue, spec.mode, spec.vivid, spec.tone, spec.drift)


def draw_panel(o: dict, x0: float, y0: float, side: float, hue: float, uid: str, defs: list) -> str:
    """One front-facing panel. Positions and sizes are in tile units (side = 1).

    x, y: center relative to the tile center; w, h: size; corner: corner scale
    color: "glass", a hue, or [top, bottom]; opacity: fill opacity
    """
    w, h = o.get("w", 0.4) * side, o.get("h", 0.3) * side
    px = x0 + (0.5 + o.get("x", 0.0)) * side - w / 2
    py = y0 + (0.5 + o.get("y", 0.0)) * side - h / 2
    outline = tile_path(px, py, w, h, o.get("corner", 0.8))
    color = o.get("color", "glass")
    gid = f"{uid}-p{len(defs)}"
    out = [f'<g filter="url(#{uid}-pblur)" opacity="0.28"><path d="{outline}" fill="{oklch(0.30, 0.05, hue)}" '
           f'transform="translate(0 {h * 0.06:.2f})"/></g>']
    if color == "glass":
        top, bottom, opacity = "#ffffff", "#ffffff", o.get("opacity", 0.30)
    elif isinstance(color, (int, float)):
        top, bottom, opacity = oklch(0.80, 0.12, color), oklch(0.62, 0.17, color), o.get("opacity", 0.90)
    else:
        top, bottom = (_resolve(c) for c in color)
        opacity = o.get("opacity", 0.90)
    defs.append(
        f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="0" y1="{py:.1f}" x2="0" y2="{py + h:.1f}">'
        f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>'
    )
    out.append(f'<path d="{outline}" fill="url(#{gid})" fill-opacity="{opacity}"/>')
    out.append(f'<path d="{outline}" fill="none" stroke="#ffffff" stroke-opacity="0.85" '
               f'stroke-width="{side * 0.006:.2f}"/>')
    return "".join(out)


def _tile_group(spec: Spec, pal: Palette, cx: float, cy: float, size: float, uid: str) -> tuple[str, str]:
    side = size * TILE_SIZE
    x0, y0 = cx - side / 2, cy - side / 2
    outline = tile_path(x0, y0, side)
    top, bottom = _tile_colors(spec, pal)
    defs = [
        f'<linearGradient id="{uid}-tile" gradientUnits="userSpaceOnUse" x1="0" y1="{y0:.1f}" x2="0" y2="{y0 + side:.1f}">'
        f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>',
        f'<clipPath id="{uid}-clip"><path d="{outline}"/></clipPath>',
        f'<radialGradient id="{uid}-sheen" gradientUnits="userSpaceOnUse" cx="{x0 + side * 0.28:.1f}" '
        f'cy="{y0 + side * 0.12:.1f}" r="{side * 0.85:.1f}">'
        f'<stop offset="0" stop-color="#ffffff" stop-opacity="0.22"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/>'
        f'</radialGradient>',
    ]
    body = [f'<path d="{outline}" fill="url(#{uid}-tile)"/>']
    tex = texture_markup(spec.texture, pal.texture)
    if tex:
        body.append(f'<g clip-path="url(#{uid}-clip)" opacity="{_setting(spec, "texture_opacity")}">'
                    f'<g transform="translate({cx:.2f} {cy:.2f}) scale({side:.2f})">{tex}</g></g>')
    body.append(f'<path d="{outline}" fill="url(#{uid}-sheen)"/>')

    if spec.blocks or any(o.get("kind", "panel") != "panel" for o in spec.objects):
        raise ValueError(f"{spec.style} tiles take panel objects only; blocks and standing objects need the stacked style")
    if spec.objects:
        defs.append(f'<filter id="{uid}-pblur" x="-30%" y="-30%" width="160%" height="160%">'
                    f'<feGaussianBlur stdDeviation="{side * 0.02:.2f}"/></filter>')
        body.append(f'<g clip-path="url(#{uid}-clip)">'
                    + "".join(draw_panel(o, x0, y0, side, spec.hue, uid, defs) for o in spec.objects) + "</g>")

    g = spec.custom_glyph or GLYPHS.get(spec.glyph)
    if g:
        ox, oy = spec.glyph_offset or (0.0, 0.0)
        tf = (f"translate({cx + ox * side:.2f} {cy + oy * side:.2f}) "
              f"rotate({45 + _setting(spec, 'glyph_rotation')}) scale({side * spec.glyph_scale:.2f})")
        fills = [oklch(spec.fill_lightness, 0.16, h) for h in spec.glyph_fills] or None
        color = pal.glyph
        if spec.glyph_gradient:
            defs.append(
                f'<linearGradient id="{uid}-gg" gradientUnits="userSpaceOnUse" x1="-1" y1="-1" x2="1" y2="1">'
                f'<stop offset="0" stop-color="{spec.glyph_gradient[0]}"/><stop offset="1" stop-color="{spec.glyph_gradient[1]}"/></linearGradient>'
            )
            color = f"url(#{uid}-gg)"
        relief = _setting(spec, "glyph_relief")
        if relief:
            # Extrusion toward the lower right; light comes from the upper left.
            e = relief * size
            if spec.glyph_side:
                side_color = _resolve(spec.glyph_side)
            elif spec.glyph_hue is not None:
                side_color = oklch(0.55, 0.15, spec.glyph_hue)
            elif spec.face == "light":
                side_color = oklch(0.45, 0.14, spec.hue)
            else:
                side_color = oklch(0.74, 0.09, spec.hue)
            side_fills = [oklch(spec.fill_lightness - 0.22, 0.14, h) for h in spec.glyph_fills] or None
            defs.append(f'<filter id="{uid}-gblur" x="-30%" y="-30%" width="160%" height="160%">'
                        f'<feGaussianBlur stdDeviation="{size * 0.012:.2f}"/></filter>')
            body.append(
                f'<g clip-path="url(#{uid}-clip)"><g filter="url(#{uid}-gblur)" opacity="0.40">'
                f'<g transform="translate({e * 0.6:.2f} {e * 1.3:.2f})"><g transform="{tf}">'
                f'{glyph_markup(g, pal.glyph_shadow, 1.0, [pal.glyph_shadow] if fills else None, pal.glyph_shadow)}'
                f'</g></g></g></g>'
            )
            steps = max(3, math.ceil(e / 0.7))
            for k in range(steps, 0, -1):
                body.append(
                    f'<g transform="translate({e * 0.35 * k / steps:.2f} {e * k / steps:.2f})"><g transform="{tf}">'
                    f'{glyph_markup(g, side_color, 1.0, side_fills, side_color)}</g></g>'
                )
            # Bevel: a lit upper-left edge, and a front face shading toward the lower right.
            body.append(f'<g transform="translate({-e * 0.10:.2f} {-e * 0.10:.2f})" opacity="0.55"><g transform="{tf}">'
                        f'{glyph_markup(g, "#ffffff", 1.0, ["#ffffff"] if fills else None, "#ffffff")}</g></g>')
            if not spec.glyph_gradient and not spec.glyph_color:
                if spec.glyph_hue is not None:
                    front_end = oklch(0.74, 0.17, spec.glyph_hue)
                elif spec.face == "light":
                    front_end = oklch(0.52, 0.16, spec.hue)
                else:
                    front_end = oklch(0.90, 0.045, spec.hue)
                defs.append(
                    f'<linearGradient id="{uid}-gf" gradientUnits="userSpaceOnUse" x1="-1" y1="-1" x2="1" y2="1">'
                    f'<stop offset="0" stop-color="{color}"/><stop offset="1" stop-color="{front_end}"/></linearGradient>'
                )
                color = f"url(#{uid}-gf)"
        body.append(f'<g transform="{tf}">{glyph_markup(g, color, 1.0 if relief else 0.95, fills, bottom)}</g>')

    body.append(f'<path d="{outline}" fill="none" stroke="#ffffff" stroke-opacity="0.35" '
                f'stroke-width="{size * 0.004:.2f}" clip-path="url(#{uid}-clip)"/>')
    return "".join(defs), "".join(body)


def icon_svg(spec: Spec, size: int = 1024) -> str:
    defs, body = icon_group(spec, size / 2, size / 2, size, "i")
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">'
        f"<defs>{defs}</defs>{body}</svg>\n"
    )


def main(argv: list[str]) -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--spec", help="JSON object with Spec fields")
    p.add_argument("--out", default="-")
    p.add_argument("--size", type=int, default=1024)
    a = p.parse_args(argv)
    spec = Spec(**json.loads(a.spec)) if a.spec else Spec()
    svg = icon_svg(spec, a.size)
    if a.out == "-":
        sys.stdout.write(svg)
    else:
        with open(a.out, "w") as f:
            f.write(svg)


if __name__ == "__main__":
    main(sys.argv[1:])
