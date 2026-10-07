# SwiftUI HIG Metrics

Use this reference when a SwiftUI-adjacent Apple-platform review needs numeric
guardrails. Prefer SwiftUI system primitives and platform styles first; use
these numbers to audit custom components, custom typography, custom hit areas,
or platform-specific exceptions.

Verify current Apple pages before enforcing a number. HIG pages are
JavaScript-rendered; their machine-readable data currently follows this pattern:

`https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<slug>.json`

To refresh the raw evidence, run:

```bash
python3 skills/apple-hig/scripts/extract_hig_metrics.py \
  --output /tmp/apple-hig-metrics.md
```

Add `--include-large-tables` when device-size and size-class matrices are part
of the review.

To verify extractor behavior without network access, run:

```bash
PYTHONDONTWRITEBYTECODE=1 \
  skills/apple-hig/scripts/test_extract_hig_metrics.py
```

## Source Pages

- Accessibility:
  https://developer.apple.com/design/human-interface-guidelines/accessibility
- Color:
  https://developer.apple.com/design/human-interface-guidelines/color
- Typography:
  https://developer.apple.com/design/human-interface-guidelines/typography
- Layout:
  https://developer.apple.com/design/human-interface-guidelines/layout
- Split views:
  https://developer.apple.com/design/human-interface-guidelines/split-views
- Sidebars:
  https://developer.apple.com/design/human-interface-guidelines/sidebars
- Tab bars:
  https://developer.apple.com/design/human-interface-guidelines/tab-bars
- Alerts:
  https://developer.apple.com/design/human-interface-guidelines/alerts
- Pull-down buttons:
  https://developer.apple.com/design/human-interface-guidelines/pull-down-buttons
- Motion:
  https://developer.apple.com/design/human-interface-guidelines/motion

## SwiftUI Interpretation

- Prefer `Text` with SwiftUI text styles, `Font.Design.default` or `.serif`,
  SF Symbols, `Button`, `Toggle`, `Picker`, `Menu`, `List`, `Table`, `Form`,
  `NavigationSplitView`, `TabView`, and native presentation modifiers before
  copying the raw metrics below into custom views.
- Treat a default value as the target for custom controls. Treat a minimum
  value as a floor for constrained cases, not as the normal design size.
- If an icon or label is visually smaller than the platform minimum control
  size, preserve a larger interactive region through padding, content shape, or
  native control styling.

## Type And Dynamic Type

Apple says people should be able to enlarge text or icons by at least 200
percent, or 140 percent in watchOS apps. In SwiftUI, start with system text
styles so Dynamic Type can scale without manual font tables.

When custom type is unavoidable, HIG gives these recommended default and
minimum sizes:

| Platform | Default size | Minimum size |
|---|---:|---:|
| iOS, iPadOS | 17 pt | 11 pt |
| macOS | 13 pt | 10 pt |
| tvOS | 29 pt | 23 pt |
| visionOS | 17 pt | 12 pt |
| watchOS | 16 pt | 12 pt |

Do not copy the full Dynamic Type tables into this skill. Query the current
Typography source when exact per-style, per-content-size values matter.

## Control Target Size

HIG gives default and minimum control sizes by platform:

| Platform | Default control size | Minimum control size |
|---|---:|---:|
| iOS, iPadOS | 44x44 pt | 28x28 pt |
| macOS | 28x28 pt | 20x20 pt |
| tvOS | 66x66 pt | 56x56 pt |
| visionOS | 60x60 pt | 28x28 pt |
| watchOS | 44x44 pt | 28x28 pt |

For spacing between controls, HIG says about 12 pt of padding works around
bezeled elements, and about 24 pt works around the visible edges of elements
without a bezel.

## Contrast

Apple Accessibility Inspector uses these WCAG Level AA values as guidance for
minimum acceptable contrast:

| Text size | Text weight | Minimum contrast ratio |
|---|---|---:|
| Up to 17 pts | All | 4.5:1 |
| 18 pts | All | 3:1 |
| All | Bold | 3:1 |

Check contrast in both light and dark appearances when the UI supports Dark
Mode.

## System Colors

HIG publishes each system color and system gray with four values: default and
increased contrast, each in light and dark appearances. Use them to judge
whether a custom hex color duplicates or drifts from a system color. In native
UI, prefer the semantic API named in the table, such as `Color.orange` or
`UIColor.systemGray`, so appearance and Increase Contrast adapt automatically.

Do not copy the color tables into this skill. Query the current values when a
finding depends on an exact color:

```bash
python3 skills/apple-hig/scripts/extract_hig_metrics.py \
  --slug color --max-snippets 0
```

## Navigation And Presentation

- Sidebars: show no more than two hierarchy levels in a sidebar. For deeper
  data, prefer a split view with an intermediate content list.
- Split views: the thin divider is 1 pt wide. By default, a split view gives
  one-third of the width to the primary pane and two-thirds to the secondary
  pane; half-and-half can also be specified.
- Pull-down buttons: listing at least three items can make the interaction feel
  worthwhile. For one or two items, consider direct buttons, toggles, or another
  native control.
- Alerts: across platforms, alerts include a title, optional informative text,
  and up to three buttons. In visionOS, an alert accessory view should have a
  maximum height of 154 pt and a 16 pt corner radius.
- Tab bars: if people can customize tabs, aim for a default list of five or
  fewer. On tvOS, the tab bar height is 68 pt and its top edge is 46 pt from
  the top of the screen.

## Platform-Specific Layout

- tvOS: inset primary content 60 pt from the top and bottom, and 80 pt from
  the sides.
- Motion for games: a consistent 30 to 60 fps generally feels smooth and
  visually appealing. This is game guidance, not a generic SwiftUI animation
  requirement.

## Do Not Treat As A Spacing Scale

These values are official guardrails, not a cross-platform spacing system. In
SwiftUI reviews, prefer semantic layout, safe areas, native containers, and
platform control styles. Only cite a number when the review finding depends on
that exact metric and the platform scope is named.
