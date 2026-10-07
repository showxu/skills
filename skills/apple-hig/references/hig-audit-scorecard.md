# HIG Audit Scorecard

Use this reference when the user asks for a scored Apple-platform interface
audit, a quick HIG compliance pass, or a comparable Apple-like quality review.
This is a review heuristic, not an official Apple certification or App Store
review prediction.

Keep official Apple HIG pages, Apple Design Resources, and current framework
documentation as the authority for exact requirements. Use the scorecard to
structure findings and avoid omissions.

## When To Use

- The user asks to audit, score, compare, or rate an Apple-platform screen,
  flow, prototype, screenshot, or SwiftUI-adjacent interface.
- The user wants a concise executive summary plus prioritized fixes.
- Multiple candidate designs need comparable HIG review output.

## When Not To Use

- Do not score when the target platform, screen scope, or artifact is unclear.
- Do not present a score as App Store approval, Apple certification, or official
  HIG compliance.
- Do not use one platform's numeric target-size rule for every platform.
- Do not let a score replace concrete findings with source basis and impact.

## Scorecard

Default weighting:

| Area | Points | Review focus |
| --- | ---: | --- |
| Visual and native-system fit | 20 | System typography, semantic colors, materials, SF Symbols, native primitives, legibility, dark/high-contrast adaptation |
| Navigation and layout | 20 | Platform-appropriate navigation, safe areas, split/sidebar/tab patterns, information density, orientation/window adaptation |
| Accessibility | 30 | VoiceOver semantics, Dynamic Type, contrast, target size, Reduce Transparency, Reduce Motion, keyboard/focus/switch access as relevant |
| Interaction and motion | 20 | Standard gestures, feedback, haptics where appropriate, predictable transitions, motion restraint and fallbacks |
| Platform integration | 10 | Platform-specific conventions such as macOS menus/shortcuts, iOS Live Activities/Dynamic Island only when relevant, watch complications, visionOS ornaments/depth |

Scoring guidance:

- Use `0` when the area is absent or actively harmful.
- Use about half credit when the surface is usable but has meaningful platform
  or accessibility gaps.
- Use most credit when issues are minor and well-scoped.
- Mark `not applicable` instead of forcing points for platform features that
  do not belong to the app or surface.

## Quick Checklist

Visual and native-system fit:

- Uses system text styles or a justified custom type system.
- Uses semantic system colors before hardcoded palettes.
- Uses native controls, lists, forms, tables, sidebars, toolbars, or materials
  before custom-drawn equivalents.
- Keeps translucent or material surfaces legible in light, dark, high contrast,
  and Reduce Transparency contexts.
- Uses SF Symbols when symbol semantics fit.

Navigation and layout:

- Names the target platform and device class.
- Uses a platform-appropriate navigation model: tabs/navigation stacks on iOS
  when appropriate, sidebars/split views on iPadOS and macOS when appropriate,
  ornaments and spatial hierarchy on visionOS when appropriate.
- Respects safe areas, Dynamic Island, home indicator, window chrome, rounded
  display corners, and pointer/focus contexts where relevant.
- Avoids custom density, spacing, or hierarchy choices that make the native
  primitive hard to recognize.

Accessibility:

- Every meaningful control has a label, role, and useful hint when needed.
- Text scales with Dynamic Type or the platform equivalent without clipping key
  content.
- Contrast is checked in supported appearances and against translucent
  backgrounds.
- Interactive targets satisfy the current platform-specific HIG guardrail or
  preserve a larger interactive region through padding/content shape.
- The design remains usable with Reduce Motion, Reduce Transparency, grayscale,
  Switch Control, keyboard, pointer, or focus input as relevant.

Interaction and motion:

- Standard platform gestures and controls behave predictably.
- Feedback is timely and not dependent on sound, color, or motion alone.
- Haptics are used only where platform and interaction semantics support them.
- Motion communicates state or hierarchy without becoming decorative or
  disorienting.

Platform integration:

- macOS surfaces expose conventional menus, keyboard shortcuts, windowing, and
  toolbar/sidebar behavior when relevant.
- iOS and iPadOS surfaces use system presentations, safe areas, multitasking,
  and background-status surfaces only when they support the task.
- watchOS surfaces optimize for glanceable vertical interaction and Digital
  Crown use when relevant.
- visionOS surfaces account for depth, ornaments, gaze/pinch input, comfort,
  and spatial hierarchy when relevant.

## Output Shape

```text
Apple HIG Scorecard

Platform:
- ...

Scope:
- ...

Scores:
- Visual and native-system fit: <score>/20
- Navigation and layout: <score>/20
- Accessibility: <score>/30
- Interaction and motion: <score>/20
- Platform integration: <score>/10
- Total: <score>/100

Score confidence:
- High | Medium | Low, with reason

Findings:
- Surface:
  Issue:
  Evidence:
  HIG or source basis:
  Impact:
  Recommendation:

Priority fixes:
- P1:
- P2:
- P3:

Not scored / needs verification:
- ...
```

## Decision Rules

- Every nontrivial point deduction needs an observed issue and a concrete
  recommendation.
- Every exact numeric claim needs a current Apple source or the local
  `swiftui-hig-metrics.md` reference.
- Prefer category-level `not applicable` over penalizing a surface for not
  using irrelevant platform features.
- Keep score confidence low when the artifact is only text description, cropped
  screenshots, incomplete code, or missing target device class.
- For implementation requests, return the HIG constraints and route code work
  to the appropriate engineering owner.
