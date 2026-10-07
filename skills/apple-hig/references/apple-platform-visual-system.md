# Apple Platform Visual System

Use this reference when an Apple-platform review is really about whether a UI
should follow Apple's native visual system instead of inventing custom
components, tokens, or layout idioms.

Do not copy Apple documentation into this repository. Verify current official
pages before making exact claims.

## Authority Stack

1. Human Interface Guidelines define the visual, interaction, platform, and
   accessibility rules.
2. Apple Design Resources provide official UI kits, fonts, SF Symbols, icon
   templates, and other asset baselines.
3. Apple framework documentation, including SwiftUI, UIKit, and AppKit docs,
   defines which native primitives are available for implementation.
4. Apple system apps are empirical donors when official docs give the principle
   but not enough concrete layout detail.

## Native Primitive Gate

For SwiftUI-adjacent work, prefer these native primitives before custom visual
layers:

- `NavigationSplitView`, `NavigationStack`
- `List`, `Table`, `Form`, `Section`, `LabeledContent`
- `Toggle`, `Picker`, `Button`, `Menu`, `ToolbarItem`
- `TextField`, `searchable`
- inspectors, sheets, popovers, alerts, toolbars, and platform-native
  presentation APIs

If recommending a custom component, first state which native primitive was
considered and why it is insufficient for the product task, platform behavior,
data shape, accessibility requirement, or presentation context.

## Default Visual Rules

- Use system fonts and Dynamic Type or platform text styles before defining a
  custom typography scale.
- Use semantic system colors before defining custom hex palettes.
- Use system materials and platform translucency behavior before custom glass
  or blur effects.
- Use SF Symbols before custom icon systems when the symbol semantics fit.
- Use platform list, form, table, sidebar, toolbar, split-view, and settings
  patterns before custom-drawn equivalents.
- Preserve dark mode, contrast, transparency, accessibility, localization,
  pointer, keyboard, focus, and size-class adaptation.

## Donor Calibration

Use donor apps only as layout evidence, not as a license to copy private or
unrelated product behavior.

| Product Surface | Primary Donors |
|---|---|
| Settings or preferences UI | System Settings |
| Document libraries, notebooks, or books | Finder, Notes |
| Workbenches, API maps, graphs, symbol browsers | Xcode, Instruments |
| Menu bar utilities | macOS menu bar apps, Control Center |
| Document or PDF viewers | Preview, Books |
| Tables, indexes, inspectors, property panels | Xcode navigator, Xcode inspector |

## Resource Access

Apple Design Resources are not all the same kind of artifact.

- Direct Apple CDN files such as `devimages-cdn.apple.com/.../*.dmg` can usually
  be fetched directly and inspected as versioned design assets.
- Apple Developer Downloads pages, such as Icon Composer search results, can
  require Apple Developer authentication before the final installer is visible.
- Figma community links and Sketch share links are external source links, not
  repository-local assets. Treat them as references unless the user explicitly
  asks to import or inspect them.
- `sketch://add-library?...` links require the Sketch app. Do not describe
  them as command-line-downloadable files.

## Handoff Rule

When implementation is requested, keep this skill at the design-authority level:
produce the HIG concern, the system primitive or resource to prefer, and the
reason a custom visual layer is or is not justified. Route code changes to the
appropriate engineering skill.
