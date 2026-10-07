# UI And Interaction Schema Facts

Status: promoted schema facts for future `UI Design Schema` and
`Interaction Design Schema` synthesis. This file does not define either final
schema and does not change the active `interaction-design` contract.

This file keeps only durable schema facts from the app reports and research
artifacts. It intentionally excludes audit receipts, command logs, temporary
paths, and authoring-process notes.

The research pipeline is:

```text
source observations and evidence records
-> research fact store
-> UI Design Schema / Interaction Design Schema synthesis
-> possible active skill contract changes after review
```

Per-app `*.schema.yaml` files may include `draft_schema_mapping`. Those mappings
are hypotheses for later synthesis only. They are not app facts, not validation
of the current local model, and not proof that the current schema should be kept.

## Evidence Grades

- `official_spec`: public formal specification.
- `official_api`: public API, plugin API, or developer API.
- `official_docs`: product documentation, help center, or product pages.
- `source_available`: inspectable source repository or runtime source.
- `artifact_probe`: local app-produced artifact probe stored under
  `references/research/artifacts/`.
- `inferred`: reasoned mapping from evidence; not a source format guarantee.

## Cross-App Object Vocabulary

| Schema area | Confirmed app facts | Evidence grade |
| --- | --- | --- |
| Surface | Figma `Canvas` / `Frame`, Sketch `Frame` / `Artboard`, Penpot `Board`, ProtoPie `Scene`, Flinto `Screen`, Principle `Artboard`, Rive `Artboard`, Axure `Page`, Origami layer root or composition context. | official API/docs/spec plus artifact probes |
| Actor | Figma `Node`, Sketch `Layer` / `Group` / `SymbolInstance`, Axure `Widget`, ProtoPie `Layer`, Flinto `RectLayer` / `GroupLayer` / `ScrollLayer` / `PathLayer`, Framer `Component`, Origami `Layer` or patch target, Rive listener target. | official API/docs plus artifact probes |
| Trigger / Event | Figma `Trigger`, ProtoPie `Trigger`, Axure `Event`, Sketch hotspot/link activation and `interactionTrigger`, Flinto `gesture` / timer link / scroll gesture descriptor, Rive listener/input/event, dotLottie state-machine event, Origami interaction input patch. | official API/docs/spec plus artifact probes |
| Action / Response | Figma `Action` / node action, ProtoPie `Response`, Axure `Action`, UXPin interaction action, Sketch navigate / show overlay / dismiss overlay / scroll action, Flinto `Link`, Penpot interaction action, dotLottie playback/action model. | official API/docs/spec plus artifact probes |
| Condition / Guard | dotLottie guard, Rive transition condition, Axure case condition, ProtoPie condition, Figma conditional action block, UXPin expression condition, Origami logic patch. | official spec/API/docs/source |
| State | Rive state, dotLottie state, Axure dynamic panel state, Flinto `BehaviorState` and layer-state maps, Sketch overlay/layer visibility and scroll position, Figma variant/component/variable/overlay/media state, UXPin component state. | official spec/API/docs plus artifact probes |
| State machine | Rive state machine, dotLottie state machine, Flinto behavior with behavior states, Axure dynamic panel state graph, ProtoPie trigger/response/variable logic, Origami patch graph state logic. | official spec/docs/source plus artifact probes |
| Transition | Figma transition on node actions, Sketch destination/animation/duration/scroll-preservation fields, Flinto `Transition` and `Link.transitionId`, Rive/dotLottie state transition, Principle transition/driver, Axure page or panel transition. | official API/docs/spec plus artifact probes |
| Animation / Motion | Figma dissolve/smart animate/scroll animate/move/push/slide/easing/duration/spring, Sketch Smart Animate and animation timing, Flinto transition animations and spring timing objects, Principle timelines/drivers, Rive animation timelines, dotLottie playback actions. | official API/docs/spec/source plus artifact probes |
| Variable | Figma variable and variable mode, ProtoPie variable and component variable, Axure variable, UXPin variable, Rive input/view-model value, Framer prop/property control. | official API/docs/spec/source |
| Expression | ProtoPie formula, Axure expression, UXPin expression, Figma conditional expression, Origami logic/math patch. | official docs/API/source |
| Runtime binding | Rive runtime input/data binding/event, Origami input/output ports and cable connections, Framer props/overrides/event handlers, UXPin Merge/code-backed component binding, Figma media runtime controls. | official API/docs/source |
| External message | ProtoPie Send/Receive channel/message, Principle messages, Rive events, Origami data/API patches. | official docs/API/source |
| Source evidence | Figma REST/Plugin API, Sketch file format/API/prototyping docs, Penpot source/docs, dotLottie spec, Rive runtime docs/source, local Flinto/Figma/Sketch/ProtoPie/Axure/Origami/Rive artifacts. | mixed |
| Coverage gap | Reported missing or unsupported fields, source IDs, represented screens/states/actions/transitions, and artifact projection gaps. | local schema need |

