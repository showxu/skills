# ProtoPie Research Report

Status: facts-first app research. This report records ProtoPie facts for later
Interaction Design Schema and UI Design Schema work. It is not a cross-app
synthesis and it does not treat the opaque `.pie` format as readable schema.

## Product Positioning

ProtoPie is a high-fidelity prototyping tool for interaction logic. Its center
of gravity is triggers, responses, variables, formulas, conditions, components,
sensors, and cross-device communication. It is stronger as an interaction logic
reference than as a design-file or production-code reference.

For this research, ProtoPie is an important app because it has a mature
prototype logic vocabulary. Its public authority comes from official docs and
product workflows, not from `.pie` binary fields.

## Mature Workflow Shape

ProtoPie workflows typically look like this:

1. Build scenes with layers and imported assets.
2. Add triggers to layers, scenes, variables, sensors, or messages.
3. Attach responses to triggers.
4. Use conditions to choose which response path runs.
5. Use variables and formulas for dynamic state and computed behavior.
6. Encapsulate reusable behavior in components and component variables.
7. Use Send/Receive to communicate across scenes, components, pies, devices, or
   ProtoPie Connect.
8. Use sensors and device inputs for high-fidelity mobile/device behavior.
9. Preview locally, share on ProtoPie Cloud, or run device/external workflows
   through ProtoPie Connect.

This is a logic-rich prototype workflow. It is not primarily a final UI
design-system workflow.

## Evidence Inventory

Official docs and product pages:

- ProtoPie docs root: https://www.protopie.io/learn/docs
- Triggers: https://www.protopie.io/learn/docs/interactions/triggers
- Responses: https://www.protopie.io/learn/docs/interactions/responses
- Variables docs: https://www.protopie.io/learn/docs/variables
- Variables tutorial with official Pie samples:
  https://www.protopie.io/blog/how-to-use-variables-protopie
- Send/Receive docs:
  https://www.protopie.io/learn/docs/components/send-receive-messages
- ProtoPie download page: https://www.protopie.io/download

Local artifact/probe inventory, not source references:

- Local app-bundle artifacts:
  `references/research/artifacts/protopie/app-bundle/walkthrough.pie`
  `references/research/artifacts/protopie/app-bundle/sample-1119.piec`
- Local official tutorial artifacts:
  `references/research/artifacts/protopie/local-official-tutorial/01-pre-defined-variables-completed.pie`
  `references/research/artifacts/protopie/local-official-tutorial/02-dynamic-variables-complete.pie`
  `references/research/artifacts/protopie/local-official-tutorial/variables-with-components.pie`

## Schema Facts

Field-level facts to preserve for later schema work:

- Document/surface: Pie and scene.
- Actor: layer and component.
- Trigger: documented trigger objects attached to layers, scenes, variables,
  sensors, messages, or components.
- Response/action: documented responses attached to triggers.
- Condition/guard: conditions branch trigger or response execution.
- State: variables, component variables, and layer/property changes.
- Expression: formulas compute dynamic values for variables, conditions, and
  responses.
- External message: Send/Receive, channel, message, component, scene, pie,
  device, and Connect communication concepts.
- Sensor/input: device and environment inputs.
- Artifact fact: official `.pie` and `.piec` samples are available, but current
  probes do not expose readable scene/layer/trigger/response/variable/formula
  serialized field names.

## File / API / Artifact Model

Observed local artifacts:

- `.pie` files from the official Studio app bundle
- `.piec` component/package sample from the official Studio app bundle
- three official tutorial `.pie` files downloaded from ProtoPie Cloud entries
  linked by the variables tutorial

Local probe facts:

- `file` reports these artifacts as `data`
- not ZIP
- not JSON
- not SQLite
- not XML plist
- not binary plist
- not common zstd/lz4/xz/bzip2 frames
- common gzip/zlib/raw-deflate probes did not reveal meaningful payloads
- `strings` output did not expose stable names such as scene, layer, trigger,
  response, variable, or formula
