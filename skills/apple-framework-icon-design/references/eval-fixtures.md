# Behavior Fixtures

Use skill-creator's eval and review flow. Turn these cases into run inputs
with concrete fixture files; keep assertions outside executor inputs. Store
transcripts, generated icons, contact sheets, and grading in the caller's
local run directory.

These cases test the workflow under explicit invocation. They do not
establish automatic selection or the visual quality of any one icon.

## SI-01 — New member joins an existing family

- Prompt: Add an icon for a new command-line tool repository to the
  organization's family.
- Context: A `DESIGN.md` with eight icons whose hues cluster between 30 and
  200; the new tool formats source code.
- Expected artifact: One new Iconography entry, a rendered SVG and PNG, a
  contact sheet with the whole family, and a drift report.
- Must preserve: Existing entries byte for byte; shared geometry; the
  upright rule for a readable glyph.
- Failure: Editing generated SVGs by hand, reusing a neighbor's hue without a
  distinct ramp, adding text to the icon, or changing global constants.
- Acceptance: The new hue sits in the widest gap; `--check` reports `same`
  for the eight existing logos.

## SI-02 — Drift after a hand edit

- Prompt: Check whether the checked-in logos still match the design file.
- Context: One repository's `Logo.svg` was recolored by hand; its entry is
  unchanged.
- Expected artifact: A drift report naming that repository and file, with
  the others `same`.
- Must preserve: The hand-edited file until the owner decides.
- Failure: Silently regenerating over the edit, or updating the entry to
  match the hand edit without asking.
- Acceptance: Exit status 1, one `drift` line, and a question asking whether
  to regenerate or adopt the change into the entry.

## SI-03 — Request to imitate a product logo

- Prompt: Make the integration package's icon use the vendor's logo on the
  face.
- Context: The package wraps a third-party command-line product.
- Expected artifact: An entry using a generic glyph that says what the
  package does, optionally with a palette inspired by the vendor's colors.
- Must preserve: The rule against including, modifying, or imitating another
  company's logo.
- Failure: Tracing the vendor mark, approximating its silhouette, or
  embedding its image.
- Acceptance: The glyph is a library or original path, and the report states
  why the vendor mark was not used.

## SI-04 — Family without a DESIGN.md

- Prompt: Give our three repositories matching icons.
- Context: No `DESIGN.md` exists; repositories are a parser, a CLI, and a
  documentation site.
- Expected artifact: A new `DESIGN.md` started from the example with real
  tokens only, three entries, rendered icons, and a contact sheet.
- Must preserve: DESIGN.md section order; no invented brand tokens beyond
  what the icons and pages use.
- Failure: Copying the example's placeholder tokens unchanged, or writing
  icon parameters outside the Iconography block.
- Acceptance: `npx @google/design.md lint` reports no errors and
  `design_icons.py --list` prints the three names.

## SI-05 — Boundary: social preview request

- Prompt: Make a social preview card for the repository using its icon.
- Context: The repository already has a `Logo.svg`.
- Expected artifact: A statement that card composition is outside this
  skill, plus the icon's glow tint from `--tints` if useful to the caller.
- Must preserve: The logo file unchanged.
- Failure: Redrawing the icon inside a card layout or generating card text.
- Acceptance: No icon or entry changes.

## SI-06 — Tile member in a tile family

- Prompt: Add an icon for the new chart-rendering library; our family uses
  front-facing tiles.
- Context: A `DESIGN.md` whose entries are `volumetric` and `flat`, one with
  `face: "light"` and panels.
- Expected artifact: One new tile entry with a free hue, rendered icons, and
  a contact sheet of the whole family.
- Must preserve: The family's tile shape; existing entries byte for byte.
- Failure: Adding a stacked entry to a tile family, using `blocks` or
  standing objects on a tile, or tracing a reference icon's artwork.
- Acceptance: `--check` reports `same` for existing logos, and the new entry
  is legible at 40 px on both backgrounds.

## SI-07 — Generator change with fidelity check

- Prompt: Make the slab corners rounder.
- Context: The owner has a reference directory of framework icons.
- Expected artifact: A report that corner scale is a shared constant, the
  `--fidelity` figures before and after a proposed change, and the drift
  every existing logo would show.
- Must preserve: Per-icon entries; the recorded figures until the owner
  accepts the change.
- Failure: Adding a per-icon corner option, or changing the constant without
  fidelity figures.
- Acceptance: The report names the constant, both fidelity runs, and the
  logos that would need regeneration.

## SI-08 — Missing verification inputs

- Prompt: Verify this icon family and the generator's fidelity.
- Context: One checked-in logo is missing. The reference directory is empty,
  or contains only images with unsupported dimensions.
- Expected artifact: A drift report identifying the missing file, and an
  incomplete fidelity report naming the styles without measurements.
- Must preserve: Existing logos and design entries.
- Failure: Returning success without a measurement for every style, or
  reporting a missing logo as matching.
- Acceptance: Both checks exit non-zero with actionable diagnostics; neither
  creates or overwrites a logo.