## Behavior-Layer Facts

Behavior facts are product interaction facts, not final visual design. Across the
reference apps, durable behavior-level schema facts are:

- A behavior model needs stable surfaces/screens because Figma, Sketch, Penpot,
  ProtoPie, Flinto, Principle, Axure, and Rive all attach interaction or runtime
  behavior to named visual/runtime surfaces.
- A behavior model needs actors because interactions attach to nodes, layers,
  widgets, components, hotspots, scroll layers, listeners, patches, or other
  concrete participants.
- Triggers/events and actions/responses are separate concepts in several mature
  systems:
  - Figma: `Reaction = trigger + actions[]`.
  - ProtoPie: trigger starts one or more responses.
  - Axure: event can contain cases, conditions, and actions.
  - Flinto: link combines source actor/screen behavior with gesture, target, and
    transition references.
  - Rive/dotLottie: events or inputs drive state-machine transitions.
- Conditions/guards are first-class in dotLottie, Rive, Axure, ProtoPie, Figma,
  UXPin, and Origami.
- A behavior model needs state scope because states can belong to different
  owners:
  - screen/surface state
  - component state
  - overlay or layer visibility state
  - scroll position state
  - runtime animation state
  - variable/input state
  - dynamic panel or behavior-state scope
- A transition should be separable from animation presentation. Mature systems
  often bind navigation or state change to a presentation transition, but the
  state/screen change and the visual motion are not the same fact.
- Variables, expressions, and messages are useful schema areas, but they should
  be scoped and typed. ProtoPie, Figma, Axure, UXPin, Rive, Framer, and Origami
  each expose different runtime or prototype-local state mechanisms.

## UI-Layer Facts

UI-layer facts describe what can be drawn or arranged. They do not become product
behavior unless connected to accepted behavior facts.

| App | UI-layer facts |
| --- | --- |
| Figma | File, document, canvas/page, section, frame, group, node, component, component set, instance, variants, component properties, variables, styles, auto layout, constraints, scroll behavior, fills, strokes, effects, exports. |
| Sketch | Document, page, frame/artboard, layer, group, shape, text, image, symbol/component, symbol instance, override, shared style, library, export preset, Apple design resource templates. |
| Penpot | File, page, board, shape, component, design token, export package, plugin/source-available data model. |
| Axure | Page, widget, dynamic panel, panel state, repeater, form input, generated HTML runtime representation. |
| ProtoPie | Scene, layer, imported design assets, component, component variables, layer properties targeted by responses. |
| Flinto | Screen, layer tree, group layer, rect/path layer, scroll layer, tags, connected layers, layer-state map. |
| Origami | Layer tree plus patch graph; patches, ports, cables, signals, and components influence layer output. |
| Rive | Artboard, vector/object layers, animation timelines, state machines, listener targets, view model / data binding. |
| Framer | Page, frame/layer, component, code component, props, property controls, overrides, route, CMS/runtime data. |

