# Apple Screenshot Specs

Source authority:

- Apple App Store Connect Help, Screenshot specifications:
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Apple App Store Connect Help, Upload app previews and screenshots:
  https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots

Verify these sources again before final upload if the user is preparing a real
release.

## Upload Basics

- Screenshots use `.jpeg`, `.jpg`, or `.png`.
- Each supported device well accepts 1 to 10 screenshots.
- App previews are separate from screenshots and are optional.
- App previews appear before screenshots on supported product pages.
- Screenshots can be changed in editable App Store Connect states. After a
  version is submitted and approved, a new version is required to update them.
- If the UI is the same across multiple sizes or localizations, Apple can scale
  from the highest required screenshots. Use custom screenshots when quality,
  layout, or localization differs.

## iPhone

Apple lists iPhone Duo outer-display sizes `1398 x 2034` / `2034 x 1398`
and inner-display sizes `2007 x 2853` / `2853 x 2007`. Its specification
says App Store Connect upload support will be available later in 2026. Treat
these as announced sizes, not currently upload-ready wells; verify that upload
support has opened before preparing a release that depends on them.

| Display | Accepted portrait | Accepted landscape | Requirement / scaling |
| --- | --- | --- | --- |
| 6.9" | 1260 x 2736, 1290 x 2796, 1320 x 2868 | 2736 x 1260, 2796 x 1290, 2868 x 1320 | Highest current iPhone well. |
| 6.5" | 1284 x 2778, 1242 x 2688 | 2778 x 1284, 2688 x 1242 | Required for iPhone apps if 6.9" is not provided; otherwise uses scaled 6.9" screenshots when this size is absent. |
| 6.3" | 1179 x 2556, 1206 x 2622 | 2556 x 1179, 2622 x 1206 | Scales from 6.5" when not provided. |
| 6.1" | 1170 x 2532, 1125 x 2436, 1080 x 2340 | 2532 x 1170, 2436 x 1125, 2340 x 1080 | Scales from 6.5" when not provided. |
| 5.5" | 1242 x 2208 | 2208 x 1242 | Scales from 6.1" when not provided. |
| 4.7" | 750 x 1334 | 1334 x 750 | Scales from 5.5" when not provided. |
| 4" | 640 x 1096, 640 x 1136 | 1136 x 600, 1136 x 640 | Status-bar variants are accepted. |
| 3.5" | 640 x 920, 640 x 960 | 960 x 600, 960 x 640 | Status-bar variants are accepted. |

## iPad

| Display | Accepted portrait | Accepted landscape | Requirement / scaling |
| --- | --- | --- | --- |
| 13" | 2064 x 2752, 2048 x 2732 | 2752 x 2064, 2732 x 2048 | Required if app runs on iPad. |
| 12.9" | 2048 x 2732 | 2732 x 2048 | Scales from 13" when not provided. |
| 11" | 1488 x 2266, 1668 x 2420, 1668 x 2388, 1640 x 2360 | 2266 x 1488, 2420 x 1668, 2388 x 1668, 2360 x 1640 | Scales from 13" when not provided. |
| 10.5" | 1668 x 2224 | 2224 x 1668 | Scales from 12.9" when not provided. |
| 9.7" | 1536 x 2008, 1536 x 2048, 768 x 1004, 768 x 1024 | 2048 x 1496, 2048 x 1536, 1024 x 748, 1024 x 768 | Scales from 10.5" when not provided. |

## Other Platforms

| Platform | Accepted dimensions | Requirement |
| --- | --- | --- |
| Mac | 1280 x 800, 1440 x 900, 2560 x 1600, 2880 x 1800 | Required for Mac apps; 16:10 aspect ratio. |
| Apple TV | 1920 x 1080, 3840 x 2160 | Required for Apple TV apps. |
| Apple Vision Pro | 3840 x 2160 | Required for Apple Vision Pro apps. |
| Apple Watch | 422 x 514, 410 x 502, 416 x 496, 396 x 484, 368 x 448, 312 x 390 | Required for Apple Watch apps; use the same watch screenshot size across all localizations. |

## Practical Defaults

- For iPhone-only work, start with 6.9" portrait `1320 x 2868` unless an
  existing App Store Connect well or app target requires another accepted size.
- For universal iPhone/iPad apps, include the 13" iPad requirement check.
- For generator output, produce exact accepted dimensions; avoid relying on
  stretch resizing after design.
- For review reports, separate Apple requirements from creative suggestions.
