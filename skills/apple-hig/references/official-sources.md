# Official Sources

Use current Apple documentation as the authority for Apple-platform interface
guidance. Do not copy HIG pages into this repository.

## Source Hierarchy

1. Current Apple Human Interface Guidelines:
   https://developer.apple.com/design/human-interface-guidelines
2. HIG foundations pages for visual and interaction primitives:
   - Accessibility:
     https://developer.apple.com/design/human-interface-guidelines/accessibility
   - Color:
     https://developer.apple.com/design/human-interface-guidelines/color
   - Dark Mode:
     https://developer.apple.com/design/human-interface-guidelines/dark-mode
   - Icons:
     https://developer.apple.com/design/human-interface-guidelines/icons
   - Layout:
     https://developer.apple.com/design/human-interface-guidelines/layout
   - Materials:
     https://developer.apple.com/design/human-interface-guidelines/materials
   - Motion:
     https://developer.apple.com/design/human-interface-guidelines/motion
   - Typography:
     https://developer.apple.com/design/human-interface-guidelines/typography
   - Writing:
     https://developer.apple.com/design/human-interface-guidelines/writing
3. HIG component and pattern pages for native Apple interface semantics:
   - Alerts:
     https://developer.apple.com/design/human-interface-guidelines/alerts
   - Buttons:
     https://developer.apple.com/design/human-interface-guidelines/buttons
   - Lists and tables:
     https://developer.apple.com/design/human-interface-guidelines/lists-and-tables
   - Menus:
     https://developer.apple.com/design/human-interface-guidelines/menus
   - Navigation bars:
     https://developer.apple.com/design/human-interface-guidelines/navigation-bars
   - Pickers:
     https://developer.apple.com/design/human-interface-guidelines/pickers
   - Popovers:
     https://developer.apple.com/design/human-interface-guidelines/popovers
   - Pull-down buttons:
     https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons
   - Search fields:
     https://developer.apple.com/design/human-interface-guidelines/search-fields
   - Settings:
     https://developer.apple.com/design/human-interface-guidelines/settings
   - Sheets:
     https://developer.apple.com/design/human-interface-guidelines/sheets
   - Sidebars:
     https://developer.apple.com/design/human-interface-guidelines/sidebars
   - Split views:
     https://developer.apple.com/design/human-interface-guidelines/split-views
   - Tab bars:
     https://developer.apple.com/design/human-interface-guidelines/tab-bars
   - Text fields:
     https://developer.apple.com/design/human-interface-guidelines/text-fields
   - Toggles:
     https://developer.apple.com/design/human-interface-guidelines/toggles
   - Toolbars:
     https://developer.apple.com/design/human-interface-guidelines/toolbars
4. Apple Design Resources for official UI kits, fonts, SF Symbols, icon
   templates, and platform asset baselines:
   https://developer.apple.com/design/resources/
   - SF Symbols:
     https://developer.apple.com/sf-symbols/
   - Icon Composer:
     https://developer.apple.com/icon-composer/
   - Fonts:
     https://developer.apple.com/fonts/
5. Platform-specific Apple developer documentation when HIG pages link to or
   depend on implementation-specific behavior:
   - App Design and UI technology overview:
     https://developer.apple.com/documentation/technologyoverviews/app-design-and-ui
   - SwiftUI technology overview:
     https://developer.apple.com/documentation/technologyoverviews/swiftui
   - UIKit:
     https://developer.apple.com/documentation/uikit
   - AppKit:
     https://developer.apple.com/documentation/appkit
6. SwiftUI documentation when a recommendation depends on whether a system
   primitive exists:
   - SwiftUI:
     https://developer.apple.com/documentation/swiftui
   - NavigationSplitView:
     https://developer.apple.com/documentation/swiftui/navigationsplitview
   - List:
     https://developer.apple.com/documentation/swiftui/list
   - Table:
     https://developer.apple.com/documentation/swiftui/table
   - Form:
     https://developer.apple.com/documentation/swiftui/form
   - searchable:
     https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)
   - inspector:
     https://developer.apple.com/documentation/swiftui/view/inspector(ispresented:content:)
7. Secondary official context. Use these for learning, examples, and direction,
   not as stronger authority than HIG or framework documentation:
   - Apple Design:
     https://developer.apple.com/design/
   - What's new in Apple design:
     https://developer.apple.com/design/whats-new/
   - Apple Design videos:
     https://developer.apple.com/videos/design/
   - Design tips:
     https://developer.apple.com/design/tips/
   - Apple Design Awards:
     https://developer.apple.com/design/awards/
   - SwiftUI tutorials:
     https://developer.apple.com/tutorials/swiftui
   - SwiftUI getting started:
     https://developer.apple.com/swiftui/get-started/

## Resource Access Examples

Examples of direct Apple CDN resources to probe before use:

- SF Pro:
  https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg
- SF Compact:
  https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg
- SF Mono:
  https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg
- SF Symbols 7:
  https://devimages-cdn.apple.com/design/resources/download/SF-Symbols-7.dmg?2
- iOS 18 Sketch design templates:
  https://devimages-cdn.apple.com/design/resources/download/iOS-18-Design-Templates-Sketch.dmg
- macOS Sequoia Sketch design templates:
  https://devimages-cdn.apple.com/design/resources/download/macOS-Sequoia-Design-Templates-Sketch.dmg
- visionOS 2 Sketch design templates:
  https://devimages-cdn.apple.com/design/resources/download/visionOS-2-Design-Templates-Sketch.dmg

## Lookup Guidance

- Verify the relevant current Apple page before asserting exact requirements,
  component conventions, platform differences, or accessibility details.
- Cite the specific Apple page in the review when a recommendation depends on
  official guidance.
- Treat Design Resources as source links and asset baselines, not as content to
  copy into the repository.
- Distinguish direct Apple CDN downloads from Developer Downloads pages,
  external Figma or Sketch links, and `sketch://` app links before promising a
  resource can be pulled down automatically.
- For SwiftUI-adjacent reviews, verify that a native control, container, style,
  or presentation API cannot express the design before recommending a custom
  visual layer.
- If official pages require JavaScript in the current environment, keep the
  claim evidence-limited or use an Apple-provided accessible source path before
  treating it as authoritative.
