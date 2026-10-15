# Generations

Each style renders the same entry with one generation's outline and system
treatment. Only `liquid-glass` uses Apple's renderer; the others are style
renderings with the geometry recorded in [rendering](rendering.md).

| Style | Generation | Outline | Treatment | Rendering |
| --- | --- | --- | --- | --- |
| `liquid-glass` | iOS, iPadOS, macOS and watchOS 26 and later | Icon Composer mask; circle on watchOS | Layered glass: specular highlights, refraction, translucency; default, dark, clear and tinted appearances | Native |
| `flat` | iOS 7 to 18 | Continuous rounded square on the full canvas | Flat artwork on a solid or gradient background | Style |
| `mac-tile` | macOS 11 to 15 | Continuous rounded square inset on the canvas | Drop shadow below the tile; selected groups may extend past it | Style |
| `gloss` | iOS 1 to 6 | Circular rounded square | Shine highlight over the upper half | Style |

## Sources

- **Liquid Glass.** Apple's
  [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
  describe layered icons that "take on Liquid Glass attributes", the
  appearances, and the platform masks. Its change log dates layered Liquid
  Glass icons to June 2025 and dark and tinted iOS icons to June 2024.
  [Say hello to the new look of app icons](https://developer.apple.com/videos/play/wwdc2025/220/)
  and [Create icons with Icon Composer](https://developer.apple.com/videos/play/wwdc2025/361/)
  cover the design and the tool. Icon Composer 27 renders design generations
  26 and 27.
- **flat.** Apple's iOS 7 announcement,
  [Apple Unveils iOS 7](https://www.apple.com/newsroom/2013/06/10Apple-Unveils-iOS-7/),
  describes a redesigned interface. The outline is measured from Apple's
  iOS 18 production template.
- **mac-tile.** Apple's
  [macOS Big Sur announcement](https://www.apple.com/newsroom/2020/06/apple-introduces-macos-big-sur-with-a-beautiful-new-design/)
  describes Dock icons made consistent with Apple's other platforms while
  keeping a Mac personality, and
  [Adopt the new look of macOS](https://developer.apple.com/videos/play/wwdc2020/10104/)
  covers the icon grid. Outline and shadow are measured from Apple's macOS 15
  production template. Objects in icons of this style sometimes extend past
  the tile; `unclipped` groups support that.
- **gloss.** Apple's
  [`UIPrerenderedIcon`](https://developer.apple.com/documentation/bundleresources/information-property-list/uiprerenderedicon)
  key records whether an icon "contains a shine effect", the highlight the
  system added in that era. No Apple template for this generation remains
  available; its corner and highlight are approximations.

## Platform Notes

- watchOS and visionOS mask icons to circles; keep content centered.
- tvOS icons are layered rectangles with a parallax effect and are outside
  this skill's renderers.
- Apple ships only Liquid Glass today. Earlier styles suit web apps, other
  platforms, and design exploration.
