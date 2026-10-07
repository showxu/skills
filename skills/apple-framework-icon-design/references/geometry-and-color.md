# Geometry and Color

Rules for choosing icon parameters. The proportions and ramps were fitted
against Apple developer framework icons used as visual reference only; no
artwork or glyphs are copied.

## Fixed Geometry

These constants live in `scripts/stack_logo.py` and apply to every icon in a
family. Do not vary them per icon.

| Constant | Value | Meaning |
| --- | --- | --- |
| `K` | 0.75 | Vertical squash of the top face. |
| `DEPTH` | 0.36 | Stack depth as a fraction of icon width. |
| `CORNER` | 0.396305, 0.230261, 0.152117, 0.076058 | Continuous corner, as fractions of the side measured from the corner. |
| `TILE_CORNER` | 1.0 | Corner scale of a front-facing tile. |
| `SLAB_CORNER` | 0.70 | Corner scale of the stacked slab's top face. |
| `WIDTH` | 0.88 | Slab width as a fraction of the canvas. |
| `TILE_SIZE` | 0.906 | Tile side as a fraction of the canvas. |

Light comes from the upper left: left sides are lighter than right sides,
and raised glyphs cast a soft contact shadow toward the lower right.

## Corner Geometry

Each corner is two cubic Béziers mirrored across the corner's diagonal. The
first leaves the straight edge at `CORNER[0]` from the corner, with both
control points on the edge (`CORNER[1]`, `CORNER[2]`), so curvature is zero
where the curve meets the edge; it ends on the diagonal at `CORNER[3]` from
each edge. Curvature is continuous along the whole outline.
`continuous_square()` returns the outline as points for the slab projection,
and `tile_path()` returns it as an SVG path for front-facing tiles.

At scale 1.0 the outline is the app icon mask:

- Ground truth is a full-bleed solid `.icon` exported by `ictool` 27.0 at
  1024 px, for iOS and macOS, design generations 26 and 27. All four masks
  are identical.
- The `tile_path()` outline rendered at 1024 px has IoU 0.99977 with that
  mask and at most 0.35 px bidirectional contour deviation, measured on the
  50% alpha contour with marching squares. Acceptance is IoU of at least
  0.999 and deviation of at most 0.5 px.
- Apple's iOS 27 App Icon Template draws its mask with 10 cubics per corner.
  That path is within 1.06 px of the `ictool` mask, and this outline is
  within 0.89 px of it.
- Front-facing framework tiles (SwiftUI, Create ML) fit best at scale 1.005,
  so tiles use 1.0.
- Stacked slab silhouettes (CloudKit, Core ML, ARKit, SceneKit, WidgetKit)
  fit best between 0.56 and 0.83; 0.70 gives the highest mean silhouette IoU,
  above the circular corner it replaced.

Re-measure when Xcode changes the icon mask: export a solid `.icon` with
`ictool --export-image` and compare its alpha with `tile_path()` at the same
size.

## Styles

| Style | Shape | Glyph | Visual references |
| --- | --- | --- | --- |
| `stacked` | Isometric slab of bands | Lying flat, raised, or standing objects | CloudKit, Core ML, RealityKit, SceneKit, WidgetKit |
| `volumetric` | Front-facing tile | Extruded, with bevel and contact shadow; glass panels; optional grid backdrop | Create ML, Metal, TestFlight, Xcode Cloud, Reality Composer Pro, App Intents, Swift Charts |
| `flat` | Front-facing tile | Flat, on a gradient | SwiftUI, SharePlay, Focus |

- A family keeps one shape: stacked slabs, or tiles. Volumetric and flat
  tiles mix within a family.
- Choose the slab when the member is a layer others build on, such as a
  framework or storage. Choose a tile when the member reads as a tool or
  product, and volumetric when its idea has physical depth.
- The tile gradient comes from `tile_ramp()`: `deepen` runs from L 0.73,
  C 0.15 at the top to L 0.56, C 0.19 at the bottom, with the hue drifting
  the ramp's way; `glow` runs from the deep end up to L 0.80. `tone` and
  `vivid` shift it like the slab ramp. `face: "light"` gives the white tiles
  of Xcode Cloud or App Intents, with the glyph and panels carrying the hue.

