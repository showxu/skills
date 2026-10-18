# Rendering and Validation

## Native Tool

Use Icon Composer's export-capable `ictool`. The compiler found by
`xcrun ictool` can be a different program and may reject `--export-image`.
The script locates the renderer in the active Xcode application's bundled
Icon Composer, or accepts an explicit `--ictool` path or `IC_TOOL` variable.
It checks the tool's advertised export command before invoking it.

The renderer owns platform geometry and material effects. Export Default,
Dark, ClearLight, ClearDark, TintedLight, and TintedDark for iOS, macOS, and
watchOS. The output canvas is 1024 px for iOS/macOS and 1088 px for watchOS.
The generator verifies the dimensions of every native and web PNG before
publishing the candidate. Inspect the circular composition at small size. The same artwork and some
appearance labels may produce identical exports on a platform; preserve
the native result and do not invent differences.

Apple's design workflow separates foreground artwork from the background and
native materials. Layer fills can be solid or automatic gradients; group
blending and glass controls shape their overlap. Do not pre-mask layers or
paint native specular effects into them. See [Apple's workflow](https://developer.apple.com/videos/play/wwdc2025/361/).

## Apple Icon Material Study

A read-only `xcrun assetutil --info` inspection of the built-in Photos, Games,
App Store, Maps, and Preview `Assets.car` files on macOS 27.0.1 (26A434)
found the following compiled material metadata. These are observations of
Apple's icons, not a specification for the editable `.icon` JSON format.
No artwork, catalog, or extracted image is redistributed.

| Icon | Material evidence |
| --- | --- |
| Photos | `LayerGradientColorName`, opacity 0.5/0.95, Multiply/PlusL/Hard Light, refraction strength 0.10/0.23, translucency 0.05–0.40 |
| Games | Gradient colors, opacity down to 0.31, Multiply/PlusL, blur 0.48–0.50, refraction about 0.71, translucency 0.20–0.30 |
| App Store | Gradient colors, Multiply/Screen/PlusL/Hard Light, varying opacity and shadows |
| Maps | Gradient colors, Multiply, varying opacity, refraction about 0.56 |
| Preview | Gradient colors, PlusL/Soft Light, opacity 0.4/0.8, refraction about 0.24, translucency 0.20 |

All five contain specular-enabled elements with per-element gathering.
The editable document's `layer-color` shadow is chromatic; `neutral` is neutral.
Compiled shadow style numbers alone do not establish editable enum names.
Native probes below establish the names this generator accepts. Per-element
specular gathering is renderer behavior, not a separate entry control.

Use these observations to choose materials for original art: gradients model
color across a surface, overlapping glass transmits the layers behind it, and
blend modes control how their colors combine. The observed strengths are
examples, not prescribed defaults. [Apple's Icon Composer guide](https://developer.apple.com/icon-composer/)
describes the corresponding material and appearance controls.

## Native Material Schema

Verified with the export-capable Icon Composer 27.0 (129) renderer using an
original rounded colored panel over a contrasting background, exported as
iOS PNGs at 128 px. Comparisons decode pixels and require differences larger
than the skill's existing drift tolerance of 1/255 per channel.

- Group `blend-mode` accepts `normal`, `plus-lighter`, `plus-darker`, `overlay`,
  `multiply`, `soft-light`, `hard-light`, `darken`, `lighten`, and `screen`.
  Every non-normal mode changes the export. `normal` equals the omitted default.
- Group `specular: false` changes the export; `true` equals the omitted default.
  Group `opacity` changes the export.
- Shadow kinds `neutral`, `layer-color`, and `none` render successfully and
  change the shadow at controlled opacity. DESIGN.md also accepts `chromatic`
  for the chromatic shadow; both it and `layer-color` serialize to native
  `layer-color`. Scalar and appearance-specific values use the same conversion.
- Layer `solid` and `automatic-gradient` fills, fill alpha, and layer opacity
  change the export. The same color rendered as solid and automatic gradient
  produces different pixels.
- Layer blend mode and group `lighting` did not change exports in the supplied
  preliminary probes; these are not supported entry fields. The compiled icon
  catalog's `LayerBlendMode` does not establish a layer-level editable control.

Native scalar properties and their `-specializations` arrays are alternative
encodings. When both are present, the scalar wins and the override array is
ignored. This applies to layer fill and opacity, and to group opacity,
blend mode, specular, shadow, translucency, blur material, and refractivity.
For an inherited green solid fill with a red Dark override and full opacity
only in Dark, emit:

```json
{
  "fill-specializations": [
    {"value": {"solid": "srgb:0.00000,1.00000,0.00000,1.00000"}},
    {"appearance": "dark", "value": {"solid": "srgb:1.00000,0.00000,0.00000,1.00000"}}
  ],
  "opacity-specializations": [
    {"value": 0.6},
    {"appearance": "dark", "value": 1}
  ]
}
```

The unqualified item carries the inherited value (native `base`). The explicit
native appearance keys are `light`, `dark`, and `tinted`; DESIGN.md uses
`default`, `dark`, and `tinted`. Unmatched appearances retain the inherited
value, or the native default if no base was supplied. Layer fill and both
opacity owners were also rendered with no explicit base. Unknown fields are
errors in the entry contract, even when the native decoder might ignore them.

Probes compare all six iOS renditions for each property and each specialization
separately. A striped backdrop makes blur and refraction measurable. Results:

| Material | Generation 26 | Generation 27 |
| --- | --- | --- |
| Layer fill, layer/group opacity | Only the selected appearance family changes | Only the selected appearance family changes |
| Group blend mode, specular, shadow, translucency, blur material | Only the selected appearance family changes | Only the selected appearance family changes |
| Group refractivity | Both scalar and specialized values have no visible effect | Only the selected appearance family changes |

For each effective material, `light` changes only Default, `dark` only Dark,
and `tinted` all four Clear/Tinted renditions. Clear is not a separate
specialization family. Changes must exceed 1/255 per channel; unmatched
renditions must stay within the existing drift tolerance. These assertions
run in `NativeMaterialTests` when the export-capable renderer is available.

Only the native document carries materials. `flat`, `mac-tile`, and `gloss`,
their web icons, contact/comparison sheets, and drift checks use the original
SVG/PNG artwork. Liquid Glass masked web PNGs and its sheet cells use native
exports; its SVG favicon and full-bleed web sources keep their existing
artwork-only composition. Lint also measures artwork, never approximated glass.

### Optional dark web exports

Entry `web_dark: true` adds `web/dark/favicon-16.png`,
`web/dark/favicon-32.png`, `web/dark/icon-192.png`, `web/dark/icon-512.png`,
and `web/dark/avatar-1024.png` for Liquid Glass. Each is a resize of the native
iOS Dark PNG with its mask intact. The default web set is preserved; select
the dark files in the consuming site's theme or metadata. No dark SVG or
full-bleed touch/maskable approximation is generated from the masked export.
Omitting the option or setting it to false preserves the existing file set
and bytes. Other styles and document-only runs do not export the dark set.

## Liquid Glass Outline

The flat SVG approximation of a Liquid Glass icon, used for its
`favicon.svg` and for lint, uses two mirrored cubic segments per continuous
corner. In fractions of a square's side, the edge departure and control
values are `0.396305, 0.230261, 0.152117, 0.076058`. The native `.icon`
document does not contain this outline; native masks always come from the
renderer.

Validate these constants by rendering the SVG outline at 1024 px and
comparing its alpha with a full-bleed solid `.icon` exported for iOS and
macOS. Acceptance is alpha intersection-over-union at least 0.999 and
contour deviation at most 0.5 px. Use the installed tool and record the
version with the local results. Compare with Apple's App Icon Template as
an independent reference. If a platform's export uses an inset, preserve
and measure that placement; do not assume the canvas is fully occupied.

With Icon Composer 27 and design generations 26 and 27, the measured iOS
and macOS exports share the same mask. The outline achieves alpha IoU
0.999767 and bidirectional contour deviation 0.3491 px at 1024 px, measured
on the 50% alpha contour using marching squares and point-to-segment distance.
Apple's iOS 27 App Icon Template draws its mask with 10 cubics per corner;
that path is within 1.06 px of the Icon Composer mask, and this outline is
within 0.89 px of it.

`apple-framework-icon-design` draws its framework tiles with the same
`CORNER` values and relies on this measurement; change both skills together.

## Style Renderings

`flat`, `mac-tile`, and `gloss` are SVG compositions rendered with
`rsvg-convert`. The continuous corner is Apple's: three cubic segments per
corner, read from SwiftUI's `RoundedRectangle(cornerRadius:style: .continuous)`
path on macOS 27.0.1. Per unit radius, the corner departs each edge at
1.528665 and passes through (0.631494, 0.074911) and (0.074911, 0.631494);
`CONTINUOUS` in the script holds every control point.

| Style | Outline on 1024 px | Treatment | Source |
| --- | --- | --- | --- |
| `flat` | Continuous radius 229 px on the full canvas | Background, artwork | iOS 18 production template |
| `mac-tile` | Continuous radius 185.4 px on an 824 px tile inset 100 px | Black shadow: 10 px down, Gaussian deviation 10 px, opacity 0.30 | macOS 15 production template |
| `gloss` | Circular radius 10/57 of the side | White highlight, path `M0 0H1024V400Q512 620 0 400Z`, opacity 0.5 at the top to 0.1 at the bottom | Approximation |

Measurements used Apple's production templates for Sketch, compared at
1024 px with `rsvg-convert` 2.63.2:

- `https://devimages-cdn.apple.com/design/resources/download/iOS-18-Production-Templates-Sketch.dmg`
  (`Template - App Icon.sketch`)
- `https://devimages-cdn.apple.com/design/resources/download/macOS-Sequoia-Production-Templates-Sketch.dmg`
  (`Template - Icon - App.sketch`)

`apple-design-resource` catalogs both under `Previous releases` while Apple
serves them. To fetch them, with the other production templates for Sketch,
into an archive and unpack the Sketch files:

```sh
python3 skills/apple-design-resource/scripts/fetch_apple_design_resources.py \
  --include-previous --label-contains "Production Templates Sketch" \
  --download-direct --downloads-dir ARCHIVE \
  --extract-dmg --accept-license --extract-extension .sketch
```

Results:

- **flat**: the template's 1024 px mask is a smooth-corner rectangle with
  radius 229. Against it, the continuous outline with radius 229 has alpha
  IoU 0.99935; radius 225 has 0.99861, radius 233 has 0.99805, a circular
  radius 229 has 0.99798, and the Liquid Glass outline has 0.98322.
- **mac-tile**: the template's 1024 px mask is an 824 px path inset 100 px.
  The continuous outline with radius 185.4 has alpha IoU 0.99895; radius 185
  has 0.99904, a circular corner 0.99780, and the Liquid Glass outline
  0.98333. The template supplies its shadow as an image; the shadow above
  reproduces it with mean absolute alpha error 0.00044 outside the tile at
  256 px.
- **gloss**: no Apple template for iOS 1 to 6 remains available. The corner
  ratio is the 10 px radius of a 57 px icon reported by
  [Hicks Design](https://hicks.design/journal/ios-icon-corner-radii); the
  highlight shape and opacity are visual approximations.

Apple's templates are licensed Apple Design Resources. This skill records
measured values only and does not redistribute template content; repeating a
measurement requires accepting the license agreement in each disk image.

## Web Icons

Every style writes the same default web set. Liquid Glass can also opt into
the [dark web exports](#optional-dark-web-exports).

- **Masked images** come from the style's own rendering: `favicon-16.png`,
  `favicon-32.png`, `icon-192.png`, and `icon-512.png` for a web manifest's
  `any` purpose, and `avatar-1024.png`. Liquid Glass scales the native iOS
  Default export.
- **`favicon.svg`** is the style's SVG. For Liquid Glass it is the flat
  approximation on the Liquid Glass outline, without native materials.
- **Full-bleed images** have an opaque background and no mask or outer
  shadow, because the platform applies its own: `apple-touch-icon.png` at
  180 px and `maskable-512.png` for the `maskable` purpose. Gloss keeps its
  highlight. The maskable image scales the artwork square by at most 0.56,
  placing it within a circle of radius 0.4 times the canvas width. Inspect it
  with circular and rounded-square crops.

## Lint

`--lint` renders each group alone at 256 px in artwork coordinates and
reports:

- artwork of a clipped group outside the style's outline, beyond 0.5% of the
  group's coverage; groups covering 95% or more of the canvas are background
  layers and are exempt, and `mac-tile` `unclipped` groups are not checked;
- shapes narrower than 1 px when the icon is shown at 32 px, measured per
  8-connected shape from the widest point of a chessboard distance transform;
- mean OKLab lightness within 0.10 of the background, or of another group
  covering at least 1% of the smaller group's area;
- more than three groups.

When any layer in a group has a fill or appearance fill override, lint prints
an `info` line explaining that the Liquid Glass appearance comes from the
fill, and that the group's lightness findings concern artwork used by other
styles. Informational lines do not cause failure or suppress artwork findings.

The thresholds are this skill's heuristics for the guidance in
[design](design.md); a finding is fixed or recorded as an owner decision.

## Drift

`--check` regenerates the selected style into a temporary candidate and
compares the entire directory without writing into the target. It reports
`same`, `drift`, `missing`, and `extra`. PNGs are the same when their
decompressed payloads match, or when their decoded pixels have equal
dimensions and differ by at most 1 in every channel: Icon Composer 27
exports of one document can differ by 1/255 in a few pixels between runs.
SVG, document, and manifest comparisons are exact.

Record `design_generation` and use the same renderer when maintaining a fixed
appearance. A tool upgrade can legitimately change native or style
rendering; review the new sheet before replacing published assets. Never
mark a renderer failure, missing image, or unavailable native preview as
verified.

For a producer regression against a pre-change script, set
`APP_ICONS_BASELINE=/path/to/app_icons.py` when running `scripts/test_app_icons.py`.
The test generates every declared style of every `examples/DESIGN*.md` entry
with both versions. Legacy output must match byte-for-byte. Live native output
must match within the existing PNG tolerance. A second native build replays
actual baseline exports after checking identical document/assets and renderer
arguments, and requires all producer outputs to be byte-identical. This
separates producer regressions from GPU rounding; it does not claim that
independent native invocations always produce identical bytes.
