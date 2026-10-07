# Brand

## Sources of Truth

- `.github/DESIGN.md`: tokens in front matter (colors, typography, spacing,
  radii, components) and the prose rules for composition and the icon family.
  Shape and templates: `design-md-template`.
- `.github/Brand/config.json`: fonts pinned by URL and SHA-256, the copy and
  members rendered into images, and the consumer map (which repository
  receives which exports, at which paths).
- Product family copy comes from the main repository’s ProductIdentity; a
  package collection takes claims and descriptions from each owning package.

## Pipeline

1. Edit `DESIGN.md` or `Brand/config.json`.
2. Render with the organization's renderer (headless Chromium through
   Playwright) into `Brand/Exports/` and its `manifest.json` of hashes. Never
   edit exports by hand.
3. Lint `DESIGN.md` and run the brand check: exports match the manifest and
   the current inputs.
4. Commit inputs and exports together in `.github`.
5. `brand.py sync <checkout>` per consumer: copies the files it uses, removes
   files its previous lock delivered and no longer needs, rewrites
   `.github/brand/brand.lock.json`, verifies. One pull request per consumer.
6. Each consumer's CI calls the shared `brand-check.yml@<commit>`; it is a
   required check. The check is self-consistency (files match their own lock),
   so repositories update independently and none breaks when `.github` moves
   ahead.
7. After merges, upload social previews and verify them (below).

Reference implementation: the reference organization's `.github` (`Brand/`,
`brand.py`, `.github/workflows/brand-check.yml`). Copy it into a new
organization and replace its configuration; do not import it across
organizations.

## Typography

- Use the typography declared in DESIGN. A system stack needs no bundled
  fonts: `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue",
  "PingFang SC", "Hiragino Sans GB", "Segoe UI", "Microsoft YaHei",
  system-ui, sans-serif`; monospace `ui-monospace, "SF Mono", SFMono-Regular,
  Menlo, Consolas, monospace`, and only for code.
- An open-font website may self-host a pinned, unmodified font with its
  redistribution license. Put the choice and typography scale in DESIGN.
  Review Latin and CJK wrapping, body readability and small-size rendering;
  platform familiarity does not require one fixed scale for every product.
- Artwork cannot use SF Pro: Apple's license excludes it. Render images with
  open fonts (Inter, Noto Sans SC, JetBrains Mono) pinned in
  `Brand/config.json`, using the same tokens.
- Avoid uppercase monospace labels and decorative display faces; they read as
  generated rather than designed.

## Icons

- `apple-framework-icon-design` owns stacked, volumetric and flat member
  icons. `apple-app-icon-design` owns native layered `.icon` documents, native
  platform/appearance exports and web renditions. DESIGN owns parameters;
  renderers derive assets and drift checks verify every consumer.
- Give members distinct hues with deliberate perceptual spacing. Review the
  family at header and table sizes on light and dark backgrounds. Use original
  glyphs and preserve authorized mark provenance; do not imitate another
  company’s icon. Route any permitted symbol export to its licensing owner.
- Validate a generated `.icon` by native export and by opening, editing,
  saving and reopening a temporary native duplicate. Confirm original bytes
  remain unchanged. A successful command-line export alone does not prove
  the document is editable.
- Check the exact uploaded SVG/PNG in the affected browser. Equivalent SVG
  geometry can render differently across engines; verify a correction in the
  reported browser and preserve the intended glyph orientation.

## Social Previews and Avatar

GitHub has no API for repository social previews or the organization avatar.

- Upload through the repository's Settings page in an authenticated browser
  session. With browser automation: navigate to the settings page in one step;
  in a second step, fetch the PNG from `raw.githubusercontent.com` at the
  merged commit SHA, put it into the page's repository-image upload input
  through a `DataTransfer`, and confirm the upload targets the expected
  repository ID. Navigation resets page state, so never combine the two.
- Verify with GraphQL: fetch each repository's `openGraphImageUrl` and compare
  its SHA-256 with the export.
- Private repositories do not show previews publicly; skip them unless asked.
- Upload the accepted avatar in organization settings within existing
  authorization. If the service resizes it, verify the saved result and record
  the accepted source; preserve the native original.

## Review Checks

- Inputs, exports, and manifest committed together; brand check passes.
- Every consumer's lock verifies, and its pull request merged before social
  previews were uploaded.
- Rendered text matches its owning product or package in every locale.
- No hand-edited exports; bundled fonts retain the declared source and license.

## DocC Landing Identity

Route catalog and directive details to `swiftpm-docs`. Each package landing
uses its repository icon via `@PageImage(purpose: icon, ...)` and a supported
named `@PageColor`. The organization’s DESIGN owns the mapping from its color
space and hue ranges to DocC names; do not duplicate package hues here.

| Example OKLCH hue interval | DocC name |
| --- | --- |
| 330–360 or 0–35 | red |
| 35–75 | orange |
| 75–115 | yellow |
| 115–185 | green |
| 185–265 | blue |
| 265–330 | purple |

This is a design-policy example, not a DocC requirement. Choose one exhaustive,
non-overlapping table in the organization’s owner. Preserve existing catalog
metadata and apply defaults only when absent, including a synthesized merged
landing for multiple modules. Verify generated metadata, referenced image bytes
and real hosted URLs. A 200 response alone does not prove correct identity.
