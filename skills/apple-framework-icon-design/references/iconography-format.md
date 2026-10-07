# Iconography Format

`DESIGN.md` follows Google's DESIGN.md format: YAML frontmatter tokens and
`##` sections. Icon parameters live in an extra `## Iconography` section,
which DESIGN.md consumers preserve as an unknown section. The section holds
prose and exactly one fenced `json` block:

```json
{
  "icons": {
    "swift-example": {"hue": 205, "mode": "deepen", "bands": 3, "glyph": "braces", "texture": "lines", "glyph_rotation": -45}
  }
}
```

Keys under `icons` are icon names, normally repository names. Each value
uses the fields below; unknown fields are rejected so typos fail loudly.

Validate the whole file with `npx @google/design.md lint DESIGN.md` after
editing tokens; the linter does not read the Iconography block, and
`design_icons.py` does.

## Colors

Write colors as `"oklch(L C h)"` (L from 0 to 1, or a percentage), hex
strings, or `[L, C, h]` lists. OKLCH keeps lightness steps even across hues,
which the band ramps depend on. Colors outside sRGB lose chroma until they
fit.

## Fields

| Field | Default | Meaning |
| --- | --- | --- |
| `hue` | 250 | OKLCH hue that derives the palette when explicit colors are absent; also the glow tint and object tint. |
| `style` | `stacked` | `stacked`: isometric slab. `volumetric`: front-facing tile with an extruded glyph and panels. `flat`: front-facing tile with a flat glyph. |
| `mode` | `deepen` | Slab: `deepen` bands darken and gain chroma; `glow` the face darkens toward the front and bands brighten toward the bottom. Tile: `deepen` runs light to deep from top to bottom; `glow` runs deep to luminous. |
| `bands` | 3 | Number of side bands (stacked). |
| `face_colors` | derived | `[back, front]` gradient of the top face; on a tile, `[top, bottom]`. |
| `band_colors` | derived | Band colors, top band first; overrides the derived ramp (stacked). |
| `band_hues` | none | One hue per band at fixed lightness steps (stacked). |
| `neutral_bands` | false | `true` for graphite bands that darken; `"glow"` for graphite that brightens downward (stacked). |
| `face` | none | `"graphite"` for a dark neutral face or tile; `"light"` for a white one with a glyph in the member's hue. |
| `vivid` | 1.0 | Chroma multiplier for the derived palette. |
| `tone` | 0.0 | Lightness offset for the whole derived ramp. |
| `drift` | auto | Hue drift direction of the ramp, `1` or `-1`. |
| `glyph` | `none` | Library glyph name (below). |
| `custom_glyph` | none | Glyph definition used instead of `glyph`. |
| `glyph_rotation` | per style | Degrees. `-45` keeps symbols upright and is the tile default; the slab default `-90` reads along the up-right edge, and `0` lays symmetric marks along the face axes. |
| `glyph_scale` | 0.31 | Glyph size relative to the face or tile. |
| `glyph_offset` | center | `[x, y]` on the face or tile, side = 1. |
| `glyph_relief` | per style | Raised (stacked, 0.018) or extruded (volumetric, 0.045) thickness as a fraction of icon size; `0` lays the glyph flat, the flat default. |
| `glyph_hue` | none | Colored glyph at a fixed bright lightness instead of white. |
| `glyph_color` | white | Explicit glyph color. |
| `glyph_side` | derived | Side color of a raised or extruded glyph. |
| `glyph_gradient` | none | Two colors across the glyph. |
| `glyph_fills` | none | Hues for multi-part glyph rectangles. |
| `fill_lightness` | 0.80 | Lightness of `glyph_fills` parts. |
| `texture` | `none` | `dots`, `grid`, `lines`, `rings`, or `constellation`. On a tile, `grid` is the grid backdrop. |
| `texture_opacity` | per style | Texture opacity: 0.30 on the slab, 0.18 on a tile. |
| `texture_color` | white | Texture color. |
| `objects` | none | Slab: standing 3D objects. Tile: panels. Both below. |
| `blocks` | none | Shorthand for tinted cubes: `[x, y, height, half-size?]` (stacked). |

