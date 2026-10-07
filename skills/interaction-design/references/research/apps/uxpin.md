# UXPin Research Report

## Product Positioning

UXPin is a realistic prototyping and design-system platform with support for
interactions, variables, expressions, forms, validation, component states, and
code-backed components through Merge.

For this research round, UXPin is a specialized and deferred reference. It is
useful for realistic prototype behavior, forms, variables, expressions,
conditional interactions, and code-backed component boundaries. It is not a
primary source for the first interaction DSL pass because no local `.uxp`
artifact has been probed and stronger public donors already cover the core
trigger/action/transition/state concepts.

## Mature Workflow Shape

UXPin workflows center on:

- designing pages, elements, components, and design-system libraries
- adding interactions to elements and canvas-level events
- using actions to navigate, show/hide/toggle elements, set states, set
  variables, scroll, open URLs, move elements, or call APIs
- using conditional interactions to make prototype behavior depend on
  variables, element content, values, or expressions
- using variables and expressions to store input, update content, validate
  values, and model realistic product-like behavior
- modeling forms and form validation inside the prototype
- using component states and state-setting actions
- using Merge to bring code-backed React components into the design editor
- sharing prototypes and design-system handoff artifacts

## Evidence Inventory

- UXPin docs root: https://www.uxpin.com/docs/
- Interactions: https://www.uxpin.com/docs/editor/interactions/
- Expressions: https://www.uxpin.com/docs/editor/expressions/
- Variables: https://www.uxpin.com/docs/editor/variables/
- Design systems:
  https://www.uxpin.com/docs/design-systems/design-systems/
- Design system libraries:
  https://www.uxpin.com/docs/design-systems/design-system-libraries/
- Merge overview:
  https://www.uxpin.com/docs/merge/what-is-uxpin-merge/
- Integrating code components:
  https://www.uxpin.com/docs/merge/integrating-your-own-components/
- Merge Component Manager:
  https://www.uxpin.com/docs/merge/merge-component-manager/
- Prototypes dashboard:
  https://www.uxpin.com/docs/dashboard/prototypes/

Historical input from the earlier root research pass exists, but this report
uses current official docs as its factual authority.

## Schema Facts

Field-level facts to preserve for later schema work:

- Actor/component: component, code-backed component, form field, and design
  system component.
- State: component state and variable state.
- Interaction: interaction attached to a component or element.
- Condition/expression: variables, expressions, and conditions can drive
  realistic prototype behavior.
- Validation: form field and validation behavior.
- Data binding: data binding and Merge/code-backed component concepts connect
  prototype UI to code-backed behavior.
- Runtime/export: React export and code-backed component handoff exist, but
  should be treated as implementation/projection facts, not product behavior.
- Artifact fact: current `.uxp` serialized field schema is unavailable.

## File / API / Artifact Model

No `.uxp` export sample is currently available locally. This report is based on
official docs only.

Documented model areas:

- Page
- Element
- Component
- Design system library
- Merge code-backed component
- State
- Interaction
- Variable
- Condition
- Expression
- FormField
- DataBinding
- Validation
- API request interaction
- React / Merge integration
- DesignSystem
- Prototype share/handoff artifact

Merge-specific documented concepts:

- React component repository
- Webpack build configuration
- default exports
- JavaScript PropTypes, Flow types, or TypeScript types/interfaces
- component properties
- JSDoc tags such as `@uxpinpropname`, `@uxpincontroltype`,
  `@uxpinignoreprop`, and `@uxpindescription`

## Interaction Model

UXPin interaction facts from official docs:

- Interactions can be added to elements and to the canvas.
- Element triggers are user interactions with elements.
- Canvas triggers are based on changes in canvas state.
- Existing interactions can be copied and pasted between elements or pages.
- Draft interactions can exist when an interaction references a deleted element
  or variable.
- An action is what happens after the interaction is triggered.

Documented actions include:

