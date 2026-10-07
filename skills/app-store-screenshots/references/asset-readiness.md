# Asset Readiness

## Readiness Checklist

- File format is `.png`, `.jpg`, or `.jpeg`.
- Dimensions match an accepted Apple size for the selected device well.
- No alpha transparency is present.
- Color space is suitable for App Store upload; prefer sRGB/RGB output for
  predictable rendering.
- Source screenshots are captured or designed at the target aspect ratio.
- Filenames sort in display order, such as `01-hero-en-1320x2868.png`.
- Existing screenshots are preserved; generated or resized variants go to a
  separate output directory.

## Local Inspection

Use the bundled helper for local files:

```bash
skills/app-store-screenshots/scripts/check_screenshots.sh \
  --target 1320x2868 \
  path/to/screenshots/*.png
```

Use multiple targets when a directory contains several accepted sizes:

```bash
skills/app-store-screenshots/scripts/check_screenshots.sh \
  --target 1320x2868 \
  --target 1284x2778 \
  path/to/screenshots/*.png
```

For direct macOS inspection:

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha -g space screenshot.png
```

## Alpha And Color

App Store screenshots should be flattened. If a PNG has alpha, create a
flattened copy instead of overwriting the source:

```bash
mkdir -p flattened
sips -s format jpeg input.png --out /tmp/appstore-flatten.jpg
sips -s format png /tmp/appstore-flatten.jpg --out flattened/input.png
rm /tmp/appstore-flatten.jpg
```

If the color profile needs conversion, write a new output file:

```bash
sips -m "/System/Library/ColorSync/Profiles/sRGB IEC61966-2.1.icc" \
  input.png --out output-srgb.png
```

## Resizing Cautions

- `sips -z` takes height first, then width.
- `sips` stretches to exact dimensions. Do not use it to fix a wrong aspect
  ratio unless the distortion is intentional and acceptable.
- Prefer re-capture or redesign when the source ratio does not match the target
  well.
- Do not upscale small screenshots and call them production-ready without a
  warning.

## Common Upload Blockers

- One-pixel dimension mismatch.
- PNG alpha channel.
- Wrong device well, such as iPhone asset placed into iPad well.
- Localized set missing a screenshot that exists in the source locale.
- File names with hidden Unicode characters copied from system screenshots.
- Copy or device frame extends beyond canvas after export.
