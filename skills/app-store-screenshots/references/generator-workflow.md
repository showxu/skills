# Generator Workflow

Use a generator only when the user asks to create exportable screenshot assets
or when repeated locale/device/theme exports would be more reliable than manual
design exports.

## Scope

- Keep the generator Apple App Store only in this repository.
- Do not add Google Play, Android devices, feature graphics, or cross-store
  export matrices here.
- Do not include upstream image assets or mockups unless the user provides
  license-safe replacements.
- Do not include live App Store Connect upload actions.

## Project Shape

For a web generator, prefer the smallest local shape that works with the
target project. A common shape is:

```text
public/
├── app-icon.png
└── screenshots/
    ├── iphone/<locale>/*.png
    └── ipad/<locale>/*.png
src/app/page.tsx
```

The generator may be Next.js, Vite, a static HTML page, or an existing app
surface. Choose the stack already present in the user's project unless they
explicitly ask for a fresh generator.

## Canvas Defaults

Design at exact Apple sizes. Common starting points:

```ts
const IPHONE_69 = { w: 1320, h: 2868 };
const IPHONE_65 = { w: 1284, h: 2778 };
const IPAD_13 = { w: 2064, h: 2752 };
```

Use the full official table in `apple-screenshot-specs.md` when a different
well is needed.

## Export Reliability

- Preload image assets before export.
- Use stable dimensions instead of viewport-relative canvas sizing.
- Render export nodes at true target size.
- Use predictable filenames with zero-padded slide numbers.
- Export to PNG or JPEG only.
- Inspect generated output after export with `check_screenshots.sh`.
- If a browser DOM-to-image library is used, verify images and fonts are fully
  loaded before capture; do a warm-up capture if the library is flaky.

## Generator Review

Before calling generator output ready:

- Compare exported file dimensions with the intended device well.
- Confirm no text or app UI is clipped.
- Confirm the first slide is strongest and adjacent layouts vary.
- Confirm localized and RTL exports are reviewed separately.
- Confirm generated assets are not silently uploaded.
