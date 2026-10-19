# Public design

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
evidence.

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

The profile is organized by the reader's job, from the supplied promise, job
groups, ordering and catalog rows. The header carries the umbrella icon, the
promise, a secondary line and links to documentation, contributing, security
and support where they exist. Keep text as text, and place each repository's
icon next to its linked name and outcome sentence; the header umbrella can
stand alone. Review the served profile in light and dark.
