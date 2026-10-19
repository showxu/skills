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

## Organization profiles

`render_profile.py` produces `.github/profile/README.md` from the public
`.github/profile/catalog.json`, and `.github-private/profile/README.md` from
that same catalog plus member input. It uses only the Python standard library
and `presentation.py`. Generation is offline, deterministic UTF-8 with LF line
endings; `--check` compares exact bytes and never writes. Validation finishes
before writing. Links accept `https:` URLs or repository-relative paths, never
protocol-relative URLs, credentials, active schemes or control characters.
Text is escaped HTML text, not embedded Markdown or trusted HTML.

The runnable neutral inputs and golden outputs are under
`tests/fixtures/profile/`. Their placeholder hosts and synthetic revision are
fixtures, not live acceptance evidence.

### Catalog contract

The catalog owns these fields:

| Field | Value and owner |
| --- | --- |
| `organization` | `login` and display `name`, supplied by the organization |
| `promise`, `secondary` | Accepted visitor promise and secondary line |
| `mark` | Umbrella image URL or `{light, dark}` image URLs |
| `website` | Optional public website URL; member header otherwise links the public organization profile |
| `navigation` | Optional roles `documentation`, `contributing`, `security`, `support`; each has `label`, `url` |
| `groups` | Ordered array of `{title, repositories}`; each repository has `name`, `outcome`, `icon` |
| `maintainer` | Optional `{label, url}` public-profile closing line |
| `description` | Optional one-line organization account description expressing the promise; validated, never rendered |
| `quickstart` | Optional `{title, commands}` rendered on the public profile after the navigation as a heading and an `sh` code block; commands are single lines without code fences |

Each repository occurs once. Names identify repositories within the catalog's
organization. An `icon` is a URL or `{light, dark}` URLs for the logo shown in
that repository's README header; a repository without its own logo uses the
product it distributes. Groups contain at least one repository; an empty
catalog has an empty groups array. GitHub inventory supplies public,
non-archived membership except `.github`; the organization steward reconciles
it online rather than the renderer fetching or inventing members.

Catalog relative links are relative to `.github/profile/README.md`. Public
output preserves them. Member output resolves them against the pinned `.github`
revision: images use raw content URLs, other links use GitHub file URLs.
They must remain within that repository. Member maintenance links are relative
to `.github-private/profile/README.md`; use HTTPS links for shared `.github`
documents. The organization declares the document paths and labels.

### Member input contract

The member repository owns a small input, conventionally `profile/member.json`:

- `catalog`: `revision` (full 40-character commit SHA) and `sha256` of the exact
  catalog bytes downloaded from that revision of `.github`. Keep the fetched
  file in a producer-owned ignored directory and pass it with `--catalog`.
  Record the pin and digest, never fork the catalog into another maintained
  group/row list. The renderer checks the digest; the online steward verifies
  the file at the recorded revision and compares membership with current truth.
- `maintenance`: required roles `maintenance`, `versioning`, `settings`,
  `design`, each with the organization's declared `label` and `url`.
- `repositories`: object keyed by exact catalog repository name. Each value
  contains only `default_branch` (the declared nonempty GitHub default branch
  name), `workflow` (workflow filename, such as `validate.yml`, or `null`),
  and `releases` (`published`, `channel` or `none`). These release
  states respectively render a live latest-release badge, a Releases link or
  an em dash. They encode publication/channel facts, never a version or status.

Unknown fields, duplicate catalog members, and missing or extra operational
members fail. Input does not carry a status, copied group, outcome or policy.
Release badges sort published releases by date and include prereleases; drafts
are excluded. They link to the repository Releases page. See the
[Shields release badge parameters](https://shields.io/badges/git-hub-release).
The renderer includes the declared `default_branch` as an explicit CI badge
query parameter and filters the workflow evidence link to that branch. Branch
names are URL-encoded, including slashes and non-ASCII characters. The
organization steward verifies each declared default branch against GitHub,
checks workflows on the observed default branch, release presence, icon
resolution and public inventory; unreadable evidence stays
REVIEW. Badge values remain live and may be cached by their provider.

```sh
python3 <renderer-dir>/render_profile.py --catalog <catalog.json> --spec <profile-recipe.json> --output profile/README.md
python3 <renderer-dir>/render_profile.py --catalog <pinned-catalog.json> --member profile/member.json --spec <profile-recipe.json> --output profile/README.md
python3 <renderer-dir>/render_profile.py --catalog <pinned-catalog.json> --member profile/member.json --spec <profile-recipe.json> --output profile/README.md --check
```

Omit `--member` for public mode. Omit `--spec` only when the documented defaults
apply; otherwise use the DESIGN-bound recipe described above with the
[profile tokens](design.md#profile-tokens). Fetch the pinned catalog before CI
runs `--check`; do not silently substitute branch HEAD when a pin is unreadable.

### Vendoring shared renderers

Vendor `render_profile.py` and `presentation.py` beside the profile inputs in
an organization-owned renderer directory, using the same process as vendoring
`render_terminal.py` and `presentation.py` beside terminal inputs. Record the
source repository, full source commit, source paths, and SHA-256 of each copied
file in the consumer's existing source receipt. Copy accepted bytes, preserve
the source license, and verify those digests in consumer CI. A renderer update
is a reviewed pin/digest change with regenerated output and `--check`, not a
local layout fork. Keep the renderer pin distinct from the catalog pin and
DESIGN digest. Commit inputs, receipt and generated README together.

The output uses GitHub-supported HTML tables, anchors, headings and images;
`<picture>` switches declared light/dark images with a fallback. See GitHub's
[organization profile paths and private visibility requirement](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile)
and [theme-aware Markdown images](https://github.blog/changelog/2022-08-15-specify-theme-context-for-images-in-markdown-ga/).
Read both generated files for markup correctness and review actual served
light/dark appearances before publication. No renderer performs uploads.