## Platform / Projection Facts

The reference apps separate product interaction from projection/runtime in
different ways. The useful schema facts are:

- Figma, Sketch, Principle, Flinto, Axure, ProtoPie, Framer, Rive, and dotLottie
  all treat preview/runtime output as a projection or executable artifact, not as
  the only source of model facts.
- Device or platform preview appears in multiple systems:
  - Figma: `PrototypeDevice`, flow start points, overlay and navigation
    presentation data.
  - Flinto: prototype metadata such as `screenSize`, `screenScale`, `platform`,
    `defaultStatusbarStyle`, and device preview behavior.
  - Sketch: preview targets, frame/artboard prototypes, Apple Design Resource
    templates.
  - Rive: runtime host chooses artboard/state machine and sets inputs.
- Native-app prototype projection needs a distinct platform expression layer so
  platform primitives, device bezels, input modes, safe-area constraints, and
  presentation patterns do not define new product behavior.

## App-Specific Schema Facts

### Figma

Source authority: official REST and Plugin APIs. Local `.fig` export is package
and vocabulary evidence only.

Confirmed schema facts:

- File tree: `File`, `Document`, `Canvas`, `Node`, `Frame`, `Section`, `Group`,
  `Component`, `ComponentSet`, `Instance`, variables, styles, exports.
- Prototype behavior is exposed through `node.reactions`.
- `Reaction` has `trigger` and `actions[]`; older singular `action` is
  deprecated.
- Trigger types include click/tap, hover, press, drag, mouse enter/leave/down/up,
  timeout/delay, keyboard/gamepad input, media hit, and media end.
- Action types include back, close, open URL, media control, set variable, set
  variable mode, conditional action blocks, and node actions.
- Node action navigation/presentation values include `NAVIGATE`, `SWAP`,
  `OVERLAY`, `SCROLL_TO`, and `CHANGE_TO`.
- Action fields can include destination IDs, transition, preserve-scroll,
  overlay relative position, reset video position, reset scroll position, and
  reset interactive component behavior.
- Transition presentation includes instant, dissolve, smart animate, scroll
  animate, move, push, slide, direction, duration, easing, cubic bezier, and
  spring behavior.
- Local `.fig` export is a ZIP package with `canvas.fig`, `thumbnail.png`,
  `meta.json`, and image assets.
- Local `canvas.fig` binary probe exposed internal field/type names such as
  `NavigationType`, `TransitionInfo`, `TransitionType`, `PrototypeDevice`,
  `prototypeInteractions`, `OverlayPositionType`, `scrollDirection`,
  `layoutSize`, and constraint names.

### Sketch

Source authority: official file format, API, prototyping docs, and Apple Design
Resources.

Confirmed schema facts:

- Design model includes document, page, frame/artboard, layer, group, shape,
  text, image, symbol/component, instance, override, shared style, library, and
  export preset.
- Prototype model includes start point, source layer, hotspot, link, target
  frame/artboard, overlay target, overlay placement, overlay dismissal/outside
  interaction, scroll area, scroll axis, fixed layer behavior, custom layer
  visibility, Smart Animate matching, animation type/timing/duration, and
  preview target.
- Apple iOS Sketch resource probes confirmed baseline flow fields:
  `MSImmutableFlowConnection.destinationArtboardID`, `interactionTrigger`,
  `interactionAction`, `animationType`, `animationTiming`, `duration`,
  `maintainScrollPosition`, and `shouldCloseExistingOverlays`.
- Apple iOS Sketch resource probes also confirmed default prototype/platform
  fields: `isFlowHome`, `prototypeVisibility`, `prototypeVisibilityTrigger`,
  `hasCustomPrototypeVisibility`, `prototypeScrolling`,
  `prototypeScrollingArea`, `prototypeViewport`, `isFixedToViewport`,
  `overlayBackgroundInteraction`, and `presentationStyle`.
