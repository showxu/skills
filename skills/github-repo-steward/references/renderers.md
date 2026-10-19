# Deterministic renderers

Use a repository-owned renderer when it implements the accepted standard.
Otherwise the helpers here provide portable rendering primitives. Run them
from the repository being served. Python 3 is required; social outlines need
`fonttools`. Raster icon validation and pixel verification use Pillow; PNG
conversion uses `rsvg-convert`. SVG CSS reference validation uses `tinycss2`.
Install dependencies in that repository's producer-owned ignored location,
not in the skill source or the owner's global environment.

## Project inputs

Resolve the project's actual DESIGN.md into a small JSON presentation recipe;
do not assume any particular token key paths. Set `design_source` to its path
and `design_sha256` to the reviewed file's digest. The helper rejects a stale
binding. Commit this mapping with the project's renderer inputs. If DESIGN is
absent, omit both fields and use or override the neutral defaults below.
Paths are relative to the recipe. Source paths, font choices, output paths and
all project colors are inputs. No fonts or project assets are bundled here.
If a font is bundled by the served project, include its redistribution license
and source/digest; the card recipe requires a license file for the chosen fonts.

Card recipe fields:

```json
{
  "owner": "example-owner",
  "title": "example-tool",
  "about": "Inspect your data before shipping it.",
  "icon": "assets/logo.svg",
  "font_title": "fonts/title.ttf",
  "font_body": "fonts/body.ttf",
  "font_license": "fonts/LICENSE.txt"
}
```

The literals above are example inputs only. Defaults: canvas 1280×640, padding
64, icon square 384, text start x=512, text width=704, owner 28 px, title range
72 down to 40 px in integer steps, title maximum two lines, About 32 px and at
most three lines with a 44 px line height. Default background is white, title
and owner black, summary dark gray. Override `background`, `ink`, `muted`,
`title_max`, `title_min`, `font_owner`, `owner_size`, `text_x`, `text_width`, `icon_size` and `padding`
with accepted DESIGN values. `font_owner` defaults to the body font; supply a
distinct face when DESIGN specifies one. Canvas and About size remain the card
contract. Unbreakable overflow fails instead of clipping or silently reducing type.

`icon` accepts a self-contained SVG or a PNG, JPEG or WebP image. Raster icons
must be square and at least `icon_size` pixels on each side (384 by default);
smaller inputs fail rather than being upscaled. The renderer embeds the file's
exact bytes in an `<image>` data URI at the same position and size as an SVG.
Standalone and embedded rasters are verified, then reopened and fully decoded,
including every animation frame, before their original bytes are embedded.

### SVG input allowlists

The root must be `svg` in `http://www.w3.org/2000/svg`, with a `viewBox` and
outlined lettering. Every retained element must use that namespace and appear
in the element allowlist below. Metadata contents, including foreign-namespace
children, are ignored and dropped from the output. Namespace declarations are
accepted; other namespaced attributes are rejected except `xlink:href` in
`http://www.w3.org/1999/xlink`.

