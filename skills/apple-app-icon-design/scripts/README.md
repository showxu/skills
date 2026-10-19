# Commands

`app_icons.py` uses the Python standard library. Style renderings, web icons,
lint, and sheets need `rsvg-convert`; Liquid Glass exports also need macOS
and Icon Composer's native renderer. Supply output and temporary locations
that the producing repository ignores. Use `TMPDIR` for temporary work owned
by the caller.

```sh
python3 scripts/app_icons.py DESIGN.md --list
python3 scripts/app_icons.py DESIGN.md --name example-studio --lint
python3 scripts/app_icons.py DESIGN.md --name example-studio --name example-alt --sheet .build/concepts.svg
python3 scripts/app_icons.py DESIGN.md --name example-studio --style liquid-glass --out .build/icons/liquid-glass
python3 scripts/app_icons.py DESIGN.md --name example-studio --style flat --out .build/icons/flat
python3 scripts/app_icons.py DESIGN.md --name example-studio --style flat --check .build/icons/flat
python3 scripts/app_icons.py DESIGN.md --name example-studio --style liquid-glass --out .build/document --document-only
python3 scripts/app_icons.py --continuous-rect 312 412 400 200 100 100 40 40
python3 scripts/app_icons.py --grid-backdrop opacity=0.2 > layers/grid-flat.svg
```

`--style` selects one of the entry's styles and may be omitted when the entry
declares only one. `--out` requires a new directory and publishes it only
after the entire candidate succeeds. It never overwrites an existing output.
`--check` is read-only for its target, includes missing and extra files, and
returns 1 on any difference. Document-only output contains just the Liquid
Glass `.icon` document; use the same flag when checking that output.

Liquid Glass output holds `NAME.icon`, `renditions/` with 18 native exports,
`web/`, a contact sheet, and `manifest.json`. Other styles hold `NAME.svg`,
`web/`, a contact sheet, and `manifest.json`. The manifest records the style,
`native` or `style-rendering`, the renderer version, and the design
generation or geometry.

In `web/`, `favicon.svg`, `favicon-16.png`, and `favicon-32.png` are page
icons; `icon-192.png` and `icon-512.png` serve a web manifest's `any`
purpose; `maskable-512.png` serves `maskable`; `apple-touch-icon.png` is the
iOS home screen icon; `avatar-1024.png` suits profiles and listings.
`touch.svg` and `maskable.svg` are their sources.

Set `"web_dark": true` in the entry to add Liquid Glass dark web exports:
`web/dark/favicon-16.png`, `web/dark/favicon-32.png`,
`web/dark/icon-192.png`, `web/dark/icon-512.png`, and
`web/dark/avatar-1024.png`. Each comes from native iOS Dark, with its mask;
the existing default and full-bleed files are preserved. The option defaults
to false and has no effect on other styles or document-only output.

`--lint` checks every style of the entry, or only `--style`, prints `clean`
or one tab-separated finding per line, and exits 1 on any finding. Material
fill notices use `info` lines and do not affect the exit status. `--sheet`
writes a new self-contained SVG comparing each named entry in each of its
styles at 160 and 32 px on light and dark backgrounds. Without an
export-capable `ictool`, its Liquid Glass cells say so. Convert it with
`rsvg-convert SHEET.svg -o SHEET.png` when a raster preview is needed.

`--continuous-rect X Y WIDTH HEIGHT RADIUS [RADIUS RADIUS RADIUS]` takes no
DESIGN.md and prints SVG path data for a rectangle with continuous corners,
with one radius or four: top-left, top-right, bottom-right, bottom-left. Use it
to draw rounded rectangles in artwork. Corners whose departures overrun an
edge end early and a tangent cubic joins them; `info` lines on standard error
name each reduced radius and blended edge. See
[continuous rectangles](../references/rendering.md#continuous-rectangles).

`--grid-backdrop [KEY=VALUE ...]` also takes no DESIGN.md and prints the SVG
layer of a [grid backdrop](../references/design.md#grid-backdrop). Keys
override `lines` (comma-separated positions), `width`, `inset`, `radius`,
`turn`, and `opacity`; `grid_backdrop()` takes the same keywords.

Optional `--ictool PATH` selects an export-capable Icon Composer renderer.
Exit 0 means the requested output, comparison, lint, sheet, path data, or
backdrop succeeded. Invalid input, render failure, drift, or a lint finding exits 1. A
successful document-only run does not establish native rendition or visual
readiness.

Run `python3 scripts/test_app_icons.py` for document, style, lint, drift,
preservation, dimension, continuous-rectangle, backdrop, and failure-path
regressions. Rendering tests run only when `rsvg-convert` is installed. Native
material and appearance tests run when export-capable `ictool` is available.
They check fill, layer/group opacity, and group material specializations
across every appearance, plus the opt-in dark web set. Set `APP_ICONS_BASELINE` to a
pre-change `app_icons.py` to compare all example styles; see the exact-byte and
native-rounding distinction in [rendering](../references/rendering.md#drift).
Use native contact sheets for visual quality review.
