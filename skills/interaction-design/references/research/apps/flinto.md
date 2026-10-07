# Flinto Research Report

Status: facts-first app research. This report records Flinto facts and local
probe evidence for later Interaction Design Schema and UI Design Schema work.
It is not a cross-app synthesis and it does not make Flinto a public schema
authority.

## Product Positioning

Flinto is a Mac app for high-fidelity app interaction prototypes. Its product
center is not static UI design or production implementation; it is app-like
motion, gesture-driven navigation, scroll behavior, behavior states, and device
preview.

For this research, Flinto is useful because it resembles the product direction
we are exploring: a model-backed interaction/prototype tool that can express
real app behavior before implementation. Its authority is limited:

- official Learn docs are concept authority for user-visible workflows
- local `.flinto` probes are artifact evidence for object and field taxonomy
- private field names are not stable public schema
- Flinto maintenance status should not be treated as platform authority

## Mature Workflow Shape

The mature Flinto workflow is prototype-tool oriented:

1. Create or import screen artwork.
2. Arrange screens and layers as prototype surfaces and actors.
3. Add links from layers or screens.
4. Choose gestures, timers, or scroll gestures as triggers.
5. Target another screen, a transition, or a behavior state.
6. Tune screen-to-screen motion in Transition Designer.
7. Define screen-local or component-like behavior in Behavior Designer.
8. Use behavior states, layer-state maps, timer links, and state-local links for
   micro-interactions.
9. Use scroll groups to model native-like scroll containers.
10. Preview on Mac/device or share a `.flinto` prototype.

This workflow is more advanced than a simple hotspot tool because links,
transitions, behavior states, scroll containers, and gesture timing interact.

## Evidence Inventory

Official docs:

- Flinto Learn: https://www.flinto.com/learn
- Links and gestures:
  https://www.flinto.com/learn/links-and-gestures-overview
- Transition Designer:
  https://www.flinto.com/learn/transition-designer-overview
- Behavior Designer:
  https://www.flinto.com/learn/behavior-designer-overview
- Behavior states: https://www.flinto.com/learn/behavior-states
- Scroll group properties:
  https://www.flinto.com/learn/scroll-group-properties
- Share a prototype:
  https://www.flinto.com/learn/share-a-flinto-prototype-with-someone-else

Local artifact/probe inventory, not source references:

- Local blank artifact:
  `references/research/artifacts/flinto/local-probe/blank.flinto`
- Local enriched artifact:
  `references/research/artifacts/flinto/local-probe/enriched-interaction.flinto`

## Schema Facts

Field-level facts to preserve for later schema work:

- Artifact root: local `.flinto` probe root is `Flinto.Prototype`.
- Prototype fields: `sublayers`, `transitions`, `behaviors`, `homeScreenId`,
  `screenSize`, `screenScale`, `platform`, `defaultTimingFunction`,
  `defaultStatusbarStyle`, `showTapHints`, and `importedFromSketch`.
- Surface: `Flinto.Screen` with `name`, `links`, `sublayers`, `behaviorIds`,
  `currentBehaviorStateIds`, `behaviorTagLayerMaps`, `timerLinkEnabled`,
  `statusbarStyle`, `orientation`, `canvasFrame`, `_bounds`, `_position`,
  `_canvasPosition`, and `resetOnLeave`.
- Actor: `GroupLayer`, `RectLayer`, `PathLayer`, and `ScrollLayer` with links,
  sublayers, geometry, visibility, and state-map participation.
- Link / trigger / action: `targetScreenId`, `transitionId`, `gesture`,
  `timeout`, `backLink`, `ignoreHistory`, `skipAnimation`, `isReversed`,
  `allowsOvershoot`, `scrollGestureOptions`, `stateChangeDefinition`,
  `fromScreenTagLayerMap`, `toScreenTagLayerMap`, and
  `forceGesturePressureRange`.
- Transition: `fromScreen`, `toScreen`, `connectedLayers`, `layerOrder`,
  `statusbarAnimation`, `createdAt`, `_screenAligned`, and `name`.
- Behavior state: `Behavior`, `BehaviorState`, `StateChangeDefinition`,
  `behaviorStateID`, `timerLink`, `linkLayers`, `tagLayerStateMap`, and
  layer-state `valueMap`.
