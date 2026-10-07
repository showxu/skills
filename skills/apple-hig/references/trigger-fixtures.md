# Trigger Fixtures

Use these examples to check whether `apple-hig` is being selected for the right
kind of work. These are routing fixtures, not user-facing canned responses.

## Should Trigger

- "Review this SwiftUI settings screen for Apple visual fit."
- "Does this custom SwiftUI row follow HIG?"
- "Check whether this sidebar should use `List` with sidebar style."
- "What Apple Design Resources should I use for macOS UI baseline?"
- "Can these Apple UI kit or SF Symbols resources be downloaded?"
- "What are the HIG minimum target sizes for a custom SwiftUI button?"
- "Audit this iPadOS layout against HIG safe areas and split-view behavior."
- "Score this iOS onboarding screen against Apple HIG and list the top fixes."
- "Compare these two macOS settings layouts with a HIG scorecard."
- "Are these custom colors, materials, and icons too far from Apple defaults?"
- "Use HIG to decide whether this menu, sheet, popover, or alert is appropriate."
- "Does this SwiftUI interface need a native primitive before custom drawing?"

## Should Not Trigger

- "Fix this SwiftUI compile error."
- "Refactor this SwiftUI view architecture."
- "Why is this NavigationSplitView state not updating?"
- "Profile this SwiftUI list performance issue."
- "Debug this Xcode build failure."
- "Implement the ButtonStyle in code."
- "Create App Store screenshots."
- "Write App Store metadata or ASO copy."
- "Pick a brand color palette for a non-Apple website."
- "Design the business onboarding flow from scratch."

## Ambiguous: Pair Or Route Elsewhere

- "Review this onboarding flow on iOS."
  Use `interaction-design` first when task flow is the main problem; use
  `apple-hig` for platform component and HIG conformance.
- "Make this SwiftUI app look more Apple-like."
  Use `apple-hig` for HIG, native primitive, metrics, and resource guidance;
  route code edits to an engineering skill.
- "Prepare a design handoff for a SwiftUI implementation."
  Use `interaction-design` for states and acceptance criteria, and `apple-hig`
  for Apple-platform constraints.
