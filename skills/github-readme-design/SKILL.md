---
name: github-readme-design
description: Lay out and render GitHub repository READMEs and public or member-only organization profiles from a supplied information set and the applicable DESIGN. Use for README first screens and section layout for libraries, CLIs, MCP servers, plugins and apps, open or closed source; badge styling; Quick look form; app download blocks and screenshot plans; public and member-only organization profile layout; deterministic catalog-driven profiles and social previews; and locally rendered light/dark terminal demos with CI recording checks. Produces README layouts, image exports, terminal scripts and recordings, catalog-driven social/profile exports and review evidence. Does not decide what a README states or source its values, change repository settings, upload previews, assign documentation roles, design icons, or build personal profile READMEs.
---

# GitHub README Design

Turn accepted information into a page and its images. The information says
what the page states; this skill decides where each statement goes, what form
it takes and how it looks, and renders the images that carry it.

## Inputs

- **Information set:** the product kind, every statement the page carries with
  its value and owner, the accepted one-sentence summary, and the outcome the
  Quick look demonstrates. It comes from the caller. When it is absent or
  incomplete, lay out nothing that depends on the missing part and report
  what is needed.
- **DESIGN:** the applicable DESIGN file at its reviewed revision, usually the
  organization's `.github/DESIGN.md`. Toolchain rendering requires the Google
  format and complete components for the selected asset; report missing values
  to the DESIGN owner. For manual README layout, where DESIGN is silent,
  choose project defaults and record them for that owner.
- **Profile inputs:** the public catalog; for a member dashboard, the catalog
  and DESIGN from the accepted `.github` commit, that explicit revision
  and member operational input. Missing or extra members fail.
- **Existing surface:** the current README, assets, recordings and
  any repository-owned renderer.

Values are used exactly as supplied. A layout never adds a channel,
requirement, command or claim the information set does not contain.

## Workflow

1. **Confirm inputs.** Record the product kind, information set, DESIGN path
   and digest, and existing assets.
2. **Lay out the README.** Use [design](references/design.md) for libraries,
   CLIs, MCP servers and plugins, and [app design](references/design-apps.md)
   for apps. Badges, the social preview and review in
   [design](references/design.md) apply to every kind. An organization profile
   uses the public or member layout in [design](references/design.md) and the
   shared profile renderer in [renderers](references/renderers.md).
3. **Produce images.** Use the pinned [toolchain](references/renderers.md) to
   record terminal `script.yml` against the built product and render its
   recording with the applicable DESIGN and fonts. Render social previews from
   DESIGN, the catalog and the accepted light-page icon; render profiles from
   DESIGN and the catalog, adding operational input and the catalog revision
   for member dashboards. Plan app screenshots from the released build, in
   light and dark.
4. **Review.** Inspect the exact exports in light and dark and in the reported
   browser. Locally run `terminal check` to re-record and compare the recording and both
   SVGs; run `social-preview check` and `profile check` for those outputs. Use
   the ecosystem validation workflow's `demo` switch in CI to re-record and
   compare only `recording.json` against the freshly built CLI.
5. **Hand back.** Return the README layout, exports, terminal scripts and
   recordings, catalog/member input paths, the pinned standard revision and
   review evidence.
   Committing follows the repository's workflow;
   settings and uploads stay with the caller.

## Boundaries

| Work | Owner |
| --- | --- |
| Framework icon family or app icons | `apple-framework-icon-design`, `apple-app-icon-design` |
| DESIGN file shape and templates | `design-md-template` |
| Store screenshot sets and official store badge artwork | `app-store-screenshots`, `apple-design-resource` |
| iOS Simulator captures | `ios-simulator` when installed |

What the page states, where each value comes from, documentation roles,
repository settings and preview uploads belong to the caller.

## Validation and output

- Every value on the page equals the information set; layouts invent nothing.
- Local terminal recordings and exports pass `terminal check`; social/profile
  exports pass `social-preview check` and `profile check`. Review the exact
  consumed PNG and generated profile markup.
- Images are reviewed in light and dark. Terminal body lines soft-wrap at
  whole glyphs with continuation markers; titles must fit. Social-card overflow
  follows its title/About fitting rules.

Report the layout, exports and their source inputs, DESIGN revision, review evidence,
defaults chosen where DESIGN was silent, and missing information.

Maintainers: read [architecture](references/architecture.md), run the helper
tests and use the [fixtures](references/eval-fixtures.md).