- Scroll: `_contentOffset`, `_contentSize`, `_clippingRect`, vertical and
  horizontal scroll flags, bounce, directional lock, paging, page size, and
  scroll indicator style.
- Motion timing: RK4 spring fields (`duration`, `delay`, `tension`,
  `friction`, `velocity`) and UIKit spring fields (`duration`, `delay`,
  `dampingRatio`, `velocity`).

## File / API / Artifact Model

Flinto does not publish a stable project-file schema or public API for `.flinto`
documents. Local app metadata confirms:

- document UTI: `com.flinto.prototype`
- extension: `.flinto`
- document class: `Flinto.Document`

The local artifacts are Apple binary property list / `NSKeyedArchiver` archives.
The enriched artifact root is `Flinto.Prototype`. The current probe observed 965
archived objects.

Observed object and field taxonomy includes:

- `Flinto.Prototype`: `sublayers`, `transitions`, `behaviors`,
  `homeScreenId`, `screenSize`, `screenScale`, `platform`,
  `defaultTimingFunction`, `defaultStatusbarStyle`, `showTapHints`,
  `importedFromSketch`
- `Flinto.Screen`: `name`, `links`, `sublayers`, `behaviorIds`,
  `currentBehaviorStateIds`, `behaviorTagLayerMaps`, `timerLinkEnabled`,
  `statusbarStyle`, `orientation`, `canvasFrame`, `_bounds`, `_position`,
  `_canvasPosition`, `resetOnLeave`
- `Flinto.Link`: `targetScreenId`, `transitionId`, `gesture`, `timeout`,
  `backLink`, `ignoreHistory`, `skipAnimation`, `isReversed`,
  `allowsOvershoot`, `scrollGestureOptions`, `stateChangeDefinition`,
  `fromScreenTagLayerMap`, `toScreenTagLayerMap`,
  `forceGesturePressureRange`
- `Flinto.Transition`: `fromScreen`, `toScreen`, `connectedLayers`,
  `layerOrder`, `statusbarAnimation`, `createdAt`, `_screenAligned`, `name`
- `Flinto.ScreenSet`: `screenParameters`, `layerParameterMap`, `allTags`,
  `type`, `name`
- `Flinto.TransitionParameters`: `animations`, `timing`, `preV25`
- `Flinto.TransitionAnimation`: `propertyKey`, `toValue`
- `Flinto.Behavior`: `states`, `allTags`, `tagTimingFunctionMap`, `name`,
  `UUID`
- `Flinto.BehaviorState`: `name`, `isInitial`, `timerLinkEnabled`,
  `timerLink`, `linkLayers`, `tagLayerStateMap`, `preV25`, `UUID`
- `_TtCC6Flinto13BehaviorState10LayerState`: `links`, `valueMap`, `UUID`
- `Flinto.ScrollLayer`: `_contentOffset`, `_contentSize`, `_clippingRect`,
  `isVerticalScrollEnabled`, `isHorizontalScrollEnabled`,
  `isBounceScrollEnabled`, `isDirectionalLockEnabled`, `isPagingEnabled`,
  `pageSize`, `scrollIndicatorStyle`, `links`, `sublayers`
- `Flinto.ScrollGestureAnimationDescriptor`: `orientation`, `startInPixel`,
  `endInPixel`, `autoReverse`
- `Flinto.StateChangeDefinition`: `animationState`, `behaviorStateID`
- `Flinto.GroupLayer`, `Flinto.RectLayer`, `Flinto.PathLayer`: layer actor
  taxonomy with geometry, style, `links`, `sublayers`, behavior IDs, and hidden
  or locked state
- `Flinto.Tag`: `name`, `tagType`, `isConnectedLayer`
- `Flinto.RK4Spring`: `duration`, `delay`, `kind/name`, `tension`,
  `friction`, `velocity`
- `Flinto.UIKitSpring`: `duration`, `delay`, `dampingRatio`, `velocity`,
  `name`

Probe counts in `enriched-interaction.flinto`:

- 3 screens
- 20 links
- 20 state-change definitions
- 20 scroll gesture descriptors
- 2 scroll layers
- 2 group layers
- 1 path layer
- 2 behavior objects
- 6 behavior states
- 5 layer-state maps
- 7 transitions
- 26 transition animations
- 2 UIKit spring objects