- Go to Page.
- Hide.
- Show.
- Toggle.
- Set State.
- Set Variable.
- Scroll to.
- Open URL.
- Go Back.
- API Request.
- Move to / Move by.

Conditional interactions:

- Conditions are attached to specific interactions.
- One interaction can have multiple conditions.
- Conditions can be evaluated as "any" or "all" of the conditions being met.
- Condition inputs include variable value, element content, explicit value, or
  expression.

UXPin is useful for validating that the local model needs conditions,
variables, element content references, and action invalidation/gap handling.

## UI Layer Model

UXPin UI layer facts:

- element and component-based design
- design-system libraries
- built-in libraries, including platform and web UI libraries
- interactive form controls
- component states and properties
- code-backed components through Merge
- Merge libraries from Git, Storybook, or npm sources
- React components rendered in the editor

UXPin's UI layer is important because it intentionally collapses the gap
between design surface and code-backed component runtime. For the local schema,
that is a useful boundary case, not a default requirement.

## State / Variable / Logic Model

UXPin is useful for:

- global prototype variables with optional default values
- setting variables from user input or element content
- using variables to set element content
- binding variables to checkboxes, radio buttons, inputs, text areas, select
  lists, state, video URL, image URL, and text-like elements
- expressions that combine numbers, strings, variables, element content,
  functions, and booleans
- expressions used for conditions, element content, operations on variables,
  form validation, shopping cart-like computations, and password/email checks
- component states changed through Set State actions
- realistic form state and validation behavior

This makes UXPin a useful specialized reference for form-heavy prototypes and
validation/variable semantics.

## Motion / Runtime / Handoff Model

UXPin includes an animation editor for interactions, but it is less important
for motion schema than Principle, Flinto, Rive, or dotLottie.

Its runtime/handoff importance is realistic component behavior and code-backed
component handoff:

- Merge can import and sync coded React components from Git repositories.
- Merge renders coded components in a design-system library.
- Code-backed components can expose interactions and data close to the actual
  product experience.
- Merge documentation emphasizes component properties, types/interfaces, and
  design-system documentation.

For the local schema, this supports a boundary rule: code-backed components can
inform UI layer and artifact projection, but they must not redefine product
behavior owned by the interaction model.

## Confirmed / Inferred / Unknown

Confirmed:

- UXPin supports interactions on elements and canvas.
- UXPin actions include navigation, visibility toggles, state setting,
  variable setting, scrolling, URL opening, back navigation, API request, and
  movement.
- UXPin conditional interactions can be gated by variable values, element
  content, explicit values, or expressions.
- UXPin variables can store user input and drive element content/state.
- UXPin expressions support values, variables, element content, functions, and
  boolean values.
- UXPin Merge imports and renders React code components in the editor.
- Merge integrations can use JavaScript, Flow, or TypeScript component
  property definitions.

Inferred:

- `.uxp` or internal project artifacts likely encode the documented
  interaction/variable/expression/component-state models, but no sample has
  been probed.
- UXPin is most valuable to the local schema as a high-fidelity form,
  validation, expression, and code-backed component boundary reference.

Unknown:

- `.uxp` file structure
- current export/import field names
- full trigger list and animation field list
- whether code-backed component runtime behavior is serializable in a way that
  is useful outside UXPin
- whether current UXPin artifacts expose a stable public schema

## Useful Later

- form validation model
- realistic prototype variables, expressions, and conditions
- component state and Set State action semantics
- draft/invalid interaction handling as a coverage/gap concept
- code-backed component boundary for UI layer and artifact projection
- distinction between prototype runtime, design-system component source, and
  production code source

## Do Not Absorb

- UXPin Merge production-code coupling into product behavior.
- Docs-only assumptions as file schema.
- API request or production-code execution as a required local prototype
  capability.
- Code-backed component behavior as canonical product behavior unless the
  upstream product interaction model explicitly accepts it.
- UXPin as a primary v0 donor now that stronger sources cover most core
  fields.
