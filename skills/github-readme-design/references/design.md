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
- A CLI: a real recorded session rendered as light/dark SVGs, selected with a
  `<picture>` using `prefers-color-scheme`.
- An MCP server: the client configuration as a table of command and arguments
  or a code block, followed by the recorded session when it also ships a CLI.
- A plugin: the capabilities it adds and the host's install step.
- Another artifact: the smallest accurate working example appropriate to it.

## Social preview

Use a 1280×640 canvas, the accepted icon, owner label, title and complete About
sentence. Derive colors and fonts from DESIGN. If absent, the bundled renderer
has documented neutral defaults. Keep font rights and licenses with bundled
fonts; do not copy a system font into artwork without permission.

Title fitting first shrinks toward a stated minimum on one line. Only when
that fails, wrap at hyphen or slash boundaries and balance line widths. Treat
adjacent separators as a run; a line must not consist of a prefix plus a
trailing hyphen while the next begins with a slash. Do not truncate a title or
invent a literal-name exception. A line break replaces the whole separator
run; the receipt retains the exact original title. Fail and revise the composition if no legible
fit exists. About stays at 32 px, at most three lines; never drop words or
shrink it to conceal overflow. Outline social-card lettering so font lookup
cannot change published rendering. The helper's layout receipt records the
actual lines and sizes for review.

Review exact SVG/PNG exports in light and dark and in the reported browser.
Equivalent geometry can render differently across engines. Merge accepted
source and exports together; the uploaded preview is exactly those accepted
bytes. The renderer and byte checks do not replace visual review.

## Organization profile

The public profile is organized by the reader's job, from the supplied catalog's
promise, job groups, ordering and rows. Center the header: umbrella icon,
promise heading, secondary line, then documentation, contributing, security
and support links where declared. Each row places the repository's README
header icon beside its linked name and outcome sentence. A distribution
repository uses the product icon when it has no logo of its own. An optional
quick start (a heading and shell commands) follows the navigation, and an
optional maintainer line closes the profile; both come from input. Keep text
as text.

The member profile is the maintainers' entry. In order, render a smaller
umbrella mark, `<organization display name> maintainer dashboard`, and one line
linking the public website or public profile; maintenance navigation from the
member input; repositories in the public catalog's job groups and order; and
organization-wide searches for open pull requests, open issues and Dependabot
pull requests. Every repository row carries its icon and linked name, a live
badge for its declared CI workflow on the default branch (or an Actions link),
and a latest-release badge for a release publisher, a Releases link for an
unused release channel, or an em dash for no release channel.

Use the shared [profile renderer](renderers.md#organization-profiles) for both
surfaces. The member input supplies maintenance links and each repository's
`default_branch`, CI workflow and release facts;
it does not duplicate catalog rows, policy or manually recorded status. Treat
all dashboard content as shareable with any member: no credentials, private
paths or unpublished plans. The shared standard remains linked in `.github`.

### Profile tokens

Resolve these named tokens from the accepted DESIGN when present into the
profile recipe, with its DESIGN path and digest. These are recipe names, not
assumed key paths in an arbitrary DESIGN file. Record defaults when DESIGN is
silent.

| Token | Default | Meaning |
| --- | --- | --- |
| `public_header_icon_size` | 128 px | Public umbrella mark square |
| `member_header_icon_size` | 64 px | Member umbrella mark square |
| `public_row_icon_size` | 40 px | Public repository icon square |
| `member_row_icon_size` | 24 px | Member repository icon square |
| `badge_style` | `flat` | Badge style under the Badges rules above |

Sizes are positive integer pixels. Badge styles are the supported Shields
styles: flat, flat-square, plastic, for-the-badge or social. Review both served
profiles in light and dark. Use HTML tables for rows and `<picture>` with a
dark `<source>` and fallback `<img>` when input declares both appearances.
Do not put Markdown syntax inside HTML tables or depend on CSS, scripts, inline
SVG, or embedded fonts in GitHub's renderer.
