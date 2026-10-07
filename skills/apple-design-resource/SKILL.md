---
name: apple-design-resource
description: Fetch, index, probe, summarize, or optionally download reachable official Apple Design Resources for other skills. Use when Codex needs Apple UI kits, design templates, app icon templates, product bezels, fonts, SF Symbols, Icon Composer, badges, logos, technology templates, or direct Apple design-resource asset links from developer.apple.com/design/resources. Do not use for HIG rule interpretation, SwiftUI/UIKit/AppKit implementation, SF Symbols glyph export, App Store screenshot production, DESIGN.md template selection, or unofficial brand scraping.
---

# Apple Design Resource

## Purpose

Use this atomic skill as the official Apple design-resource adapter. It turns
the live Apple Design Resources page into a local catalog that higher-level
skills can consult for asset locations, resource families, availability, and
direct-download candidates.

This skill owns resource discovery and transport facts. It does not decide HIG
conformance, design style, implementation approach, or App Store deliverables.
When an official resource resolves to a Sketch Cloud share or local `.sketch`
file, hand that source to `sketch-design` for download, parsing, export, and
handoff artifacts.

## When To Use

- Find official Apple UI kits, design templates, production templates, product
  bezels, fonts, SF Symbols, Icon Composer, app icon templates, badges, logos,
  or technology templates.
- Refresh a local catalog from `https://developer.apple.com/design/resources/`.
- Probe whether official Apple, Figma, Sketch, or direct CDN resource links are
  currently reachable.
- Download direct Apple CDN design-resource archives when the user explicitly
  wants local assets.
- Provide another skill with a compact resource catalog instead of making it
  scrape the Apple page directly.
- Hand official Sketch links, including `sketch.com/s/...` shares, to
  `sketch-design` without resolving or parsing them here.

## When Not To Use

- Apple HIG interpretation, platform convention review, scorecards, or
  accessibility guidance. Use `apple-hig`.
- Sketch Cloud share resolution, `.sketch` ZIP/JSON parsing, visual exports,
  or implementation handoff. Use `sketch-design`.
- SwiftUI, UIKit, AppKit, or Xcode implementation work.
- Exporting individual SF Symbols glyphs. Use `sfsymbols-export`.
- App Store screenshots, metadata, ASO, or submission assets.
- Selecting or applying local `DESIGN.md` templates. Use
  `design-md-template`.
- Scraping unofficial brand systems or third-party design kits as authority.

## Workflow

1. Run the fetch script to build or refresh the catalog:

   ```bash
   python3 skills/apple-design-resource/scripts/fetch_apple_design_resources.py
   ```

2. Add `--probe` when current reachability matters. The script probes HTTP(S)
   links with bounded concurrency and records status, content type, content
   length, and errors.
3. Add `--download-direct` only when the user explicitly asks for local copies.
   The script downloads only direct Apple CDN resources and respects
   `--max-download-bytes`.
4. Read `references/generated/latest-catalog.json` for machine consumption or
   `references/generated/latest-README.md` for a compact human summary.
5. Pass only resource facts to the calling skill: resource family, platform or
   section, label, URL, link kind, reachability, file type, size, and local
   download path when present.
6. If the caller needs a Sketch Cloud share or `.sketch` file interpreted, pass
   the URL or local path to `sketch-design` rather than extending this skill.

## Script

`scripts/fetch_apple_design_resources.py` supports:

- `--source-url`: override the official source URL for debugging.
- `--output-dir`: change the generated catalog root.
- `--snapshot-name`: choose a deterministic snapshot directory.
- `--probe`: test HTTP(S) reachability.
- `--max-workers`: limit probe concurrency.
- `--resource-family`: include only one or more catalog families, such as
  `product-bezel`.
- `--link-kind`: include only one or more link kinds, such as
  `apple-cdn-download` or `sketch-cloud-share`.
- `--section-contains`: include only rows whose section path contains text.
- `--label-contains`: include only rows whose label contains text.
- `--download-direct`: download direct Apple CDN resource files.
- `--max-download-bytes`: cap each direct download.
- `--extract-dmg`: mount downloaded `.dmg` files and copy matching asset files.
- `--extract-extension`: asset extension to extract, default `.png`; repeat for
  more extensions.

Generated files live under `references/generated/`:

- `latest-catalog.json`: latest machine-readable catalog.
- `latest-links.csv`: latest flat link table.
- `latest-README.md`: latest human-readable summary.
- `<snapshot>/catalog.json`, `<snapshot>/links.csv`, `<snapshot>/README.md`,
  and `<snapshot>/INDEX.md`: immutable snapshot output.

Catalog snapshot, download, and extraction paths are relative to the output
directory selected by `--output-dir`. Dated snapshots and downloaded assets
stay local; the repository publishes the three `latest-*` catalog files.

## Decision Rules

- Treat Apple Design Resources as asset/source-link authority, not HIG rule
  authority.
- Prefer official Apple URLs over third-party mirrors. Keep Figma and Sketch
  links as external official-page links, not as local source copies.
- Treat `sketch-cloud-share`, `sketch://`, and local `.sketch` assets as
  handoff inputs for `sketch-design`; do not perform Sketch Cloud GraphQL
  resolution or Sketch document parsing in this skill.
- Do not download anything by default. Network probing is read-only; downloads
  require explicit user intent.
- Mount and extract Apple design-resource DMGs only when the user asks for
  extraction; `--extract-dmg` is the explicit opt-in.
- Do not commit raw downloaded Apple design assets unless a human explicitly
  asks and licensing/storage implications are understood.
- Preserve platform and section context from the source page so callers can
  distinguish iOS, iPadOS, macOS, tvOS, watchOS, visionOS, technology, font,
  tool, and product-bezel resources.

## Validation

- The script exits nonzero when the page cannot be fetched or no resource links
  are found.
- `latest-catalog.json` parses as JSON and includes `source_url`,
  `fetched_at`, `resources`, `counts`, and `snapshot_dir`.
- Probe failures are recorded per link instead of failing the whole catalog.
- Direct downloads record SHA-256, byte count, local path, or a skip/error
  reason.
