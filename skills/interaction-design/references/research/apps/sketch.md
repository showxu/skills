# Sketch Research Report

## Product Positioning

Sketch is a mature macOS-native design tool with a documented file format,
developer API, component/symbol model, and built-in prototyping tools. For this
research, Sketch is both:

- a static design-file and UI-layer reference
- a baseline built-in prototype reference

Sketch is especially important for Apple-oriented work because Apple Design
Resources are distributed as Sketch files in addition to other formats. Those
resources are evidence for platform UI material, template organization, and
native visual-system structure. Sketch is not a deep interaction-logic donor in
the same sense as ProtoPie, Axure, Flinto, or Rive.

## Mature Workflow Shape

Sketch's mature workflow is file-first, artboard/frame-based, and optimized for
macOS design production:

1. Designers organize work into documents, pages, frames/artboards, groups,
   layers, symbols, libraries, shared styles, and export presets.
2. Reusable UI is modeled through symbols/components, symbol instances, nested
   symbols, and overrides.
3. Platform resources, including Apple templates, provide UI starting points,
   device frames, controls, and layout references.
4. Prototypes are built with links, hotspots, overlays, scroll areas, fixed
   layers, start points, layer visibility rules, and Smart Animate.
5. Preview happens in the Mac app, web app, or iOS app.
6. Handoff happens through exports, file format tooling, developer APIs, cloud
   sharing, and design-to-code pipelines.

The workflow is strongest for UI layer structure and designer-authored preview
flows. It is not a full product behavior, business-rule, or runtime state
machine system.

## Evidence Inventory

Official documentation:

- Sketch file format: https://developer.sketch.com/file-format/
- Sketch file format spec: https://developer.sketch.com/file-format/spec
- Sketch API reference: https://developer.sketch.com/reference/api
- Sketch prototyping overview: https://www.sketch.com/docs/prototyping/
- Links: https://www.sketch.com/docs/prototyping/adding-links/
- Hotspots: https://www.sketch.com/docs/prototyping/adding-hotspots/
- Overlays: https://www.sketch.com/docs/prototyping/overlays/
- Apple Design Resources: https://developer.apple.com/design/resources/

Local artifact/probe inventory, not source references:

- Apple iOS Sketch design template artifact:
  `references/research/artifacts/sketch/apple-ios18-templates-guides.sketch`
- Apple tvOS Sketch UI library artifact:
  `references/research/artifacts/sketch/apple-tvos-ui.sketch`
- Local extraction convention:
  `sketch-design` can extract `.sketch` ZIP/JSON facts into
  `design-context.json`, including layout, style, text, symbol, export,
  prototype, background, and source-property details. This is local tooling
  evidence for how to inspect Sketch artifacts, not a replacement for Sketch
  official file-format/API documentation.

Evidence priority:

1. Official Sketch file format, API, and prototyping docs.
2. Apple Design Resources as official platform UI/design evidence.
3. Local Sketch artifacts and probes as artifact confirmation.

## Schema Facts

Field-level facts to preserve for later schema work:

- UI tree: `Document`, `Page`, `Frame` / `Artboard`, `Layer`, `Group`,
  `Shape`, `Text`, `Image`, `Symbol`, `SymbolInstance`, `Override`,
  `SharedStyle`, `Library`, and `ExportPreset`.
- Prototype source: source layer or hotspot.
- Prototype target: target frame/artboard or overlay target.
- Trigger: link/hotspot activation, including click/tap-style activation and
  documented preview interactions.
- Action: navigate, show overlay, dismiss overlay, and scroll.
- Overlay fields: placement, outside interaction / dismissal behavior, and
  animation.
- Scroll fields: scroll area, scroll axis, fixed layer behavior, custom layer
  visibility, and maintain-scroll-position behavior.
- Transition / animation: animation type, timing, duration, Smart Animate, and
  matched-layer continuity.
- Local Apple resource probe fields:
  `MSImmutableFlowConnection.destinationArtboardID`, `interactionTrigger`,
  `interactionAction`, `animationType`, `animationTiming`, `duration`,
  `maintainScrollPosition`, and `shouldCloseExistingOverlays`.

## File / API / Artifact Model

Sketch files are inspectable design artifacts with documented structure and
developer-facing APIs.

Design model:

- `Document`
- `Page`
- `Frame` / `Artboard`
- `Layer`
- `Group`
- `Shape`
- `Text`
- `Image`
- `Symbol` / component source
- `SymbolInstance`
- `Override`
- `SharedStyle`
- `Library`
- `ExportPreset`
- asset files and previews

Prototype model:

- start point
- source layer
- hotspot
- link
- target frame/artboard
- overlay target
- overlay placement
- overlay dismissal / outside interaction
- scroll area
- scroll axis
- fixed layer behavior
- custom layer visibility
- Smart Animate matching
- animation type
- animation timing
- duration
- preview target

