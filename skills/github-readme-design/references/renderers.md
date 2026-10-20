# Deterministic renderers

## Toolchain

Terminal, social-preview and profile assets and DESIGN lint use the TypeScript
package in `scripts/`, with Node 24 at the exact version in `.node-version`. Node runs the erasable
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
worktree, `npm ci --ignore-scripts && npm test` installs into ignored `scripts/node_modules`
and runs TypeScript checking and `node:test`. `npm run golden` deliberately
updates the golden terminal SVGs and social-preview PNG; ordinary tests only
compare them. The licensed font in `scripts/test/fixtures/fonts/` is test data,
not a default consumer font.

## Social preview

The toolchain renders `.github/assets/social-preview/social-preview.png` from
DESIGN, the organization catalog, a selected repository and its light-page
icon. The card's owner is `organization.login`; title and About come from the
repository's `title` and `about`. `--repository .github` uses the organization's
`name` and `about`. Nothing is fetched during rendering.

DESIGN components `social-preview`, `social-preview-owner`,
`social-preview-about` and `social-preview-gap` own all styling. The first
three reference typography `social-preview-title`, `social-preview-owner` and
`social-preview-body`. Font selection and one-character-to-one-glyph outlining
follow the terminal rules below, with each typography's weight and variation.
Each social typography entry must declare `fontVariation` and select a variable
font; a missing declaration fails with the token named.
Missing components, typography or dimensions fail; there are no fallback styles.
Fonts are explicit inputs; keep their source and redistribution license with
any bundled font files.

The canvas is 1280×640, a GitHub platform constant, filled with
`social-preview.backgroundColor`. The icon is a square of `social-preview.size`
at `x = social-preview.padding`, vertically centered. The text starts after
that square plus `social-preview-gap.width` and ends one padding from the
right edge. Owner, title and About use their component text colors.

Title fitting tries one line at its DESIGN font size, decreasing in 1 px steps
to the 40 px legibility floor. If none fits, it replaces one hyphen/slash
separator run with a line break, choosing balanced widths at the largest
fitting size, at most two lines. It never truncates or breaks arbitrary letters.
About wraps at word boundaries at its DESIGN font size, at most three lines;
an unbreakable word or fourth line fails. The owner must fit on one line.

The text block contains the owner's line height, a `social-preview-gap.height`
gap, title line heights, the same gap and About line heights. Title line height
scales with its fitted size. The block is vertically centered and must fit
inside the padded canvas. Each baseline is at the bottom of its line box,
preserving the card composition. Geometry and overflow errors identify the
input or token; change the owning input rather than clipping the output.

`@resvg/resvg-wasm` 2.6.2 rasterizes the internal outlined SVG with no fonts
loaded. Output is 1280×640, 8-bit RGBA PNG, with no text or timestamp chunks.
Only the consumed PNG is committed. The internal SVG is not an output artifact.
The same pinned renderer and inputs are checked against a byte golden on
macOS and Linux.

Icons accept single still PNG, JPEG or WebP raster images, square and at least
the rendered icon size, or a self-contained SVG under the allowlist below.
Pinned `@jsquash/png`, `@jsquash/jpeg` and `@jsquash/webp` WebAssembly decoders
fully decode every raster before embedding. Decoder warnings and recovered
errors reject the input with its file named. APNG and animated WebP fail with
the icon file named, including when embedded in SVG. PNG/JPEG bytes are embedded
as data URIs; WebP uses a lossless internal PNG because this resvg version does
not decode WebP.
The rasterizer resamples the image at the specified size. SVG images have their
own document scope so icon IDs cannot collide with card glyph IDs.

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
node <toolchain>/src/cli.ts social-preview render --design <DESIGN.md> --fonts <dir> --catalog <catalog.json> --repository <name> --icon <logo.png> --out .github/assets/social-preview/social-preview.png
node <toolchain>/src/cli.ts social-preview check --design <DESIGN.md> --fonts <dir> --catalog <catalog.json> --repository <name> --icon <logo.png> --assets .github/assets/social-preview --artifact-dir .build/social-preview-artifact
```

`check` compares PNG bytes without overwriting the committed file. On drift it
names the output, prints a regeneration command and optionally copies the
regenerated PNG to a separate dedicated artifact directory. Review that exact
PNG at 1× and link-preview size; byte checks do not establish visual acceptance.
Only pixel changes affect the rendered PNG; icon metadata is not carried into
it. Settings uploads remain with the caller.

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
transcript joined by LF and XML-escaped. In `<title>` and `<desc>`, each space
in a U+0020 run immediately before LF or the end of the text is encoded as
`&#32;`, preserving the parsed text. Every distinct nonempty glyph path
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
| `asset` | Required: `terminal`, `social-preview`, `profile` or `design` |
| `command` | Default `check`; assets support `check` and `render`, design supports `lint` |
| `design` | Required path to the applicable DESIGN.md |
| `fonts` | Organization fonts directory, required for terminal and social-preview |
| `assets` | Terminal or social-preview asset directory in the caller |
| `executable` | Built product, required for terminal |
| `catalog` | Organization catalog, required for social-preview and profile |
| `repository`, `icon` | Catalog repository selector and local light-page icon, required for social-preview |
| `mode` | Profile mode: `public` (default) or `member` |
| `member` | Operational JSON input, required for member profile |
| `catalog-revision` | Full standard commit SHA, required for member profile; rejected in public mode |
| `output` | Profile file (default `profile/README.md`) or social-preview render file (defaults to `assets/social-preview.png`) |
| `artifact-dir` | Optional dedicated failure-artifact directory, separate from the checked output |

