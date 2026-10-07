# Sketch Design Eval Fixtures

## Fixture: Sketch Cloud Share Resolve

- Input: Apple iOS 26 UI Kit Sketch Cloud share
  `https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9`.
- Command:

  ```bash
  python3 skills/sketch-design/scripts/fetch_sketch_cloud_share.py \
    --url https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9 \
    --output-dir /tmp/sketch-cloud-ios26 \
    --resolve-only
  ```

- Expected:
  - `manifest.json` uses schema `sketch-design.cloud-manifest.v1`.
  - The resolved document is named `Apple iOS 26 UI Kit`.
  - The document metadata includes size, Sketch version, page count, frame
    count, document version, and download availability.
  - The manifest records `download_url_omitted: true` and does not persist the
    signed temporary download URL.
  - If run without `--resolve-only`, the downloaded `.sketch` file is ZIP-valid
    and can be passed directly to `extract_sketch_design.py`.

## Fixture: Sketch Cloud GraphQL Read-Only CLI

- Input: Apple iOS 26 UI Kit Sketch Cloud share
  `https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9`.
- Commands:

  ```bash
  skills/sketch-design/scripts/sketch-cli schema \
    --output-dir /tmp/sketch-cloud-graphql-schema

  skills/sketch-design/scripts/sketch-cli index \
    --url https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9 \
    --page-limit 5 \
    --frame-limit 5 \
    --component-limit 5 \
    --output-dir /tmp/sketch-cloud-graphql-index

  skills/sketch-design/scripts/sketch-cli tokens \
    --url https://www.sketch.com/s/f63aa308-1f82-498c-8019-530f3b846db9 \
    --output-dir /tmp/sketch-cloud-graphql-tokens
  ```

- Expected:
  - `schema-summary.json` reports root query/mutation/subscription names,
    schema counts, relevant enums, implemented read-only segments, future
    read-only segments, and excluded mutation/subscription scope.
  - `document-index.json` reports `Apple iOS 26 UI Kit`, 33 pages, 1477
    frames, 1462 symbols, 105 text styles, 20 layer styles, and 111 color
    variables.
  - `document-index.json` omits signed file/render/download URLs and stores only
    stable asset metadata.
  - `token-export.json` contains Cloud token export data without persisting
    token download URLs.
  - These Cloud facts are treated as preflight/index data. Local `.sketch`
    extraction remains the final design-fact source.

## Fixture: Apple iOS 26 UI Kit Batch Summary

- Input: `.sketch` downloaded from the Apple iOS 26 Sketch Cloud share above.
- Command:

  ```bash
  python3 skills/sketch-design/scripts/extract_sketch_design.py \
    --input "/tmp/sketch-cloud-ios26/Apple iOS 26 UI Kit.sketch" \
    --output-dir /tmp/sketch-design-ios26-full \
    --summary-only
  ```

- Expected:
  - The script completes without MCP full-document traversal.
  - The original view reports nonzero pages, symbol masters, text layers,
    symbol instances, shared layer styles, text styles, swatches, fonts, and
    embedded images.
  - The output preserves Apple iOS 26 semantics such as Liquid Glass and Tab
    Bar through source naming, symbols, styles, and token evidence.
  - The route is comparable to the official Figma library route for stable
    design-system discovery, while keeping Sketch extraction fully local after
    the `.sketch` download.

## Fixture: Apple tvOS UI Library Batch Summary

- Input: `references/fixtures/apple-tvos-ui.sketch`, the Apple tvOS UI Sketch
  library extracted from official Apple Design Resources.
- Baseline: `references/apple-fixture-baseline.json` fixture
  `apple-tvos-ui-library-large`.
- Command:

  ```bash
  python3 skills/sketch-design/scripts/extract_sketch_design.py \
    --input skills/sketch-design/references/fixtures/apple-tvos-ui.sketch \
    --output-dir /tmp/sketch-design-large \
    --detach \
    --summary-only
  ```

- Expected:
  - The script completes without MCP full-document traversal.
  - `summary.md` includes artboard, symbol, shared style, swatch, font, color,
    and effect counts.
  - Original and detached views remain separately labelled.
  - `design-context.json` uses schema `sketch-design.context.v2`.
  - Detail coverage records style, text, symbol, export, shape, prototype,
    background, group layout, and override sections where present.
  - Generated exports stay outside the repository unless a human explicitly
    asks to commit a specific output.

## Fixture: Apple UI Library Symbol Export

- Input: `references/fixtures/apple-tvos-ui.sketch`.
- Command:

  ```bash
  python3 skills/sketch-design/scripts/extract_sketch_design.py \
    --input skills/sketch-design/references/fixtures/apple-tvos-ui.sketch \
    --output-dir /tmp/sketch-design-onboarding \
    --target "Onboarding & Sign In/Dark/PIN Entry 6 Digits" \
    --export-artboards \
    --include-symbols
  ```

- Expected:
  - One 1920x1080 onboarding PNG is exported.
  - The export manifest records one exported file named
    `500D55C8-B2F0-425E-BFC7-66940E4A056E.png`.
  - `target_filter.applied` is true and the context is scoped to the selected
    symbol-master subtree plus ancestors.
  - The target symbol master has detailed `background`, `symbol`, `style`, and
    `layout` facts in `design-context.json`.
  - `--include-symbols` is required because the target is a symbol master, not
    a regular artboard.

## Fixture: MCP Parity Calibration

- Input: a small representative Sketch document opened in Sketch, with Sketch
  MCP running at `http://127.0.0.1:31126/mcp`. Avoid full-library MCP traversal
  for `apple-tvos-ui.sketch`.
- Command:

  ```bash
  python3 skills/sketch-design/scripts/extract_sketch_design.py \
    --input path/to/open-document.sketch \
    --output-dir /tmp/sketch-design-mcp \
    --mcp-parity-url http://127.0.0.1:31126/mcp \
    --summary-only
  ```

- Expected:
  - `mcp-parity.json` is generated when the document is open in Sketch.
  - If the document is not open, parity is marked `skipped`, not failed.
  - When available, MCP layer count and mapped type counts are used as
    calibration signals for the local parser.

## Fixture: Implementation Handoff Quality

- Input: any `.sketch` file with text, shapes, at least one artboard, and at
  least one exported visual reference.
- Expected:
  - `implementation-handoff.md` contains component, token, asset, validation,
    and re-query guidance.
  - It explicitly preserves official coding guidance: project conventions,
    visual parity, incremental updates, component boundaries, intentional
    deviations, and re-extraction on mismatch.
  - It does not contain framework-specific SwiftUI, UIKit, AppKit, React, or
    HTML implementation code.
  - It distinguishes source facts from inferred implementation hints.

## Fixture: Sibling Boundary

- Input: a request to implement a selected Sketch frame into project code.
- Expected:
  - This skill may produce design context and handoff artifacts.
  - Live current-selection implementation remains owned by the official
    source-owned `sketch-implement-design` workflow.
  - Framework-specific coding remains owned by the relevant implementation
    skill.
