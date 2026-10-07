# Generator Workflow

Use this reference when the user asks for a local generator for Google Play
screenshots or feature graphics.

## Scope

Generate exportable local assets. Do not upload to Play Console.

Supported first-pass targets:

- Android phone screenshots.
- 7-inch tablet screenshots, portrait and landscape.
- 10-inch tablet screenshots, portrait and landscape.
- Feature graphic, 1024x500.

Add Chromebook, TV, Wear OS, Automotive, or Android XR only when the user
explicitly targets those form factors.

## Project Shape

Use the user's existing frontend stack when available. For a new generator,
keep it small and deterministic:

```text
project/
├── public/
│   ├── app-icon.png
│   └── screenshots/
│       └── android/
│           ├── phone/
│           ├── tablet-7/
│           │   ├── portrait/
│           │   └── landscape/
│           └── tablet-10/
│               ├── portrait/
│               └── landscape/
└── src/app/page.tsx
```

Only create directories for device types the user actually supports.

## Canvas Sizes

Use sizes that satisfy Google Play guidance and export cleanly:

```text
phone portrait:       1080x1920
7-inch tablet portrait: 1200x1920
7-inch tablet landscape: 1920x1200
10-inch tablet portrait: 1600x2560
10-inch tablet landscape: 2560x1600
feature graphic:      1024x500
```

These are generator defaults, not the only accepted Google Play dimensions.
Validate final assets with `check_play_assets.sh` and current Google Play
Console guidance.

## Export Rules

- Preload images and fonts before export.
- Export at exact canvas size with `pixelRatio: 1`.
- Use numbered filenames so assets sort in listing order.
- Keep source captures unmodified; write generated assets to an output folder.
- Re-run validation after export.
- Avoid hidden live upload steps.

## QA Gate

- Text fits at thumbnail size.
- Feature graphic focal content remains center-safe.
- Phone and tablet screenshots use the correct capture type.
- No alpha where Google requires flattened JPEG or 24-bit PNG.
- No ranking, price, sale, testimonial, or store badge claims.
- Localized exports are reviewed separately.