The Action sets up the Node version from its `.node-version`, installs with
`npm ci --ignore-scripts --omit=dev`, and runs `src/cli.ts`. `terminal/render` records and
renders into `assets`; `terminal/check` regenerates in a temporary directory
and compares recording and SVG bytes without overwriting committed files.
It reports changed commands pairwise by index, plus added and removed steps,
and prints a unified recording diff. When the recording matches but an SVG
differs, it names the file and says DESIGN or the renderer changed. On drift,
`artifact-dir` receives the complete commit-ready directory: `script.yml`,
`fixture/` if present, `recording.json` and both SVGs. Copy those files from the
CI artifact, review and commit them together. Exit codes are 0 for success,
1 for drift or validation failure and 2 for command usage errors.
Social-preview drift artifacts contain the regenerated PNG; profile artifacts
contain the regenerated Markdown file. Public profile mode rejects member input
and a catalog revision. All Action values reach the shell through environment
variables and quoted arguments.

### Organization standard and member caller

The pin chain is member → organization reusable workflow → toolchain Action.
The organization standard owns two reusable workflows. Each validates
`job.workflow_sha`, checks out the caller and its own standard repository at
that exact SHA without persisted credentials, and takes DESIGN, fonts and the
catalog from the pinned standard, never from a branch head.

`.github/workflows/presentation.yml` accepts `runner` (default
`ubuntu-24.04`), `executable-artifact`, `executable-path` and `assets`
(default `.github/assets`). It derives the caller's expected assets from its
catalog `kind`, following
[assets by product kind](design.md#assets-by-product-kind):

| Caller | Checked assets |
| --- | --- |
| `tool` | `terminal`, `social-preview` |
| `library`, `app`, `distribution`, the organization's `.github` | `social-preview` |
| `website` | none; calling the workflow fails |

A caller owned by another account or missing from the catalog, a missing
expected asset directory, a `terminal` directory for a kind without terminal,
and executable inputs missing for a tool or given for any other kind fail.
The social preview icon is the catalog entry's light-page image (the catalog
`mark` for `.github`). Its URL must be exactly
`https://raw.githubusercontent.com/<organization>/<repository>/HEAD/<path>`,
with no query or fragment and a relative path without `..` segments. A
`<repository>` equal to the caller resolves to that file in the caller,
`.github` to that file in the pinned standard; any other host, owner,
repository or ref, and a missing file, fail with the URL named. For a tool the workflow downloads the built executable
and restores its execute bit; the runner must match the OS that built the
product. On failure it uploads `presentation.tar` as the artifact
`presentation`, laid out like the asset root (`terminal/`, `social-preview/`)
with modes and hidden files kept; extract it there, review and commit.