| Elements | Allowed names |
| --- | --- |
| Structure and descriptions | `svg`, `g`, `defs`, `title`, `desc`, `metadata`, `symbol`, `use`, `image` |
| Geometry | `path`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon` |
| Paint and clipping | `linearGradient`, `radialGradient`, `stop`, `clipPath`, `mask`, `pattern` |
| Filters | `filter`, `feGaussianBlur`, `feOffset`, `feBlend`, `feColorMatrix`, `feComposite`, `feFlood`, `feMerge`, `feMergeNode`, `feMorphology`, `feDropShadow`, `feComponentTransfer`, `feFuncR`, `feFuncG`, `feFuncB`, `feFuncA` |

Only the following unprefixed attributes are accepted. `id` and `class` are
permitted because style elements are excluded.

| Attributes | Allowed names |
| --- | --- |
| Identity and geometry | `id`, `class`, `x`, `y`, `width`, `height`, `viewBox`, `preserveAspectRatio`, `transform`, `d`, `pathLength`, `rx`, `ry`, `cx`, `cy`, `r`, `x1`, `y1`, `x2`, `y2`, `points` |
| Paint servers and clipping | `gradientUnits`, `gradientTransform`, `spreadMethod`, `fx`, `fy`, `fr`, `offset`, `clipPathUnits`, `maskUnits`, `maskContentUnits`, `patternUnits`, `patternContentUnits`, `patternTransform` |
| Filter parameters | `filterUnits`, `primitiveUnits`, `in`, `in2`, `result`, `stdDeviation`, `dx`, `dy`, `mode`, `type`, `values`, `operator`, `k1`, `k2`, `k3`, `k4`, `radius`, `edgeMode`, `tableValues`, `slope`, `intercept`, `amplitude`, `exponent` |
| Presentation | `color`, `fill`, `fill-opacity`, `fill-rule`, `stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-dasharray`, `stroke-dashoffset`, `stroke-opacity`, `opacity`, `clip-path`, `clip-rule`, `mask`, `filter`, `marker`, `marker-start`, `marker-mid`, `marker-end`, `cursor`, `display`, `visibility`, `overflow`, `paint-order`, `vector-effect`, `color-interpolation`, `color-interpolation-filters`, `color-rendering`, `shape-rendering`, `image-rendering`, `stop-color`, `stop-opacity`, `flood-color`, `flood-opacity` |

`href` and `xlink:href` are permitted only on `use` and `image`. A `use` link
must be a same-document fragment. An `image` link must be a base64
`data:image/png`, `data:image/jpeg` or `data:image/webp` URI with a matching,
verified and decoded raster payload. Image links to fragments are rejected.

Every attribute value is checked for non-fragment `url()` references, including
CSS escapes and quoted URLs. `url()` accepts only literal fragments. Other
value functions are limited to `matrix`, `translate`, `scale`, `rotate`,
`skewX`, `skewY`, `calc`, `min`, `max`, `clamp`, `rgb`, `rgba`, `hsl`, `hsla`,
`hwb`, `lab`, `lch`, `oklab`, `oklch`, `color`, `color-mix`, `blur`, `brightness`,
`contrast`, `drop-shadow`, `grayscale`, `hue-rotate`, `invert`, `opacity`,
`saturate`, `sepia`, `circle`, `ellipse`, `inset`, `path`, `polygon`, `rect` and
`xywh`. Function names are case-insensitive.

All other elements and attributes are rejected, including style elements and
attributes, events, animation, live text, external filter inputs and foreign
namespaces outside discarded metadata. DOCTYPE/entity declarations and
processing instructions are rejected during parsing; XML declarations and
predefined/numeric character references are accepted.

### Render and check

```sh
python3 <skill>/scripts/render_social.py --spec <recipe.json> --output <card.svg>
rsvg-convert -w 1280 -h 640 <card.svg> -o <card.png>
python3 <skill>/scripts/render_social.py --spec <recipe.json> --output <card.svg> --check
```

The SVG uses glyph outlines. A sibling `.layout.json` records title/About
lines, actual font size, dimensions and input digests, including the icon file's
SHA-256 for either input type. `--check` compares both outputs and fails on drift
without writing. Inspect both output images.

## Terminal recording

Capture commands in a controlled directory with actual exit codes and stdout.
Retain stderr and failures in provenance where needed; do not fabricate output
or silently relabel a failed command as successful. A demonstration of an
expected error may be prepared by the repository's own renderer with an
explicitly reviewed error contract; this helper accepts successful sessions.
Normalize private paths explicitly before publication and preserve a private
receipt of what was normalized. Reject control sequences rather than rendering
unreadable escapes.

The recording has `title` and a nonempty `commands` list. Each command has
`command`, `stdout`, `exit_code` (zero). A separate provenance JSON records the
source revision, executable digest/version, input/dependency revisions and
digests, toolchain, original command exit codes and any normalization. Keep it
beside the recording or in private evidence, never in README prose.

Terminal recipe accepts `design_source`/`design_sha256`, `font_family`,
`font_size`, `line_height`, `padding`, `radius`, `title_height`, `min_width`,
and `light`/`dark` color objects. Color roles are `surface`, `bar`, `border`,
`prompt`, `command`, `output`, `dim`. Defaults are a portable monospace family,
14 px type/21 px lines, 20 px padding, 10 px radius, 34 px title bar and 560 px
minimum width with neutral grayscale themes. These are overridable defaults,
not a project's visual identity. Render width accounts for wide Unicode cells.

```sh
python3 <skill>/scripts/render_terminal.py --record <record.json> --spec <recipe.json> --output-dir <demo-dir>
python3 <skill>/scripts/render_terminal.py --record <record.json> --spec <recipe.json> --output-dir <demo-dir> --check
```

Outputs are `Demo-light.svg` and `Demo-dark.svg`. Commit recording, recipe and
exports together; use `--check` in the project's CI. Helpers never execute the
recorded commands and never upload. Build/test outputs stay in the producer's
ignored directory, reused across runs and removed after the task.