## Fidelity

`design_icons.py --fidelity REFDIR` renders each style's plain outline at
256 px and compares it with reference PNGs named `icon-<name>.png`: silhouette
IoU, and the mean OKLab lightness difference along a sample line (down the
slab's sides, or down a tile's left margin) against the best-matching ramp.
References are images the owner supplies for comparison, such as the
framework icons on Apple's developer site. They stay outside the repository
and are never traced.

Run it after changing geometry constants or ramps. At the current values:

| Style | Mean silhouette IoU | Ramp lightness difference |
| --- | --- | --- |
| `stacked` | 0.9226; above 0.95 except Core ML (smaller slab) and RealityKit (standing objects) | 0.05 to 0.21 |
| `volumetric` | 0.9988 | 0.001 to 0.08 |
| `flat` | 0.9879 | 0.014 to 0.13 |

A drop in silhouette IoU means geometry drifted. A large ramp difference for
one reference means its palette sits outside the derived ramps, and an entry
imitating it needs `tone`, `vivid`, or explicit colors.

## Side Ramps

The bands read as one continuous ramp from the face down. Patterns that work:

- **Deepen**: the first band keeps the face's lightness with a little less
  chroma, then each band steps darker while the hue drifts one way.
  Example measurement: face L 0.80, bands 0.80, 0.71, 0.57; hue 222 to 266.
- **Glow**: a mid-dark face with bands brightening toward a luminous bottom.
  Example: face front L 0.61, bands 0.70, 0.76, 0.87.
- **Graphite glow**: dark neutral face (L about 0.36) with neutral bands
  brightening downward (0.39, 0.49, 0.57).
- **Accent then neutral**: a light colored face, one band continuing the
  face color, then graphite bands darkening (0.81, then 0.54, 0.38).
- **White face**: white face, a near-white band (L 0.93), then saturated
  bands of the member's hue (L about 0.67 to 0.59, chroma about 0.11 to 0.15).
- **Rose ramp**: a red face (L 0.67, C 0.20) whose bands dip, then brighten
  into pink (0.59, 0.67, 0.81). Pink is the bright end of a red ramp.
- Hue may jump between bands when lightness stays level.

Failures seen in practice:

- A near-white first band under a mid-lightness face (0.77, 0.92, 0.64)
  breaks the ramp.
- A dark face over light rainbow bands (0.27, then 0.78) reads as two
  objects.
- Purples and pinks at high lightness look pastel; lower the tone and raise
  chroma instead (`tone`, `vivid`).
- Warm hues drifting toward yellow turn brown; the default drift moves them
  toward red and magenta.

## Hues Across a Family

- List current hues with `design_icons.py DESIGN.md --tints`.
- Space a new hue as far as possible from its neighbors on the hue circle.
  Below about 25 degrees apart, change the ramp pattern or face treatment so
  the two stay distinct at 40 px.
- Keep one umbrella icon (the organization) allowed to share a hue with a
  member when their glyphs differ strongly.

## Glyphs

- Raised glyphs, stacked offset copies with a blurred contact shadow, read as
  thick slab letters. Keep `glyph_relief` at its default unless the glyph is
  very thin.
- Standing objects (cube, glass, cylinder, cone, sphere) suit members whose
  idea is physical: measurement bars, storage, containers.
- Symbols that must be read stay upright (`glyph_rotation: -45`). Symmetric
  marks lie along the face axes (`0`).
- A plus sign laid on the axes reads as an x; draw it diagonally or dashed.
- One idea per glyph. If it needs a caption to be understood, choose another.
- Do not imitate another company's or project's logo, even when the member
  integrates with that product. A generic glyph and a palette reference are
  acceptable.

## Review Sizes

Check every change at 1024 px for detail, 160 px for README headers, and
40 px for profile tables, on white and on `#0d1117`.
