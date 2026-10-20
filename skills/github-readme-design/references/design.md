# README and profile design

Lay out the supplied information with the applicable DESIGN and
documentation roles. Where DESIGN is silent, choose and document project
defaults. The README layout here covers libraries, CLIs, MCP servers and
plugins, and [app design](design-apps.md) covers apps. Badges, social preview
and review apply to every product kind, and the organization profile layout
is at the end.

## README first screen

Without a project design, the documented default is a centered linked logo,
name, outcome tagline, applicable badges and a concise navigation row. Default
sections are Overview, Quick look, Install, Usage, Requirements, Documentation,
Contributing, License; adapt for the actual artifact instead of adding empty
sections. Logo sizes, hues and layout tokens come from DESIGN when present.
Icon construction belongs to the icon design owners.

## Badges

Badge order defaults to CI, language/toolchain, platforms, license. Show a
badge only if an actual workflow, supported requirement or license backs it.
Badge values come from their information owners; this skill owns the
selection, order, labels and styling. Non-package repositories omit
compiler/platform claims. Use accessible labels and link each badge to its
evidence. Use DESIGN's `badge_style` when declared; otherwise use `flat`. Keep
status and release values live rather than writing results into labels.

## Quick look form

- A library: a short working snippet showing the core result. Default to at
  most twelve lines; keep imports meaningful. An ecosystem README skill
  supplies and builds the snippet when one applies.
- A CLI: a scripted session at `.github/assets/terminal/script.yml`,
  re-recorded in CI against the freshly built product and rendered as
  light/dark SVGs. Use the `<picture>` markup below.
- An MCP server: the client configuration as a table of command and arguments
  or a code block, followed by the recorded session when it also ships a CLI.
- A plugin: the capabilities it adds and the host's install step.
- Another artifact: the smallest accurate working example appropriate to it.

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/terminal/terminal-dark.svg">
  <img alt="<one sentence describing the session>" src=".github/assets/terminal/terminal-light.svg">
