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

The slab's two sides are separate lit planes. The left plane keeps the band
color, the right plane falls into shade, and the front corner between them
carries a narrow highlight. On Apple's CloudKit icon the bottom band measures
L 0.50 to 0.55 on the left, 0.58 at the front corner, and 0.35 to 0.39 on the
right. The top face stays nearly flat color: a faint sheen and edge, no
outline, so the face and the first band read as one solid top layer. Raised
glyphs cast a soft contact shadow toward the lower right.

## Corner Geometry

Each corner is two cubic Béziers mirrored across the corner's diagonal. The
first leaves the straight edge at `CORNER[0]` from the corner, with both
control points on the edge (`CORNER[1]`, `CORNER[2]`), so curvature is zero
where the curve meets the edge; it ends on the diagonal at `CORNER[3]` from
each edge. Curvature is continuous along the whole outline.
`continuous_square()` returns the outline as points for the slab projection,
and `tile_path()` returns it as an SVG path for front-facing tiles.

At scale 1.0 the outline is the Liquid Glass app icon mask. `CORNER` equals
`CORNER` in `apple-app-icon-design`, whose `references/rendering.md` owns the
measurement against Icon Composer and Apple's App Icon Template; change both
skills together.

- Front-facing framework tiles (SwiftUI, Create ML) fit best at scale 1.005,
  so tiles use 1.0.
- Stacked slab silhouettes (CloudKit, Core ML, ARKit, SceneKit, WidgetKit)
  fit best between 0.56 and 0.83; 0.70 gives the highest mean silhouette IoU,
  above the circular corner it replaced.

When Xcode changes the icon mask, re-measure as `apple-app-icon-design`
describes, then refit the tile and slab scales here.

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
IoU, and the mean OKLab lightness and chroma differences along a sample line
(down the slab's front corner, or down a tile's left margin) against the
best-matching ramp. For slabs it also prints the bottom band's left-minus-right
lightness as `reference/ours`. References are images the owner supplies for
comparison, such as the 256 px framework icons on Apple's developer site
(`https://developer.apple.com/assets/elements/icons/<name>/<name>-128x128_2x.png`).
They stay outside the repository and are never traced.

Run it after changing geometry constants, ramps, or slab lighting. At the
current values:

| Style | Mean silhouette IoU | Ramp lightness difference | Ramp chroma difference | Slab side contrast |
| --- | --- | --- | --- | --- |
| `stacked` | 0.9224; above 0.95 except Core ML (smaller slab) and RealityKit (standing objects) | 0.04 to 0.22; CloudKit 0.047, Core ML 0.038 | 0.012 to 0.12; CloudKit 0.012, Core ML 0.014 | references 0.11 to 0.33; ours 0.13 (`deepen`), 0.18 (`glow`) |
| `volumetric` | 0.9988 | 0.001 to 0.082 | 0.002 to 0.049 | - |
| `flat` | 0.9879 | 0.014 to 0.125 | 0.020 to 0.172 | - |

A drop in silhouette IoU means geometry drifted. A large ramp difference for
one reference means its palette sits outside the derived ramps (ARKit's
graphite, RealityKit's standing objects, WidgetKit's glass panels), and an
entry imitating it needs `tone`, `vivid`, or explicit colors.

## Palette Lint

`design_icons.py DESIGN.md --lint` checks each slab entry's resolved palette,
derived or explicit, and exits 1 on any finding:

- `seam`: the first band's lightness differs from the face front by more than
  0.10. Apple's first band continues the face material (CloudKit 0.79 to
  0.77, Core ML 0.73 to 0.70, a white face over a 0.92 band).
- `dark face`: a face front below L 0.45 over bands that rise more than 0.30
  above it. The slab reads as a dark lid on a light base; ARKit's dark face
  keeps its bands below about 0.57.
- `pastel`: a color at L 0.80 or above with chroma between 0.03 and 0.11.
  Light Apple colors keep chroma (CloudKit face 0.79/0.12, Core ML bottom
  0.86/0.16); neutral whites and graphites are exempt.

## Side Ramps

The bands read as one continuous ramp from the face down. Patterns that work:

- **Deepen**: the first band keeps the face's lightness with a little less
  chroma, then each band steps darker while the hue drifts one way.
  Example measurement: face L 0.80, bands 0.80, 0.71, 0.57; hue 222 to 266.
- **Glow**: a mid-dark face with bands brightening toward a luminous bottom
  that gains chroma. Example: face front L 0.61, bands 0.70, 0.76, 0.87;
  chroma 0.12 rising to 0.16 at the bottom.
- **Graphite glow**: dark neutral face (L about 0.36) with neutral bands
  brightening downward (0.39, 0.49, 0.57).
- **Accent then neutral**: a light colored face, one band continuing the
  face color, then graphite bands darkening (0.81, then 0.54, 0.38).
- **White face**: white face, a near-white band (L 0.93), then saturated
  bands of the member's hue (L about 0.67 to 0.59, chroma about 0.11 to 0.15).
- **Rose ramp**: a red face (L 0.67, C 0.20) whose bands dip, then brighten
  into pink (0.59, 0.67, 0.81). Use explicit face and band colors for this
  non-monotonic ramp; it follows the same seam and chroma limits as other
  palettes. Pink is the bright end of a red ramp, not a pastel exemption.
  Check resolved sRGB colors: if gamut mapping reduces the pink below the
  chroma limit, lower its lightness before increasing chroma.
- Hue may jump between bands when lightness stays level.

Failures seen in practice:

- A near-white first band under a mid-lightness face (0.77, 0.92, 0.64)
  breaks the ramp.
- A dark face over light rainbow bands (0.27, then 0.78) reads as two
  objects.
- A white outline, strong sheen, or dense texture on the face separates it
  from the bands and washes out its chroma.
- Light blues, violets, and reds cannot hold slab chroma in sRGB near L 0.80
  and turn pastel. Derived palettes lower such a color's lightness by up to
  0.06 before reducing its chroma; explicit colors need a lower lightness, or
  `tone` and `vivid`.
- Warm hues drifting toward yellow turn brown; the default drift moves them
  toward red and magenta.

## Hues Across a Family

- List current hues with `design_icons.py DESIGN.md --tints`.
- Space a new hue as far as possible from its neighbors on the hue circle.
  Below about 25 degrees apart, change the ramp pattern or face treatment so
  the two stay distinct at 40 px.
- Members have distinct hues; changing a ramp does not permit duplicate
  member hues. Only the umbrella icon may share a hue with one member,
  when their glyphs differ strongly.

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

## Review Sizes

Check every change at 1024 px for detail, 160 px for README headers, and
40 px for profile tables, on white and on `#0d1117`.