- Sketch state is lightweight: overlay visibility, layer visibility, scroll
  position, fixed layer status, symbol/component override state, and Smart
  Animate matched-layer continuity.

### Flinto

Source authority: official Learn docs for concepts; local `.flinto` probes for
artifact field taxonomy. Private field names are artifact evidence, not stable
public schema.

Confirmed schema facts:

- `.flinto` files in the local probes are Apple binary property list /
  `NSKeyedArchiver` archives.
- Flinto app metadata declares document UTI `com.flinto.prototype`, extension
  `flinto`, package-document capability, and document class `Flinto.Document`.
  The saved local probes themselves are binary archives rather than directory
  packages.
- Enriched local artifact root is `Flinto.Prototype` with 965 archived objects.
- Observed prototype fields include `sublayers`, `transitions`, `behaviors`,
  `homeScreenId`, `screenSize`, `screenScale`, `platform`,
  `defaultTimingFunction`, `defaultStatusbarStyle`, `showTapHints`, and
  `importedFromSketch`.
- Observed screen fields include `name`, `links`, `sublayers`, `behaviorIds`,
  `currentBehaviorStateIds`, `behaviorTagLayerMaps`, `timerLinkEnabled`,
  `statusbarStyle`, `orientation`, `canvasFrame`, `_bounds`, `_position`,
  `_canvasPosition`, and `resetOnLeave`.
- Observed link fields include `targetScreenId`, `transitionId`, `gesture`,
  `timeout`, `backLink`, `ignoreHistory`, `skipAnimation`, `isReversed`,
  `allowsOvershoot`, `scrollGestureOptions`, `stateChangeDefinition`,
  `fromScreenTagLayerMap`, `toScreenTagLayerMap`, and
  `forceGesturePressureRange`.
- Observed transition fields include `fromScreen`, `toScreen`,
  `connectedLayers`, `layerOrder`, `statusbarAnimation`, `createdAt`,
  `_screenAligned`, and `name`.
- Built-in transition-preset resources expose additional transition-authoring
  field signals such as `screenParameters`, `layerParameterMap`, `allTags`,
  `animations`, `timing`, `delay`, `duration`, `kind`, `tension`, `friction`,
  `velocity`, and `UUID`.
- Behavior model facts include `Behavior`, `BehaviorState`,
  `StateChangeDefinition`, `tagLayerStateMap`, `timerLink`, `linkLayers`, and
  layer-state `valueMap`.
- Scroll model facts include `_contentOffset`, `_contentSize`, `_clippingRect`,
  vertical/horizontal scroll flags, bounce, directional lock, paging, page size,
  scroll indicator style, links, and sublayers.
- Motion timing facts include RK4 spring fields (`duration`, `delay`, `tension`,
  `friction`, `velocity`) and UIKit spring fields (`duration`, `delay`,
  `dampingRatio`, `velocity`).

### ProtoPie

Source authority: official docs and official sample availability. Local `.pie`
and `.piec` artifacts are opaque in this round.

Confirmed schema facts:

- Document model concepts include Pie, scene, layer, component, trigger,
  response, condition, variable, formula, Send/Receive, channel/message, and
  sensor.
- Trigger-response is the central interaction shape.
- Conditions can branch response execution.
- Variables and component variables provide mutable prototype state.
- Formulas compute dynamic values used by conditions, variables, or responses.
- Send/Receive exchanges messages across components, scenes, pies, devices, or
  external workflows.
- Sensors and device inputs are first-class high-fidelity prototype inputs.
- Local official `.pie` and `.piec` samples exist, but probes did not expose
  readable scene/layer/trigger/response/variable/formula field names.

### Rive

Source authority: official docs, runtime format docs, runtime source, and public
`.riv` runtime artifacts.

Confirmed schema facts:

- Runtime object model includes file/runtime asset, artboard, animation, state
  machine, state, transition, input, boolean input, number input, trigger input,
  listener, event, view model / data binding, and runtime binding.