`.github/workflows/profile.yml` accepts `mode` (default `public`), `member`
(default `profile/member.json`) and `output` (default `profile/README.md`) and
checks the caller's generated profile, as described in
[organization profiles](#organization-profiles). It rejects an unknown `mode`
before any checkout, and `member` and `output` must be caller-relative paths
without `..` segments, so the check cannot read another checkout. On drift it
uploads the regenerated file as the artifact `profile`. The `.github` repository calls
both workflows locally; a `.github-private` repository calls `profile.yml` in
member mode from a job named `check`, so its context is `check / profile`.
Organization DESIGN CI calls the Action with `asset: design`, `command: lint`
and `design` so linting and rendering share the parser lockfile.

A tool uploads its build and references only the organization standard:

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

A library, app or distribution calls it without executable inputs:

```yaml
jobs:
  presentation:
    uses: example-org/.github/.github/workflows/presentation.yml@<full-40-character-sha> # vX.Y.Z
```

The member dashboard calls the profile workflow:

```yaml
jobs:
  check:
    uses: example-org/.github/.github/workflows/profile.yml@<full-40-character-sha> # vX.Y.Z
    with:
      mode: member
```

The referenced repositories publish signed SemVer tags after reviewed merges,
choosing each version by their own `VERSIONING.md`; consumers pin the
corresponding commit and keep `# vX.Y.Z` comments for Dependabot. A changed
shared workflow or toolchain advances through representative consumers at the
exact candidate commit before tags and pin updates, covering every changed
path: a change to the tool path needs a tool's run, which downloads its
executable and checks its terminal
([organization release](../../github-org-steward/references/release.md)).

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
npm ci --ignore-scripts --omit=dev --prefix "$toolchain_dir"
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

`profile render` produces the public `.github` repository's `profile/README.md`
from its catalog and DESIGN. Member mode adds the dashboard repository's
operational input and the pinned catalog revision. Generation is offline,
deterministic UTF-8 with LF line endings. `profile check` compares exact bytes
without overwriting the output; validation finishes before any output is written.

The neutral inputs and unchanged public/member parity goldens live under
`scripts/test/fixtures/profile/`. Placeholder hosts and the synthetic revision
are test inputs, not live acceptance evidence.

### Shared catalog contract

The catalog module validates both social-preview and profile inputs once per
command. Unknown fields, duplicate JSON keys and case-insensitive duplicate
repository names fail. Required fields:

| Field | Meaning |
| --- | --- |
| `organization` | `login`, display `name` and the organization's repository `about` sentence |
| `promise`, `secondary` | Accepted visitor promise and secondary line |
| `mark` | Umbrella image URL or `{light, dark}` image URLs |
| `navigation` | Roles `documentation`, `contributing`, `security`, `support`, each optional with `label`, `url` |
| `groups` | Ordered `{title, repositories}` groups; each group has a nonempty repository array |
| Repository | `name`, `outcome`, `icon`, `kind`, `title`, `about` |

Repository `kind` is `tool`, `library`, `app`, `distribution` or `website`.
`title` and `about` supply the social preview; they do not add profile markup.
The organization repository is implicit and cannot be a group member, nor can
`.github-private`. Empty catalogs use an empty `groups` array. Icons use the
repository README header logo; distributions can use their product's icon.

Optional catalog fields:

- `website`: public website URL; the member header otherwise links to the
  public organization profile.
- `maintainer`: `{label, url}` public-profile closing line.
- `description`: one-line organization account description, validated but not
  rendered.
- `quickstart`: `{title, commands}`, rendered only on the public profile after
  navigation. Commands form a nonempty array of single lines without code fences.

Text is escaped HTML text, not embedded Markdown or trusted HTML. Links accept
HTTPS or repository-relative paths, never protocol-relative URLs, credentials,
active schemes, controls or paths escaping the repository. Catalog relative
links are relative to `.github/profile/README.md`; public output preserves them.
Member output resolves them against `--catalog-revision`, using raw content
URLs for images and GitHub blob URLs for other links. Member maintenance links
are relative to `.github-private/profile/README.md`; use HTTPS for shared docs.

### DESIGN and member inputs

The `size` properties of `profile-header`, `profile-member-header`, `profile-row`
and `profile-member-row` are required positive integer px dimensions. The badge
style is the renderer constant `flat`. Profile order, escaping, table markup,
`<picture>` behavior and final newline are covered by byte-parity goldens.

Member JSON contains only:

- `maintenance`: required `maintenance`, `versioning`, `settings` and `design`
  roles, each with declared `label` and `url`.
- `repositories`: object keyed by each exact catalog repository name. Each
  entry contains `default_branch` (nonempty), `workflow` (a `.yml`/`.yaml`
  filename or null) and `releases` (`published`, `channel` or `none`). These
  render a live latest-release badge, Releases link or em dash respectively.

Missing or extra operational members fail. CI badge URLs explicitly include
and encode each declared default branch. Release badges sort by date and include
prereleases. The renderer does not fetch live status; the organization's online
observations verify default branches, workflow existence, releases, inventory
and icons. Unreadable evidence remains REVIEW.

```sh
node <toolchain>/src/cli.ts profile render --design <DESIGN.md> --catalog <catalog.json> --out profile/README.md
node <toolchain>/src/cli.ts profile render --design <DESIGN.md> --catalog <catalog.json> --member profile/member.json --catalog-revision <full-40-hex-sha> --out profile/README.md
node <toolchain>/src/cli.ts profile check --design <DESIGN.md> --catalog <catalog.json> --member profile/member.json --catalog-revision <full-40-hex-sha> --out profile/README.md --artifact-dir .build/profile-artifact
```

The organization reusable `profile.yml` checks out the catalog and DESIGN at
`job.workflow_sha` and supplies that same SHA as `catalog-revision` in member
mode. Consumers pin the workflow by full SHA with a version comment. This one
pin selects the inputs and the transitive toolchain version. Local invocations
must supply that same standard revision explicitly. Public mode omits both
member input and catalog revision.

The output uses GitHub-supported HTML tables, anchors, headings and images;
`<picture>` switches declared light/dark images with a fallback. See GitHub's
[organization profile contract](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile)
and [theme-aware images](https://github.blog/changelog/2022-08-15-specify-theme-context-for-images-in-markdown-ga/).
Review actual served profiles in light and dark before publication. No renderer
performs uploads.
