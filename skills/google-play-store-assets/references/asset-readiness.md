# Asset Readiness

## Readiness Checklist

- File is `.png`, `.jpg`, or `.jpeg` for screenshots and feature graphics.
- Screenshots and feature graphics are JPEG or 24-bit PNG with no alpha.
- App icon is a 512x512 PNG with alpha and file size no larger than 1024KB.
- Feature graphic is exactly 1024x500.
- Generic screenshots meet Google Play mandatory size rules:
  - minimum dimension at least 320px
  - maximum dimension no more than 3840px
  - longest side no more than twice the shortest side
- Large-screen screenshots are 16:9 landscape or 9:16 portrait when targeting
  promotion-ready tablet/Chromebook formats.
- Wear OS screenshots are 1:1 and at least 384x384 when targeting Wear OS.
- Android XR screenshots are 8:5, at least 1920x1200, and no larger than 8MB.
- Filenames sort in display order, such as `01-hero-en-phone-1080x1920.png`.
- Existing assets are preserved; generated variants go to a separate output
  directory.

## Local Inspection

Use the bundled helper:

```bash
skills/google-play-store-assets/scripts/check_play_assets.sh \
  --kind screenshot \
  path/to/screenshots
```

Other supported kinds:

```bash
--kind feature-graphic
--kind app-icon
--kind large-screen
--kind wear-os
--kind android-xr
```

For direct macOS inspection:

```bash
sips -g pixelWidth -g pixelHeight -g hasAlpha -g space asset.png
```

## Common Upload Blockers

- Feature graphic not exactly 1024x500.
- Screenshot has alpha.
- Screenshot longest side is more than twice the shortest side.
- PNG is RGBA when a flattened RGB image is required.
- Tablet section filled with phone-shaped screenshots.
- Wear OS screenshot includes a device frame or extra graphic background.
- Android XR screenshot has the wrong 8:5 aspect ratio.
- Asset contains ranking, price, sale, award, testimonial, or store badge text.
- Localized copy overflows after translation.
- Missing alt text for uploaded graphic assets.