- Runtime flow is host-controllable: load `.riv`, choose artboard/state machine,
  set inputs, listen for events, render output.
- Public `.riv` artifacts are runtime files and confirm the `RIVE` magic header.
  The local public batch covers state-machine baseline samples, toggle/switch
  controls, gesture/card interaction, avatar/creator interaction, and
  multi-expression character state.
- `.riv` is enough for runtime state-machine evidence; `.rev` is editor-source
  evidence and remains unavailable in this round.
- Rive state machines are useful as explicit state-machine/runtime-binding
  evidence, not as complete product screen-flow or business-rule evidence.

### dotLottie / LottieFiles State Machine

Source authority: official public spec/docs.

Confirmed schema facts:

- Package model includes manifest, animations, assets, themes, and state
  machines.
- State-machine model includes states, transitions, guards/conditions, inputs,
  events/interactions, and playback actions.
- dotLottie is the strongest open formal state-machine spec reference in the
  current research set.

### Origami Studio

Source authority: official docs and official app-bundle examples.

Confirmed schema facts:

- Patch graph model includes document/composition context, layers, patches,
  input ports, output ports, cables/connections, signals, components, published
  ports, and patch categories.
- Official examples cover interaction, navigation, layer, component, logic,
  loop, and animation categories.
- Origami is strongest for signal-flow, patch graph, and runtime-binding
  concepts, not product requirement semantics.

### Axure RP

Source authority: official docs/API and official app-bundle training files.

Confirmed schema facts:

- Functional prototype model includes project, page, widget, event, case,
  condition, action, target, dynamic panel, panel state, variable, expression,
  repeater, form input, and validation concepts.
- Dynamic panels and panel states are direct evidence for scoped component or
  surface state.
- Cases and conditions are direct evidence for guarded behavior branches.
- Generated HTML is a runtime projection, not source schema.

### UXPin

Source authority: official docs.

Confirmed schema facts:

- Realistic prototype model includes component, code-backed component, state,
  interaction, variable, condition, expression, form field, data binding,
  validation, React export, and design-system / Merge concepts.
- UXPin is useful for form/validation/code-backed component boundary facts.
- Current `.uxp` artifact field schema is unavailable.

### Framer

Source authority: official developer docs.

Confirmed schema facts:

- Web/runtime model includes project, page, frame/layer, component, code
  component, override, property control, props, interaction/event handler,
  animation, route, CMS data, plugin, and published runtime.
- Framer is useful for web runtime/component binding facts.
- Full editable project internals are unavailable as stable local artifact
  evidence.

### Principle

Source authority: official docs and app-bundle resources.

Confirmed schema facts:

- Motion model includes document, artboard, layer, event, transition, driver,
  animation, timeline, property animation, drag/scroll interaction, screen flow,
  preview, and share/export behavior.
- Principle is useful for motion/timeline/driver fields.
- No `.prd` authoring sample was found in the app-bundle resources in this
  round.

### Penpot

Source authority: public docs/source.

Confirmed schema facts:

- Open design/prototype model includes file, page, board, shape, component,
  design token, prototype flow, interaction, plugin, export, and open package
  concepts.
- Penpot is useful for source-available design/prototype model comparison and
  open file/API model research.

## Known Missing Field Facts

These gaps are preserved so future research can restart without replaying the
conversation. They do not block first-pass `Interaction Design Schema` or
`UI Design Schema` design. They matter when the work moves from schema design
into importer/exporter compatibility, editor-source adapters, or higher-fidelity
projection parity.

