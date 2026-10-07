---
name: apple-hig
description: Guide, review, audit, score, or compare Apple platform interface decisions and structured platform context against current Apple Human Interface Guidelines. Use for Apple HIG compliance, scored HIG audits, Apple-platform quality scorecards, prioritized interface fixes, SwiftUI visual-system guidance, native control or primitive selection, Apple Design Resources needs, platform metrics, iOS, iPadOS, macOS, watchOS, tvOS, or visionOS navigation, controls, sheets, alerts, layout, safe areas, accessibility, motion, input, and platform convention checks. Do not use for owning product behavior, mutating source artifacts, fetching or downloading Apple design resources, writing or debugging SwiftUI/UIKit/AppKit code, business task-flow design, App Store operations, visual brand templates, or non-Apple platform guidance.
---

# Apple HIG

## Purpose

Use this skill to check Apple-platform interface decisions against the current
Apple Human Interface Guidelines. Focus on platform conventions, components,
accessibility, motion, layout constraints, visual-system defaults, and
interaction expectations.

Use the HIG as the visual and interaction authority, Apple Design Resources as
the asset and design-token authority, and Apple framework documentation as the
native primitive authority. This skill should prevent unnecessary custom
Apple-platform visual systems; it should not become an implementation skill.

This skill does not own the product's business flow, state model, branch
points, or recovery rules. If structured platform context is provided, use it
as review evidence for related Apple-platform interaction choices. Return Apple
platform convention guidance, findings, or proposed deltas; do not mutate source
artifacts.

## When To Use

- Review an iOS, iPadOS, macOS, watchOS, tvOS, or visionOS screen or flow for
  Apple platform fit.
- Produce a scored HIG audit or Apple-platform quality scorecard when the user
  asks to audit, rate, compare, or prioritize fixes for a screen or flow.
- Review structured platform context for Apple native platform fit, including
  primary platform, secondary platforms, navigation, presentation, input
  methods, platform constraints, and adaptation notes.
- Review SwiftUI UI for HIG fit, visual-system defaults, native primitive
  choice, platform metrics, or unnecessary custom drawing.
- Check navigation patterns, bars, tabs, sidebars, sheets, popovers, alerts,
  menus, buttons, toggles, pickers, forms, lists, and toolbars against HIG.
- Check Apple-platform accessibility, focus, touch or pointer targets, motion,
  input method, safe area, layout, and system affordance expectations.
- Check whether custom colors, typography, materials, icons, sidebars, lists,
  tables, forms, settings rows, or row controls are replacing Apple system
  primitives without a documented need.
- Identify when Apple Design Resources, SF Symbols, fonts, UI kits, icon
  templates, or product bezels are needed; use `apple-design-resource` for
  fetch, catalog, probe, or download operations.
- Refresh or cite HIG numeric guardrails or system color values for
  SwiftUI-adjacent review.
- Convert generic interaction intent into Apple-platform UI guidance.
- Identify when an existing product surface also needs separate design-side UX
  review.

## When Not To Use

- Defining the user's business task, journey, state model, or recovery flow
  from scratch.
- Owning, rewriting, or mutating source artifacts; return convention findings
  or proposed deltas instead.
- Writing SwiftUI, UIKit, or AppKit implementation code, or debugging
  implementation behavior. Pass HIG and primitive constraints to an engineering
  skill when code changes are needed.
- SwiftUI architecture, state management, compile errors, performance,
  rendering bugs, Xcode build issues, or simulator/debugger work.
- App Store screenshots, ASO, App Store Connect, submission, or review
  operations.
- `DESIGN.md` template selection or visual identity templates.
- Non-Apple platform guidance unless the user asks for an Apple comparison.

## Inputs To Inspect

- Target Apple platform and device class.
- Screenshot, wireframe, prototype, spec, product flow, or component list.
- User task and risk level when it affects platform choices.
- Existing implementation constraints only when they affect HIG feasibility.
- Current official Apple HIG pages relevant to the decision.
- Current Apple Design Resources catalog from `apple-design-resource` or Apple
  framework documentation when a recommendation depends on design tokens,
  assets, or native controls.

## Workflow

1. Identify platform, device class, input method, and screen or flow scope.
2. Separate product-flow questions from Apple-platform questions. Mark
   unresolved product behavior or artifact generation as out of scope before
   treating it as HIG review input.