</picture>
```

See [renderers](renderers.md) for recording, rendering and CI commands.

## Assets

Use one directory per asset kind under `.github/assets/`, with lowercase
kebab-case names and `-light`/`-dark` appearance suffixes:

| Kind | Directory | Files |
| --- | --- | --- |
| logo | `.github/assets/logo/` | `logo-light.png`, `logo-dark.png` |
| social-preview | `.github/assets/social-preview/` | `social-preview.png` |
| terminal | `.github/assets/terminal/` | `script.yml`, optional `fixture/`, `recording.json`, `terminal-light.svg`, `terminal-dark.svg` |
| screenshots | `.github/assets/screenshots/` | `script.yml`, `capture.json`, `<scene>-light.png`, `<scene>-dark.png` |

### Assets by product kind

| Kind | logo | social-preview | terminal | screenshots |
| --- | --- | --- | --- | --- |
| tool (CLI) | yes | yes | yes | no |
| library | yes | yes | no | no |
| app | yes | yes | no | yes |
| distribution (tap) | uses the distributed product's icon | yes | no | no |
| organization `.github` | profile assets | yes | no | no |
| website | uses the organization icon | n/a | no | no |

Use the supplied product kind and icon selection with the applicable DESIGN.
Organization variants belong in its DESIGN and per-repository selections in
its catalog; a standalone repository uses its own metadata.

### Asset principle

Every asset kind follows script → capture → render. CI regenerates what it
can reproduce and compares the result. Assets that require native local tools,
such as Liquid Glass exports from Icon Composer on macOS, and screenshots CI
cannot capture are committed with a provenance receipt. Commit consumed
README images, profile output and the social-preview PNG; retain
`recording.json` for readable review diffs.

| Kind | Script | Capture | CI |
| --- | --- | --- | --- |
| terminal | `script.yml` | run commands in a sandbox → `recording.json` | regenerate, byte compare |
| social-preview | DESIGN + catalog | none | regenerate, byte compare |
| logo | DESIGN icon entry | native export, receipt | compare to exports at the pinned standard |
| screenshots | `script.yml` naming UI-test scenes | UI test capture, `capture.json` | regenerate with tolerance where CI can run it, else verify receipt |

### Screenshots

Each scene in `script.yml` names a UI test, device, appearance and locale. The
driving code lives in the product's UI tests. Capture results are recorded in
`capture.json`; final images add the DESIGN-defined background and frame.
App Store screenshot sets belong to `app-store-screenshots` and may reuse the
captures. Video is outside this asset contract because README video plays only
from GitHub-hosted uploads.

## Social preview

Use a 1280×640 canvas, the accepted icon, owner label, title and complete About
sentence. The toolchain reads colors, fonts, sizes and spacing from the
applicable DESIGN components; missing values must be resolved by that owner.
Keep font rights and licenses with bundled fonts; do not copy a system font into artwork without permission. Raster icons
are single still images; APNG and animated WebP fail with the file named.

Title fitting first shrinks toward a stated minimum on one line. Only when
that fails, wrap at hyphen or slash boundaries and balance line widths. Treat
adjacent separators as a run; a line must not consist of a prefix plus a
trailing hyphen while the next begins with a slash. Do not truncate a title or
invent a literal-name exception. A line break replaces the whole separator
run; the catalog retains the exact original title. Fail and revise the
composition if no legible fit exists. About stays at its DESIGN font size, at
most three lines; never drop words or shrink it to conceal overflow. Outline social-card lettering so font lookup
cannot change published rendering. The toolchain rasterizes the internal SVG
to the consumed PNG; review that exact export.

Review the exact PNG at 1× and at link-preview size in the reported browser.
Equivalent geometry can render differently across engines. Merge accepted
source and exports together; the uploaded preview is exactly those accepted
bytes. The renderer and byte checks do not replace visual review.

## Organization profile

The public profile is organized by the reader's job, from the supplied catalog's
promise, job groups, ordering and rows. Center the header: umbrella icon,
promise heading, secondary line, then documentation, contributing, security
and support links where declared. Each row places the repository's README
header icon in its own cell, then the linked name in bold above its outcome
sentence, so names never wrap beneath the icon in GitHub's narrow profile
column. A distribution repository uses the product icon when it has no logo
of its own. An optional quick start (a heading and shell commands) follows
the navigation, and an optional maintainer line closes the profile; both come
from input. Keep text as text.

The member profile is the maintainers' entry. In order, render a smaller
umbrella mark, `<organization display name> maintainer dashboard`, and one line
linking the public website or public profile; maintenance navigation from the
member input; repositories in the public catalog's job groups and order; and
organization-wide searches for open pull requests, open issues and Dependabot
pull requests. Every repository row carries its icon in its own cell, its
linked name, a live badge for its declared CI workflow on the default branch
(or an Actions link),
and a latest-release badge for a release publisher, a Releases link for an
unused release channel, or an em dash for no release channel.

Use the shared [profile renderer](renderers.md#organization-profiles) for both
surfaces. The member input supplies maintenance links and each repository's
`default_branch`, CI workflow and release facts;
it does not duplicate catalog rows, policy or manually recorded status. Treat
all dashboard content as shareable with any member: no credentials, private
paths or unpublished plans. The shared standard remains linked in `.github`.

### Profile tokens

The toolchain reads the `size` property of these DESIGN components. Each must
resolve to a positive integer px dimension; missing values fail.

| Component | Meaning |
| --- | --- |
| `profile-header` | Public umbrella mark square |
| `profile-member-header` | Member umbrella mark square |
| `profile-row` | Public repository icon square |
| `profile-member-row` | Member repository icon square |

Profile badges use the renderer constant `flat`. Review both served profiles in
light and dark. Use HTML tables for rows and `<picture>` with a dark `<source>`
and fallback `<img>` when input declares both appearances.
Do not put Markdown syntax inside HTML tables or depend on CSS, scripts, inline
SVG, or embedded fonts in GitHub's renderer.
