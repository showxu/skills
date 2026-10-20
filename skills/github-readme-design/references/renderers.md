# Deterministic renderers

## Toolchain

Terminal assets and DESIGN lint use the TypeScript package in `scripts/`,
with Node 24 at the exact version in `.node-version`. Node runs the erasable
TypeScript directly; there is no compiled distribution. `package-lock.json`
pins all dependencies. DESIGN is read through `@google/design.md/linter`
0.4.0: `lint(text)` must return zero errors and zero warnings; informational
findings are allowed. Diagnostics include the file, token path, rule and
message. The renderer consumes the resolved components and typography from
that parser. The official DTCG export remains available for other consumers;
it is not this renderer's input.

Consumers run the composite Action at a full commit SHA, or use a package copy
at that commit in their ignored build directory as described under
[local regeneration](#local-regeneration). Never install into an installed
skill directory or the global environment. In this skill's development
worktree, `npm ci && npm test` installs into ignored `scripts/node_modules`
and runs TypeScript checking and `node:test`. `npm run golden` deliberately
updates the golden SVGs; ordinary tests only compare them. The licensed font
in `scripts/test/fixtures/fonts/` is test data, not a default consumer font.

Social cards and organization profiles use the Python helpers below, or a
repository-owned renderer implementing the accepted standard. Python 3 is
required; social outlines need `fonttools`. Raster icon validation and pixel
verification use Pillow; PNG conversion uses `rsvg-convert`. SVG CSS reference
validation uses `tinycss2`. Install Python dependencies in the consumer's
producer-owned ignored location.

## Social card inputs

Resolve the project's actual DESIGN.md into a small JSON presentation recipe;
do not assume any particular token key paths. Set `design_source` to its path
and `design_sha256` to the reviewed file's digest. The helper rejects a stale
binding. Commit this mapping with the project's renderer inputs. If DESIGN is
absent, omit both fields and use or override the neutral defaults below.
Paths are relative to the recipe. Source paths, font choices, output paths and
all project colors are inputs. Consumer fonts and project assets are explicit inputs.
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

## Terminal

The asset directory contains `script.yml`, optional `fixture/`, generated
`recording.json`, `terminal-light.svg` and `terminal-dark.svg`. Commit these
inputs and outputs together under `.github/assets/terminal/`. README uses a
`<picture>` dark source and light fallback with an informative alt sentence.

### Script schema

```yaml
title: Inspect a workspace
executable: demo
env:
  EXAMPLE: fixture
files:
  project/README.md: |
    Shared guidance.
copy:
  - from: fixture/team-rules
    to: team-rules
steps:
  - run: git init --quiet --initial-branch=main && git add . && git commit --quiet -m "docs: add guidance"
    cwd: ~/team-rules
    show: false
  - run: demo inspect ~/team-rules
  - write: ~/project/review.md
    content: |
      Review code and tests.
  - run: demo review review.md
expect:
  - file: ~/project/review.md
    contains: Review code
  - file: ~/project/review.md
    equals: |
      Review code and tests.
```

The example's command and files are illustrative inputs. Use the product's
actual commands and assertions. Unknown keys, duplicate YAML keys, malformed
values and YAML aliases fail. `title`, a bare `executable` name, and `steps`
are required; at least one `run` step must be shown. `env`, `files`, `copy`
and `expect` are optional. Environment values and file contents are strings.

A `run` has a shell command, optional `cwd` (default `~/project`) and optional
boolean `show` (default true). A `write` has `write` and `content` and is always
hidden. Shown commands are single lines; hidden setup may be multiline.
Managed paths resolve inside the sandbox home, using `~/` or relative paths.
`copy.from` is relative to `script.yml` and must stay within its `fixture/`,
including symlink targets. `copy.to` is inside the sandbox home. Each `expect`
requires `file` and exactly one of `contains` or `equals`; `equals` compares
complete file content, including its final newline.

Copies require a fresh destination and create each descendant exclusively.
Managed copies and writes refuse existing destination symlinks at any depth,
including `~/bin/<executable>`, even when a link points inside home. Errors
name the offending path.
Expectation targets and existing managed-write targets must be regular files
as reported by `lstat`; FIFOs, directories and symlinks fail before opening.
Managed writes may create a new file.

### Recorder environment and recording

Before creating the sandbox, the recorder resolves `--executable` and checks
that it is an existing regular file with execute permission.
The recorder creates a fresh temporary home, `~/project`, `~/tmp`, and a
`~/bin/<executable>` symlink to the supplied built product. Commands execute
through `/bin/sh -c` with no inherited environment. This isolates the demo's
working files and environment; repository scripts remain trusted executable
code, not an OS security sandbox.

| Fixed key | Value |
| --- | --- |
| `HOME` | Temporary sandbox home |
| `PATH` | `~/bin:/usr/bin:/bin:/usr/sbin:/sbin` with the home path expanded |
| `TMPDIR` | Expanded `~/tmp` |
| `LC_ALL`, `TERM`, `NO_COLOR` | `C`, `dumb`, `1` |
| `GIT_CONFIG_NOSYSTEM`, `GIT_CONFIG_GLOBAL` | `1`, `/dev/null` |
| `GIT_TERMINAL_PROMPT`, `GIT_ALLOW_PROTOCOL` | `0`, `file` |
| `GIT_AUTHOR_NAME`, `GIT_COMMITTER_NAME` | `Demo` |
| `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_EMAIL` | `demo@example.invalid` |
| `GIT_AUTHOR_DATE`, `GIT_COMMITTER_DATE` | `2026-01-01T00:00:00Z` |

`env` adds keys and cannot override any fixed key. Every run must exit zero
with empty stderr within 120 seconds. Failures name the step, command, exit
code and stderr; timeouts terminate the process group. Assertions run after
the last step. The sandbox is removed after success, command failure,
assertion failure or timeout. SIGINT and SIGTERM are handled throughout sandbox
creation, fixture copying, managed writes, commands, expectation reads and
removal. A signal terminates any running command process group, waits for
pending filesystem work and removes the sandbox before exiting with status
130 (SIGINT) or 143 (SIGTERM).
Cleanup restores owner permissions on sandbox directories so restricted
directory modes do not prevent removal. It does not follow symlinks when
restoring permissions. If cleanup still fails, the diagnostic names the
offending path and the command exits nonzero.

Normalization replaces both the created and canonical home paths with `~`,
longest first, and removes exactly one trailing LF from each output. It makes
no other substitutions; fix varying dates, identities and inputs in the script.
Only shown steps enter the recording:

```json
{
  "title": "Inspect a workspace",
  "steps": [
    {
      "command": "demo inspect ~/team-rules",
      "output": "Shared guidance ready."
    }
  ]
}
```

Serialization is two-space JSON, ordered `title`, `steps`, and then `command`,
`output` in each step, with one trailing LF.

### Rendering rules

The renderer reads `terminal`, `terminal-frame`, `terminal-title-bar`,
`terminal-prompt`, `terminal-command` and `typography.terminal` from DESIGN.
The light appearance uses base components. Each `-dark` component overrides
only the properties it lists; other properties come from its base component.
Both appearances must have identical geometry and typography. Missing tokens
fail; terminal styling has no fallback recipe or neutral theme. Dimensions
must be `px`, and colors resolve to opaque six-digit hex.

Typography selects font files in `--fonts` by name ID 16 (preferred family),
falling back to name ID 1. A variable face must have a `wght` axis covering
`fontWeight` and every axis in `fontVariation`, each within range. A static
face matches only when `fontVariation` is absent and OS/2 `usWeightClass`
equals `fontWeight`. Exactly one face must match; otherwise the diagnostic
lists the candidates. `fontVariation` follows CSS settings syntax, such as
`"'MONO' 1"`; `wght` belongs only in `fontWeight`. Axis values use the
[CSS number grammar](https://drafts.csswg.org/css-values-4/#numbers): optional
signs, integer or decimal forms, and optional exponents (`1e0`, `+1`, `.5`).
A decimal point requires following digits.
The selected variation's cmap maps each character to one glyph; kerning,
ligatures and contextual alternates are not applied. Advance widths come
from those glyphs.

Tabs expand to the next multiple of eight cells, counting the `$ ` prompt
for commands. Other controls fail. A missing glyph names the character,
Unicode code point and step. A shown step has a `$ ` prompt in prompt color,
its command in command color and its output lines in terminal text color.
Empty output contributes no line. One empty line separates steps; there is
no extra separator after the final step.

With padding `p`, frame size `s`, corner radius `r` and title-bar height `bar`:

- Width is the ceiling of the maximum of `terminal.width`, title advance plus
  `2p`, and widest line advance plus `2p`. The maximum is **830 px**, the README
  column on github.com's repository page: a platform fact, not a DESIGN token.
  Overflow names the widest line for shortening; the renderer never scales
  down the text to fit.
- Height is `ceil(bar + 2p + lineCount × lineHeight)`.
- Frame and interior are fills, not strokes: the outer rounded rectangle is
  `(0, 0, W, H)` at radius `r`; the interior is `(s, s, W−2s, H−2s)` at radius
  `r−s`. The title-bar fill spans `y=s` to `bar−s` with rounded top corners and
  a straight lower edge. The separator is `(s, bar−s, W−2s, s)` in frame color.
- Title baseline is `(bar + capHeight)/2`, using OS/2 cap height at the selected
  font size; its x position is `(W−titleAdvance)/2`.
- Body text starts at `x=p`. For hhea ascent `A` and absolute descent `D`, both
  scaled to the font size, line `i` has baseline
  `bar + p + i×lineHeight + (lineHeight−(A+D))/2 + A`.

The SVG has `role="img"`, `<title>` and a `<desc>` containing the rendered
transcript joined by LF and XML-escaped. Every distinct nonempty glyph path
is defined once, sorted by glyph ID, in font-size pixels with its y axis
flipped. Runs place glyphs using SVG 2 `<use href>` with x and baseline y;
there are no live text elements, styles, transforms or external font lookups.
Element order is title, description, definitions, frame, interior, title bar,
separator, title run, then body runs in reading order. Numbers have at most
two decimals with no trailing zeros or negative zero. Hex colors are uppercase;
line endings are LF with one trailing newline. No timestamps or random IDs
enter the SVG. The same inputs produce the same bytes across macOS and Linux;
the package's CI matrix compares both against committed goldens.

## CI integration

The composite Action lives at
`showxu/skills/skills/github-readme-design/scripts@<full-40-character-sha> # vX.Y.Z`.
Pins are full commit SHAs with SemVer comments; version labels below are
placeholders to resolve to reviewed releases, not mutable references.

| Input | Meaning |
| --- | --- |
| `asset` | Required: `terminal` or `design` |
| `command` | Default `check`; terminal supports `check` and `render`, design supports `lint` |
| `design` | Required path to the applicable DESIGN.md |
| `fonts` | Organization fonts directory, required for terminal |
| `assets` | Terminal asset directory, required for terminal |
| `executable` | Built product, required for terminal |
| `artifact-dir` | Optional dedicated failure-artifact directory, separate from assets |

The Action sets up the Node version from its `.node-version`, installs with
`npm ci --omit=dev`, and runs `src/cli.ts`. `terminal/render` records and
renders into `assets`; `terminal/check` regenerates in a temporary directory
and compares recording and SVG bytes without overwriting committed files.
It reports changed commands pairwise by index, plus added and removed steps,
and prints a unified recording diff. When the recording matches but an SVG
differs, it names the file and says DESIGN or the renderer changed. On drift,
`artifact-dir` receives the complete commit-ready directory: `script.yml`,
`fixture/` if present, `recording.json` and both SVGs. Copy those files from the
CI artifact, review and commit them together. Exit codes are 0 for success,
1 for drift or validation failure and 2 for command usage errors.

### Organization standard and member caller

The pin chain is member → organization reusable workflow → toolchain Action.
The organization workflow at `.github/workflows/presentation.yml` accepts
`runner` (default `ubuntu-24.04`), `executable-artifact`, `executable-path`, and
`assets` (default `.github/assets`). It validates `job.workflow_sha`, checks
out the caller and its own standard repository at that exact workflow SHA,
downloads the built executable and restores its execute bit. DESIGN and fonts
come from that pinned standard, not a branch head. It calls the Action with
`asset: terminal`, the terminal subdirectory, and a dedicated artifact path;
on failure it uploads that directory as `presentation-terminal`. The runner
must match the OS that built the product. Organization DESIGN CI calls the
same Action with `asset: design`, `command: lint` and `design` so linting and
rendering share the parser lockfile.

A member uploads its build and references only the organization standard:

```yaml
jobs:
  build:
    runs-on: macos-26
    steps:
      # Checkout and build the product here.
      - uses: actions/upload-artifact@<full-40-character-sha> # vX.Y.Z
        with:
          name: executable
          path: .build/release/demo
  presentation:
    needs: build
    uses: example-org/.github/.github/workflows/presentation.yml@<full-40-character-sha> # vX.Y.Z
    with:
      runner: macos-26
      executable-artifact: executable
      executable-path: demo
```

The referenced repositories publish signed SemVer tags after reviewed merges;
consumers pin the corresponding commit and keep `# vX.Y.Z` comments for
Dependabot. Standard major versions change the workflow interface, minor
versions change DESIGN requiring regeneration, and patches preserve output.

### Local regeneration

From the consumer's task worktree, use its ignored build directory. Set the
commit to the full reviewed toolchain SHA selected by its pinned standard.
This downloads only the package at that commit, without a checkout or `.git`:

```sh
toolchain_commit='<full-40-character-sha>' # vX.Y.Z
toolchain_dir="$PWD/.build/presentation-toolchain"
mkdir -p "$toolchain_dir"
curl -fsSL "https://api.github.com/repos/showxu/skills/tarball/$toolchain_commit" \
  -o "$toolchain_dir/source.tar.gz"
archive_root="$(tar -tzf "$toolchain_dir/source.tar.gz" | sed -n '1s,/.*,,p')"
tar -xzf "$toolchain_dir/source.tar.gz" -C "$toolchain_dir" --strip-components=4 \
  "$archive_root/skills/github-readme-design/scripts"
tar -xzf "$toolchain_dir/source.tar.gz" -C "$toolchain_dir" --strip-components=1 \
  "$archive_root/LICENSE"
node --version # Must match the copied .node-version; use that runtime below.
npm ci --omit=dev --prefix "$toolchain_dir"
node "$toolchain_dir/src/cli.ts" terminal record \
  --script .github/assets/terminal/script.yml --executable .build/release/demo \
  --out .github/assets/terminal/recording.json
node "$toolchain_dir/src/cli.ts" terminal render \
  --recording .github/assets/terminal/recording.json --design .build/standard/DESIGN.md \
  --fonts .build/standard/design/fonts --out-dir .github/assets/terminal
node "$toolchain_dir/src/cli.ts" terminal check \
  --assets .github/assets/terminal --design .build/standard/DESIGN.md \
  --fonts .build/standard/design/fonts --executable .build/release/demo \
  --artifact-dir .build/presentation-artifact
```

Build the real product first and obtain the standard's DESIGN and fonts at
its pinned workflow revision. The example paths are consumer inputs; use its
actual ignored build, executable and standard font paths. Reuse the dedicated
package directory for a pin and replace its contents when changing pins.
Remove download, dependency and review outputs when no longer needed.

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
an organization-owned renderer directory, and record the
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