3. If structured interaction or platform context is provided, inspect the
   relevant platform, screens, states, actions, transitions, feedback, and open
   decisions as review input rather than source material to overwrite.
4. Identify the HIG surfaces involved: navigation, layout, controls, modal
   presentation, feedback, accessibility, motion, input, and system patterns.
5. For SwiftUI/UIKit/AppKit-adjacent design work, identify the system primitive
   that should be tried first before recommending custom drawing or custom
   controls.
6. Verify mutable rules against current official Apple pages before making them
   authoritative.
7. If the user asks for a scored audit, use
   `references/hig-audit-scorecard.md` as the output frame. Treat the score as
   a review heuristic, not official Apple certification.
8. Report concrete issues by platform surface: observed choice, HIG concern,
   native primitive or system resource to prefer, impact, and recommended
   adjustment.
9. Keep recommendations at design guidance level. Hand implementation details
   to SwiftUI/UIKit/AppKit skills when code changes are needed.

## Reference Files To Consult

- `references/official-sources.md`: official Apple HIG source hierarchy and
  lookup guidance.
- `references/apple-platform-visual-system.md`: HIG, Apple Design Resources,
  SwiftUI primitive, and donor-app decision rules.
- `references/swiftui-hig-metrics.md`: official HIG numeric guardrails and the
  system color query that are useful when reviewing SwiftUI-adjacent UI.
- `references/hig-audit-scorecard.md`: optional scorecard and quick checklist
  for requested HIG audit, scoring, comparison, or prioritized-fix reports.

Read these references when you need source links or when platform guidance may
have changed.
Use `apple-design-resource` when the task needs current resource URLs,
reachability, downloadable direct Apple CDN assets, or Product Bezels/brand
asset cataloging.

## Decision Rules

- Apple official HIG and current Apple developer documentation override generic
  interaction heuristics for Apple-platform work.
- Treat SwiftUI/UIKit/AppKit system controls, platform list/form/table/sidebar
  styles, semantic colors, system fonts, SF Symbols, system materials, and
  adaptive presentation APIs as the default visual system.
- Prefer standard Apple components and system patterns unless the product task
  justifies a custom interaction.
- Do not recommend custom colors, spacing scales, typography scales, icon
  systems, glass or material effects, sidebars, tables, settings rows, or row
  controls until the recommendation states why the native Apple primitive is
  insufficient.
- Do not invent exact HIG requirements from memory. Verify current official
  guidance when the claim affects the recommendation.
- Do not present a scorecard score as App Store approval, Apple certification,
  or complete HIG compliance.
- Do not flatten platform differences. iOS, iPadOS, macOS, watchOS, tvOS, and
  visionOS can have different navigation, input, layout, and focus norms.
- If a HIG constraint changes the user's flow, mark the change as a product
  decision and return it as a proposed delta.
- Prototypes, screenshots, and design frames are review artifacts. Do not treat
  them as authority to mutate source artifacts.

## Validation Rules

- The platform and device class are named.
- Each finding maps to a specific screen, component, interaction, or state.
- HIG-backed findings distinguish official guidance from design judgment.
- SwiftUI/UIKit/AppKit-adjacent findings name the native primitive considered
  before recommending custom visuals.
- Numeric recommendations name the Apple source and platform scope.
- Scorecard output names the scored scope, confidence, and evidence behind
  nontrivial deductions.
- Accessibility, input method, and motion are considered when relevant.
- Implementation requests are routed to an engineering skill instead of being
  solved here.

## Output Format

```text
Apple HIG Review

Platform:
- ...

Findings:
- Surface: ...
  Issue:
  HIG basis:
  Native primitive or resource:
  Impact:
  Recommendation:

Needs UX review:
- ...

Proposed source-artifact deltas:
- ...

Needs implementation skill:
- ...
```

## Failure / Uncertainty Handling

- If the Apple platform is unclear, ask for the target platform before making
  platform-specific claims.
- If current official guidance cannot be verified, mark the recommendation as
  needing HIG verification instead of presenting it as authoritative.
- If the artifact is missing, ask for the smallest useful input: screenshot,
  flow description, platform, and target device class.