| App / source | Missing field facts | Current usable evidence | Blocks v0 schema design? | Needed later for |
| --- | --- | --- | --- | --- |
| Figma | Same-file REST JSON for the local `.fig` export. Local `.fig` package exposes package layout and internal vocabulary hints, but not stable semantic node/reaction instances. | Official REST and Plugin API docs for nodes, reactions, triggers, actions, transitions, component properties, variants, and variables; local `.fig` package probe as package-shape evidence only. | No. Official API is the schema authority. | Same-file API/package comparison, local Figma importer/exporter, and artifact-level schema verification. |
| ProtoPie | Readable `.pie` / `.piec` serialized field names and internal object graph. Official tutorial and app-bundle `.pie` files are available but opaque in current probes. | Official docs for triggers, responses, conditions, variables, formulas, components, Send/Receive, channels, messages, and sensors. | No. Official docs are enough for interaction-logic donor facts. | ProtoPie importer/exporter, private-format field confidence, and parity testing against real `.pie` files. |
| Rive | `.rev` editor-source fields and editor-only metadata. Public `.riv` runtime files do not expose the full authoring project model. | Official runtime docs/source plus public `.riv` runtime artifacts covering state machines, inputs, listeners, events, view models, and data binding. | No. Runtime state-machine facts are sufficient for v0. | Rive editor-source adapter, authoring-source round-trip, and deeper design-time animation model extraction. |
| Principle | `.prd` authoring sample and file-level authoring fields. Official app bundle did not include a `.prd` sample. | Official docs and app-bundle resources for motion, timelines, drivers, preview/export, compatibility, and Sketch import. | No. Principle is a specialized motion/timeline donor. | Principle file importer/exporter, timeline field parity, and authoring-project reverse engineering. |
| Framer | Editable/remix project internals and stable local project artifact format. | Official developer docs for components, code components, overrides, property controls, event handlers, routes, CMS/runtime, and plugins. | No. Framer is a web runtime/component donor for this round. | Framer project adapter, remix/export analysis, and published-runtime-to-source comparison. |
| UXPin | `.uxp` artifact fields and full project package shape. | Official docs for interactions, variables, expressions, conditions, forms, validation, component states, Merge, and code-backed components. | No. UXPin is deferred/specialized. | UXPin importer/exporter and code-backed component parity research. |
| Sketch | A modern prototype-heavy `.sketch` covering all current prototyping features in one artifact: overlays, scroll areas, fixed layers, Smart Animate, custom layer visibility, and preview targets. | Official Sketch file/API/prototyping docs, Apple Design Resources, and local Apple Sketch artifact probes confirming baseline flow fields. | No. Official docs plus Apple artifacts are sufficient for v0. | Artifact-level confirmation of newer prototype fields and Sketch-to-schema adapter testing. |
| Flinto | Broader `.flinto` samples for media, components, imports, preview-device variants, and more behavior combinations. Current probes cover blank and enriched interaction cases but not every app feature. | Official Learn docs plus local blank/enriched `.flinto` probes for screens, links, gestures, transitions, behavior states, scroll groups, layer-state maps, and motion timing. | No. Current samples are sufficient for app-like interaction and motion donor facts. | Flinto importer/exporter, richer app-like prototype parity, and private-format field confidence. |
| Axure RP | Deeper diffed `.rp` cases for generated HTML parity, advanced repeaters, and complex variable/expression scenarios. | Official docs/API plus RP 11 app-bundle training `.rp` files and `.rplib` libraries. | No. Current evidence is sufficient for functional prototype logic fields. | Axure importer/exporter, generated-HTML/runtime comparison, and complex enterprise-prototype field coverage. |
| Origami Studio | Deeper package/file field mapping for official `.origami` examples and app-bundle manifests. | Official docs, JavaScript Patch API, official examples, and app-bundle examples/templates/manifests. | No. Current evidence is sufficient for patch graph and signal-flow donor facts. | Origami adapter, patch graph import/export, and detailed layer-property binding parity. |

## Facts To Preserve For Synthesis

- Keep behavior and UI-layer schemas separate.
- Keep platform/native expression separate from behavior.
- Keep transitions separate from animation presentation.
- Keep runtime/projection artifacts separate from source behavior.
- Keep evidence grade on every field that comes from private artifacts,
  inferred behavior, or public API/docs.
- Do not promote app-specific private field names as local schema names when a
  clearer cross-app concept exists.
