# Public presentation

## Copy and metadata

Start with the visitor's outcome, supported by current source, tests or CI.
Use an active sentence without hype or unmeasured superiority. Process terms
such as signing, provenance or independent versioning belong in standards
unless those are the repository's product. About, the README tagline and the
social-card summary use one accepted sentence. The Overview explains the
mechanism or distinction; Quick look demonstrates it. Each adds information.

Keep release versions and drifting membership, feature or performance counts
out of short copy. Measurements need reproducible scope and an owning source.
Topics describe current domains, inputs, outputs and ecosystem; package topics
apply to packages only. Read back the complete topic set and About fields after
publication. Set a homepage only after its destination works.

Do not hand-maintain membership-dependent banners, tables or counts. Route a
catalog or organization profile to the organization owner; generate membership
from its owned data and GitHub inventory with drift checks.

## README first screen

Apply the applicable DESIGN and documentation roles. Without a project design,
the documented default is a centered linked logo, name, outcome tagline,
applicable badges and a concise navigation row. Default sections are Overview,
Quick look, Install, Usage, Requirements, Documentation, Contributing, License;
adapt for the actual artifact instead of adding empty sections.

Badge order defaults to CI, language/toolchain, platforms, license. Show a
badge only if an actual workflow, supported requirement or license backs it.
Take badge values from the ecosystem's README skill when one applies; this
skill owns the selection, order, labels and styling.
Non-package repositories omit compiler/platform claims. Use accessible labels
and link each badge to its evidence. Logo sizes, hues and layout tokens come
from DESIGN when present; absent it, choose and document project defaults.
Icon construction belongs to the icon design owners.

Quick look depends on what the visitor uses:

- A library: a short working snippet showing the core result. Default to at
  most twelve lines; validate against current API and keep imports meaningful.
  An ecosystem README skill supplies and builds the snippet when one applies.
- A CLI: a real recorded session rendered as light/dark SVGs, selected with a
  `<picture>` using `prefers-color-scheme`. Record successful commands and
  representative output; build chatter and operator paths do not belong in it.
- Another artifact: the smallest accurate working example appropriate to it.

Keep recording provenance outside the README, with the recording or private
release evidence as appropriate. Explain how to reproduce in the owning
reference. The README demonstrates an outcome; it is not an execution ledger.

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
source and exports together, then upload those accepted bytes. The renderer
and byte checks do not replace visual review.