- official tutorial file sizes and SHA-256 hashes are recorded in the artifact
  manifest

The artifact conclusion is clear: `.pie` files are useful as provenance and
sample availability evidence, but not as direct field-schema evidence in this
round. ProtoPie official docs remain the authority for the interaction model.

## Interaction Model

ProtoPie's documented interaction model is trigger-response based:

- Pie: prototype document
- Scene: surface or screen context
- Layer: visual or interactive actor
- Component: reusable interaction unit
- Trigger: event that starts one or more responses
- Response: operation produced by a trigger
- Condition: branch/guard around trigger or response execution
- Variable: mutable prototype state
- Formula: computed value used by conditions, variables, or responses
- Send/Receive: message exchange between components, scenes, pies, or devices
- Channel/Message: communication context and payload
- Sensor: device or environment input

ProtoPie is especially important because it treats prototype logic as first
class. It can describe interactions that exceed simple screen navigation:
dynamic variable updates, formula-driven behavior, external messages, and
device input.

## UI Layer Model

ProtoPie has a layer-based UI model:

- scenes contain layers
- layers can be imported from design tools or created in ProtoPie
- layer properties are targets for responses
- components package reusable layers and logic
- component instances can expose component variables
- visual layer changes can be animated or bound to interaction responses

For this research, ProtoPie's UI layer is useful mainly as an actor/target
model. It should not be treated as a final design-token or UI-system authority.

## State / Variable / Logic Model

ProtoPie is strong for state and logic:

- variables can model prototype state
- component variables allow reusable component-level state
- formulas compute dynamic values
- conditions gate response execution
- trigger/response chains can mutate variables and layer properties
- Send/Receive provides external or cross-scope event/state transfer
- sensors produce device-driven inputs

Important boundary: ProtoPie formulas and variables are prototype logic. They
can inspire local variable/expression concepts, but ProtoPie-specific syntax
should not become canonical product DSL syntax by default.

## Motion / Runtime / Handoff Model

ProtoPie supports high-fidelity runtime preview and handoff:

- local preview
- ProtoPie Cloud sharing
- device preview
- ProtoPie Connect for hardware, multi-device, and external communication
- responses that animate or change layer properties
- messages across component, scene, pie, or external boundaries

ProtoPie's motion model is response-driven rather than timeline-editor-driven.
It is useful for behavior-coupled animation and runtime state, less useful as a
dedicated motion timeline donor compared with Principle or Rive.

## Confirmed / Inferred / Unknown

Confirmed:

- official docs define triggers, responses, variables, formulas, conditions,
  Send/Receive, components, and Connect/device workflows
- official app bundle contains `.pie` and `.piec` artifacts
- official variables tutorial links to downloadable Cloud `.pie` files
- local tutorial `.pie` probes show an opaque private binary format

Inferred:

- `.pie` artifacts likely serialize the documented concepts, but serialized
  field names and enums are not readable from current probes
- `.piec` likely packages component-level content, but local field extraction
  is not available
- ProtoPie variables/components/tutorial files are enough to validate product
  concept maturity, not enough to define file-schema fields

Unknown:

- readable `.pie` file schema
- exact serialized object names and enums
- full sensor field taxonomy
- exact Connect runtime payload format
- how formula syntax is serialized
- whether ProtoPie Studio can export a trusted metadata representation

## Useful Later

- trigger-response vocabulary
- response/action taxonomy
- variable and component-variable model
- formula/expression model
- condition/guard semantics
- Send/Receive and external message model
- sensor/system input modeling
- component-local interaction encapsulation
- runtime handoff boundaries for prototype-only logic

## Do Not Absorb

- private `.pie` or `.piec` bytes as schema
- ProtoPie-specific formula syntax as the canonical expression language
- external device or Connect mechanics as product behavior
- sensor availability as a universal platform assumption
- layer styling as final UI design authority
- Cloud/share workflow as a local source-of-truth model
