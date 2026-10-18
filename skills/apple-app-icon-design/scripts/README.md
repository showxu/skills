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

`--lint` checks every style of the entry, or only `--style`, prints `clean`
or one tab-separated finding per line, and exits 1 on any finding. Material
fill notices use `info` lines and do not affect the exit status. `--sheet`
writes a new self-contained SVG comparing each named entry in each of its
styles at 160 and 32 px on light and dark backgrounds. Without an
export-capable `ictool`, its Liquid Glass cells say so. Convert it with
`rsvg-convert SHEET.svg -o SHEET.png` when a raster preview is needed.

Optional `--ictool PATH` selects an export-capable Icon Composer renderer.
Exit 0 means the requested output, comparison, lint, or sheet succeeded.
Invalid input, render failure, drift, or a lint finding exits 1. A successful
document-only run does not establish native rendition or visual readiness.

Run `python3 scripts/test_app_icons.py` for document, style, lint, drift,
preservation, dimension, and failure-path regressions. Rendering tests run
only when `rsvg-convert` is installed. Native material and appearance tests
run when export-capable `ictool` is available. Set `APP_ICONS_BASELINE` to a
pre-change `app_icons.py` to compare all example styles; see the exact-byte and
native-rounding distinction in [rendering](../references/rendering.md#drift).
Use native contact sheets for visual quality review.