Apple resource model:

- platform templates and UI kits
- device and screen templates
- native control and surface references
- layout guidance encoded as design files
- reusable visual components and assets

## Interaction Model

Sketch's built-in interaction model is simple and explicit:

- A source layer or hotspot owns an interaction.
- The interaction targets another frame/artboard or overlay.
- The trigger is link activation such as click, tap, hover, press, or toggle
  depending on the prototype feature.
- The action is navigate, show overlay, dismiss overlay, or scroll.
- The transition defines presentation timing and animation.
- Start points define prototype entry locations.

Official prototyping docs confirm support for:

- links between frames
- hotspots with separately drawn clickable regions
- overlays for menus, modals, messages, dropdowns, and similar UI
- overlay default position, animation, and background behavior
- outside interaction modes such as no action, close overlay, or allow active
  links/hotspots behind the overlay
- scroll areas with vertical, horizontal, or multi-direction behavior
- fixed elements in scrolling prototypes
- custom layer visibility in previews
- multiple start points

Local Apple iOS Sketch templates confirmed baseline flow fields including:

- `MSImmutableFlowConnection.destinationArtboardID`
- `interactionTrigger`
- `interactionAction`
- `animationType`
- `animationTiming`
- `duration`
- `maintainScrollPosition`
- `shouldCloseExistingOverlays`

These fields are useful evidence, but local schema should not copy Sketch field
names directly where a cross-tool concept is clearer.

## UI Layer Model

Sketch is a strong UI-layer reference:

- documents and pages organize work
- frames/artboards define screen surfaces
- layers and groups define visual hierarchy
- symbols/components define reusable UI
- overrides define instance customization
- shared styles define reusable visual treatment
- libraries distribute reusable components and styles
- export presets define asset/handoff output
- Apple Design Resources provide platform UI evidence, device templates,
  native controls, screen patterns, and visual-system material

UI-layer data is not product behavior unless accepted through a product source
artifact or connected to prototype links, hotspots, overlays, state visibility,
or other explicit interaction evidence.

## State / Variable / Logic Model

Sketch state is lightweight and preview-oriented:

- overlay visibility
- layer visibility
- scroll position
- fixed element status
- symbol/component override state
- hotspot target override
- Smart Animate matched-layer continuity
- start-point selection

Sketch does not provide a deep variable, formula, conditional-logic, or state
machine system comparable to ProtoPie, Axure, Flinto, Rive, or dotLottie.
Business rules, permissions, validation, recovery, and product traceability
must come from local product artifacts or stronger interaction-logic donors.

## Motion / Runtime / Handoff Model

Sketch motion/prototype facts:

- animation type
- animation timing
- duration
- Smart Animate matched-layer interpolation
- overlay appearance and dismissal
- scroll behavior
- fixed layer behavior
- maintain-scroll-position behavior
- preview start points

Runtime/handoff facts:

- Sketch preview is a design/prototype projection, not product truth.
- The file format and developer APIs make Sketch useful for design-side
  inspection and future adapters.
- Apple Sketch resources are valuable UI-platform evidence, not a substitute
  for product interaction requirements.

## Confirmed / Inferred / Unknown

Confirmed:

- Sketch has public file format and API documentation.
- Sketch public prototyping docs cover links, hotspots, overlays, scroll areas,
  fixed elements, custom layer visibility, Smart Animate, start points, preview,
  and sharing.
- Apple Design Resources are official design evidence and include Sketch-based
  platform UI material.
- Local Apple iOS Sketch probes confirmed baseline flow/prototype fields.

Inferred:

- Sketch's prototype model maps cleanly to local surface, actor, trigger,
  action, transition, state, and animation concepts.
- Sketch is best treated as a baseline prototype donor and strong UI-layer
  donor rather than a complete interaction-logic donor.

Unknown:

- A modern custom `.sketch` sample covering every current prototyping feature
  has not been captured.
- Edge behavior for all trigger/overlay/Smart Animate combinations is not
  exhaustively verified.
- Full design-tool adapter requirements remain future work.

## Useful Later

- UI-layer model: document/page/frame/layer/group/symbol/instance/override/
  shared-style/library/export-preset
- Apple platform UI evidence through official Sketch resources
- simple prototype link model
- hotspot model for clickable regions independent of visual layers
- overlay positioning and outside-interaction semantics
- scroll-area and fixed-layer semantics
- Smart Animate as matched-layer transition evidence
- start-point and preview-target concepts

## Do Not Absorb

- exact Sketch file JSON paths as canonical local schema
- Apple resource visual layers as product behavior
- final Apple visual styling into the behavior DSL
- Sketch preview behavior as complete product logic
- Sketch-specific field names where local cross-tool concepts are clearer
- a requirement that all Apple-native prototype projection must pass through
  Sketch