These facts are strong local artifact evidence, but not a public contract.

## Interaction Model

Flinto's interaction model is app-like:

- screen: prototype surface
- layer/group/path/scroll layer: visual actor and interaction target
- link: connection from source actor/screen to target screen, transition, or
  behavior state
- gesture: trigger on a link
- timer link: time-based trigger
- behavior: local interactive model for a screen or component-like area
- behavior state: named state inside a behavior
- state-change definition: link-side binding to a target behavior state
- transition: animated screen-to-screen change
- scroll group/layer: scrollable interaction container
- tag/connected layer: matched-layer or reusable transition binding

Important behavior facts:

- a screen can reference behavior IDs and current behavior-state IDs
- a behavior owns multiple behavior states
- a behavior state may include state-local links, timer link, layer-state map,
  and tag-layer state mapping
- a link may target a screen and transition or carry a state-change definition
- scroll gestures are separate from normal links and include scroll-specific
  descriptors

Flinto is weaker for explicit business rules, data validation, permissions, or
structured product traceability. Those are outside its product focus.

## UI Layer Model

Flinto's UI layer is prototype-artifact oriented:

- screens contain visual layer trees
- group layers organize nested layer hierarchy
- rect/path layers carry visual shape and geometry facts
- scroll layers add clipping, content size, content offset, paging, indicator,
  bounce, axis, and directional-lock facts
- layer state maps capture per-state visual values
- tags and connected layers support matched motion
- import-origin fields may exist, such as `importedFromSketch`, but current
  artifacts are not enough to generalize imported Sketch/Figma semantics

This makes Flinto useful for understanding how UI actors bind to interaction
state. It is not a final UI token, design-system, or native-component schema.

## State / Variable / Logic Model

Flinto has strong local state modeling:

- `Behavior` groups a state model.
- `BehaviorState` names individual states and marks initial state.
- `StateChangeDefinition.behaviorStateID` links an interaction to a target
  behavior state.
- layer-state maps attach visual property values to behavior states.
- timer links allow delayed state transitions.
- link layers allow state-local links.

Flinto has weak general-purpose logic:

- no public evidence of rich expression language comparable to ProtoPie or
  Axure
- no strong first-party model for business-rule predicates
- no product requirement traceability
- conditions are mostly state/context driven rather than general formulas

## Motion / Runtime / Handoff Model

Flinto's motion and preview model is one of its strongest areas:

- Transition Designer controls screen-to-screen motion.
- Behavior Designer controls state-local micro-interactions.
- transition tags and connected layers support matched motion.
- screen sets and layer parameter maps store before/after transition
  parameters.
- RK4 and UIKit spring objects preserve timing vocabulary.
- transitions include status bar animation and layer-order concepts.
- previews can run locally/on-device and be shared as `.flinto` prototypes.

Motion fields should influence later projection/motion schema. Exact numeric
spring parameters should remain presentation/runtime detail, not product
behavior.

## Confirmed / Inferred / Unknown

Confirmed:

- Flinto uses `.flinto` package documents with app-declared UTI.
- The enriched local artifact has a `Flinto.Prototype` root.
- Screen, link, transition, behavior, behavior state, scroll layer, group
  layer, path layer, state-change definition, and spring classes appear in the
  local object graph.
- Public Learn docs confirm links, gestures, Transition Designer, Behavior
  Designer, behavior states, scroll groups, and sharing.

Inferred:

- Field names in local artifacts likely correspond to Flinto's internal model,
  but they are private implementation details.
- Link plus state-change definition is Flinto's serialized route from trigger
  to behavior-state change.
- Layer-state maps represent per-state visual/property values.

Unknown:

- full media support
- imported Sketch/Figma variants
- component-rich or nested behavior edge cases
- device-preview metadata
- exhaustive gesture enum values
- stability of private class and field names across Flinto versions

## Useful Later

- app-like screen/link/gesture model
- behavior-state model
- layer-state map model
- scroll group interaction model
- timer-trigger model
- matched-layer/tag transition model
- spring and transition vocabulary
- preview artifact as projection, not source of product truth

## Do Not Absorb

- private `.flinto` serialization as canonical schema
- exact class names as stable local field names
- exact spring constants as product behavior
- imported-design fields without more evidence
- Flinto's current maintenance status as platform authority
- Flinto UI as final visual design guidance