A tile entry with `blocks` or a standing object is rejected; those need the
slab.

Tile entries look like this:

```json
"swift-example": {"style": "flat", "hue": 232, "glyph": "prompt"},
"example-kit": {"style": "volumetric", "hue": 196, "glyph": "chevrons", "texture": "grid", "glyph_scale": 0.28}
```

## Library Glyphs

`arrow`, `box`, `braces`, `brackets`, `chevrons`, `cloud_prompt`, `copy`,
`cycle`, `cylinder`, `dashed_plus`, `fast_forward`, `letter_s`, `loop3`,
`mug`, `one_zero`, `prompt`, `ring`, `shebang`, `spark`, `tag`, `tiles`,
`toggle`, `toggle_on`.

Print the current list with:

```bash
python3 -c "import sys; sys.path.insert(0, 'scripts'); import stack_logo; print(sorted(stack_logo.GLYPHS))"
```

## Custom Glyphs

Glyph coordinates span about -1 to 1 on each axis, y pointing down before
rotation.

```json
"custom_glyph": {
  "style": "stroke",
  "width": 0.15,
  "d": "M-0.5 -0.86 H0.5 A0.16 0.16 0 0 1 0.66 -0.7 V0.7 A0.16 0.16 0 0 1 0.5 0.86 H-0.5 A0.16 0.16 0 0 1 -0.66 0.7 V-0.7 A0.16 0.16 0 0 1 -0.5 -0.86 Z",
  "extra": "M-0.34 0.1 H0.34 M-0.34 0.4 H0.34",
  "rects": [[-0.17, -0.6, 0.34, 0.34]],
  "round": 0.08
}
```

- `style`: `stroke` draws `d` as rounded strokes of `width`; `fill` fills it.
- `extra`: a second stroked path.
- `dash`: stroke dash array for `d`.
- `rects`: filled rounded rectangles `[x, y, w, h]` with corner `round`.
- `dots`: filled circles `[x, y, r]`.
- `knock`: circles `[x, y, r]` in the accent color, for cut-outs.
- `transform`: SVG transform applied to the whole glyph.

## Standing Objects

On the slab, objects stand on the face instead of lying on it. Positions and
sizes are in face units (side = 1, center 0).

```json
"objects": [
  {"kind": "cube", "x": 0.04, "y": 0.3, "s": 0.07, "h": 0.14},
  {"kind": "cylinder", "x": -0.2, "y": 0.0, "s": 0.12, "h": 0.3, "rings": [0.33, 0.66]}
]
```

- `kind`: `cube`, `glass`, `cylinder`, `sphere`, or `cone`.
- `x`, `y`: base center; `s`: half-size (cube, glass) or radius; `h`: height.
- `color`: `"white"`, a hue number, `{"tint": hue}`, or `[top, left, right]`.
- `rings`: cylinder ring heights as fractions of the height.
- `inner`: hue of a cube inside a glass cube.

## Panels

On a tile, objects are front-facing panels with continuous corners, drawn in
list order behind the glyph. Positions and sizes are in tile units (side = 1,
center 0).

```json
"objects": [
  {"x": -0.16, "y": 0.10, "w": 0.34, "h": 0.42, "color": 10},
  {"x": 0.16, "y": -0.14, "w": 0.34, "h": 0.42, "color": "glass"}
]
```

- `kind`: `panel`, the default.
- `x`, `y`: center; `w`, `h`: size; `corner`: corner scale, default 0.8.
- `color`: `"glass"` (the default), a hue number, or `[top, bottom]`.
- `opacity`: fill opacity; 0.30 for glass, 0.90 otherwise.
