# Google Play Preview Assets

Last verified: 2026-04-30.

Official authority: Google Play Console Help, [Add preview assets to showcase
your app](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).

## Source Hierarchy

1. Current Play Console state and official Google Play Console Help.
2. Google Play Developer Program Policies and metadata policy.
3. Selected generator/export tool behavior.
4. Community examples and upstream skill content.

Community skill examples can shape workflow and generator design, but they are
not authority for current Play requirements.

## Managed Surface

Google says preview assets are managed from Play Console:

```text
Grow users > Store presence > Main store listing > Graphics
```

Assets can appear beyond the store listing, including Google Play promotional
surfaces. Note whether "External marketing" is enabled in store settings when
the user cares about Google-owned promotional placement.

## App Icon

Required to publish the store listing:

- 32-bit PNG with alpha.
- 512px by 512px.
- Maximum file size: 1024KB.
- Must follow Google Play icon design specifications.
- Must not include ranking, price, category, badge, or misleading text.

## Short Description

Required to publish the store listing:

- 80-character limit.
- Summarize the app or game's core purpose.
- Avoid ranking/performance claims, price or promotional language,
  call-to-actions, keyword stuffing, repeated punctuation, line breaks, emojis,
  and capitalization for emphasis.
- Localize where appropriate.

## Feature Graphic

Required to publish the store listing:

- JPEG or 24-bit PNG, no alpha.
- 1024px by 500px.
- Used as preview video cover when a preview video exists, and in larger Play
  surfaces.

Recommended:

- Convey the app or game experience and core value proposition.
- Keep focal content centered and avoid cutoff zones.
- Avoid overloaded details, pure white/black/dark gray backgrounds, price or
  ranking claims, time-sensitive claims, third-party trademarks without
  permission, device imagery, and Google Play/store badges.
- Localize graphic text where appropriate.
- Include alt text of 140 characters or fewer.

## Screenshots

Google Play supports up to 8 screenshots for each supported device type:

- phones
- tablets, 7-inch and 10-inch
- Chromebooks
- Android TV
- Wear OS watches
- Android Automotive OS cars
- Android XR headsets

Minimum publishing requirement:

- At least two screenshots across device types.
- JPEG or 24-bit PNG, no alpha.
- Minimum dimension: 320px.
- Maximum dimension: 3840px.
- Maximum dimension cannot be more than twice the minimum dimension.

Promotion-readiness recommendations:

- Apps: at least four screenshots with minimum 1080px resolution for large
  screenshot formats; use 16:9 landscape or 9:16 portrait.
- Games: at least three 16:9 landscape or 9:16 portrait screenshots.
- Screenshots should demonstrate the actual app or game experience.
- Avoid blurry, distorted, stretched, upside-down, sideways, or skewed images.
- Avoid third-party trademarked characters/logos without permission, device
  imagery, and Google Play/store badges.
- Include alt text of 140 characters or fewer.

## Device-Specific Notes

- Large screens: Chromebook and tablet sections should demonstrate the
  in-app experience. Google recommends at least four screenshots, 1080-7680px,
  and 16:9 or 9:16 aspect ratio.
- Wear OS apps: include at least one current Wear OS screenshot, only the app
  interface, no device frames or added graphics, 1:1 aspect ratio, minimum
  384x384, and no transparent backgrounds or masking.
- Android TV: an Android TV screenshot and TV banner are required for
  Android TV-enabled apps.
- Android Automotive OS: requirements vary by category; provided screenshots
  must accurately depict the app on Android Automotive OS.
- Android XR: upload 4-8 PNG/JPEG screenshots, up to 8MB each, 8:5 aspect
  ratio, recommended 3840x2400, minimum 1920x1200.

## Preview Video

Optional for most apps; especially recommended for games and required for some
game promotional surfaces.

- Use a YouTube URL, not a playlist or channel.
- Do not add extra URL parameters such as timecodes.
- Video must be public or unlisted, not private.
- Ads must be disabled.
- Video must not be age-restricted and must be embeddable.
- Show actual app or game experience early; keep the first 30 seconds strong.
- Avoid ranking, price, promotional, call-to-action, or misleading copy.
