# Axure RP Research Report

Status: facts-first app research. This report records Axure RP facts for later
Interaction Design Schema and UI Design Schema work. It is not a cross-app
synthesis and it does not promote Axure project files or generated HTML as
source-of-truth schema.

## Product Positioning

Axure RP is an enterprise functional-prototype tool. It is strong for
screen/page structure, widgets, events, cases, conditional logic, variables,
expressions, dynamic panels, repeaters, forms, and generated HTML prototypes.

For this research, Axure is most valuable as a functional logic donor. It is
less important for motion polish than tools like Principle, Flinto, Rive, or
Figma. Its distinguishing strength is explicit event/case/action logic and
stateful UI components such as dynamic panels.

## Mature Workflow Shape

Axure workflows typically look like this:

1. Define pages as prototype surfaces.
2. Place widgets and grouped widgets on pages.
3. Configure widget/page events.
4. Add cases under events.
5. Attach conditions to cases when branching is needed.
6. Add actions that navigate, show/hide, move, set panel state, set text, set
   variables, fire events, scroll, wait, or manipulate repeaters.
7. Use dynamic panels for stateful regions.
8. Use repeaters for repeated/data-like UI.
9. Use form widgets, values, and conditions for input and validation-like
   behavior.
10. Generate HTML prototypes for preview/share.
11. Use libraries for reusable widgets and patterns.

This is closer to a functional prototype programming model than a simple
hotspot model.

## Evidence Inventory

Official docs and product pages:

- Events, cases, actions:
  https://archive.axure.com/axure-rp/reference/events-cases-actions/
- Dynamic panels:
  https://archive.axure.com/axure-rp/reference/dynamic-panels/
- Axure RP API: https://www.axure.com/axure-rp-api
- Core training: https://www.axure.com/support/core-training-4
- Axure download page: https://www.axure.com/downloadthanks

Local artifact/probe inventory, not source references:

- Local app-bundle artifacts:
  `references/research/artifacts/axure/app-bundle/Prototype Starter.rp`
  `references/research/artifacts/axure/app-bundle/Prototyping Basics.rp`
  `references/research/artifacts/axure/app-bundle/Quick Win.rp`
  `references/research/artifacts/axure/app-bundle/UX Prototyping.rp`
  `references/research/artifacts/axure/app-bundle/Sample UI patterns.rplib`
  `references/research/artifacts/axure/app-bundle/Sample form patterns.rplib`

## Schema Facts

Field-level facts to preserve for later schema work:

- Project structure: project, page, widget, library, generated HTML projection.
- Actor: widget, dynamic panel, repeater, form input, or target.
- Event: widget/page event.
- Case: branch under an event.
- Condition: case condition and conditional logic.
- Action: action targeting page, widget, panel, variable, form, repeater, or
  navigation behavior.
- State: dynamic panel state, widget state, variable state, form state, and
  repeater state.
- Variable/expression: global/local variables and expressions.
- Validation: form input and validation behavior.
- Runtime projection: generated HTML can execute prototype behavior but is not
  the source schema.

## File / API / Artifact Model

Observed local artifacts:

- `.rp` training project files from the official Axure RP 11 app bundle
- `.rplib` sample libraries from the official Axure RP 11 app bundle

Local file probe facts:

- `file` reports the local `.rp` and `.rplib` artifacts as `data`
- current local reports do not claim a readable current `.rp` schema
- Axure's legacy API and public docs provide concept evidence, not complete
  current RP 11 file serialization

Axure's artifact model has three important surfaces:

- authoring project: `.rp`
- reusable library: `.rplib`
- generated HTML prototype: shareable/runtime projection

Generated HTML is useful for runtime behavior comparison, but it must not be
treated as the authoring source or product source of truth.

## Interaction Model

Axure has a clear functional interaction model:

- Project: prototype container
- Page: surface/screen
- Widget: actor, UI element, and action target
- Event: trigger fired by page/widget/user/runtime behavior
- Case: branch under an event
- Condition: predicate gating a case
- Action: operation executed by a case
- Target: page, widget, dynamic panel, variable, repeater, or form field
- DynamicPanel: stateful container
- PanelState: visible dynamic-panel state
- Variable: global/local mutable value
- Expression: computed value for actions or conditions
- FormInput: user input widget and value source
- Repeater: repeated/data-like UI component
- Validation: condition/expression-driven behavior around forms and values

Axure's most important structural pattern is:

```text
event -> case -> optional condition -> actions[] -> targets
```

This is strong evidence for separating trigger, condition, action, target, and
state change in later local schema work.

## UI Layer Model

Axure's UI layer is page/widget oriented:

- pages are prototype surfaces
- widgets are UI actors and action targets
- groups and libraries organize reusable UI
- dynamic panels define stateful UI regions
- panel states represent alternate visible UI states
- repeaters represent repeated or data-driven UI
- form widgets represent user input controls
- generated HTML projects the widget tree into a browser runtime

Axure is useful because its UI layer is tied to functional behavior. It is not
a final high-fidelity visual system donor.

## State / Variable / Logic Model

Axure is strong for explicit logic:

- cases encode branch alternatives under an event
- conditions gate cases
- variables hold mutable prototype state
- expressions compute or compare values
- dynamic panel states encode visible state
- show/hide actions encode visibility state
- repeaters add data-like state and repeated item behavior
- form widgets provide input values and validation targets
- wait/fire-event actions can sequence behavior

Axure can represent validation and recovery patterns well because form values,
conditions, actions, and dynamic panel states can be composed into observable
prototype behavior.

## Motion / Runtime / Handoff Model

Axure supports generated HTML prototypes for preview and sharing. Its runtime
model matters because:

- events and cases must execute in generated HTML
- dynamic panels and repeaters must be interactive
- variables and expressions must evaluate at runtime
- form values and validation-like behavior must be observable
- generated HTML can be tested as a projection

Motion exists through action effects, show/hide effects, movement, panel-state
changes, waits, and animations, but Axure is not primarily a motion/timeline
donor.

## Confirmed / Inferred / Unknown

Confirmed:

- official docs describe events, cases, actions, dynamic panels, variables,
  expressions, repeaters, and generated prototypes
- official RP 11 app bundle includes `.rp` training files and `.rplib` sample
  libraries
- current local artifacts are preserved under the interaction-design research
  artifact tree

Inferred:

- current `.rp` files serialize the documented Axure authoring model, but the
  local reports do not expose a stable readable field schema
- generated HTML can later be used to compare runtime behavior against
  authoring concepts
- the legacy API is conceptually useful but may not cover every current RP 11
  field

Unknown:

- complete current `.rp` serialized schema
- exact RP 11 enum values for events/actions/conditions
- generated HTML mapping for each official training `.rp`
- full repeater data model in current RP 11 artifacts
- exact library serialization for `.rplib`

## Useful Later

- event/case/condition/action chain
- target model
- dynamic panel and panel-state model
- variable/expression model
- form input and validation behavior
- repeater/data-like UI model
- generated HTML as projection for runtime comparison
- functional prototype coverage model

## Do Not Absorb

- current `.rp` internals as canonical schema without stronger evidence
- generated HTML as product or authoring source of truth
- legacy API fields as complete RP 11 schema
- enterprise feature complexity unless it maps to a real product need
- Axure visual styling as final UI design guidance
- repeater/data behavior as a substitute for product data-model definition
