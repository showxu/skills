# Framer Research Report

## Product Positioning

Framer is a web-native design, component, CMS, and publishing platform. For
this research, Framer is a specialized reference for:

- web runtime surfaces
- code components
- property controls
- code overrides
- routes and published pages
- CMS/data binding
- plugin extension points
- implementation-adjacent prototype projection

Framer is not a product behavior source for this repository. Its runtime and
component model can inform projection, UI-layer binding, and web artifact
behavior, but product requirements and canonical interaction behavior must come
from Product Experience artifacts.

## Mature Workflow Shape

Framer's mature workflow is web-publishing oriented:

1. Designers build pages, frames, layers, sections, components, and site
   structure on a visual canvas.
2. Teams use components, effects, interactions, layout controls, routes, CMS
   collections, and responsive behavior to create realistic web experiences.
3. Developers extend the canvas with React code components, property controls,
   code overrides, plugins, CMS sync, and API integrations.
4. Preview and publish turn the design into a live web runtime.
5. Data, routing, and runtime behavior can be close to production web behavior,
   even when used as a prototype.

This makes Framer a strong web runtime/component donor. It also makes Framer a
risk: its implementation-adjacent capabilities should not back-define product
requirements or canonical interaction behavior.

## Evidence Inventory

Official documentation:

- Framer developers: https://www.framer.com/developers/
- Code overrides introduction:
  https://www.framer.com/developers/overrides-introduction/
- Override examples:
  https://www.framer.com/developers/overrides-examples
- Property controls:
  https://www.framer.com/developers/property-controls
- Plugin/API reference:
  https://www.framer.com/developers/reference
- CMS guide: https://www.framer.com/developers/cms
- Plugin reference:
  https://www.framer.com/developers/plugins/reference

Evidence priority:

1. Official Framer developer docs and Plugin API docs.
2. Published/exported artifacts only as future adapter evidence.

## Schema Facts

Field-level facts to preserve for later schema work:

- Project structure: project, page, frame/layer, route, CMS data, plugin, and
  published runtime.
- Actor/component: component and code component.
- Runtime binding: props, property controls, overrides, and event handlers.
- Interaction: event handler or interaction attached to component/frame logic.
- Animation: animation and web runtime presentation.
- Data: CMS/fetch/runtime data boundaries.
- Artifact fact: full editable project internals are unavailable as stable local
  artifact evidence in this round.

## File / API / Artifact Model

No stable unauthenticated editable Framer project artifact is available locally
for this round. Official developer documentation is the authority.

Documented model:

- `Project`: site/project workspace
- `Page`: routeable web page surface
- `Frame` / `Layer`: canvas and layout objects
- `Component`: reusable design/runtime unit
- `CodeComponent`: React component rendered inside Framer
- `PropertyControl`: canvas-editable props for code components
- `Props`: parameters passed into code components
- `Override`: React higher-order component that modifies a layer at preview or
  publish time
- `Route`: published navigation path
- `CMSCollection`: content collection
- `CMSItem`: content row/object with `id`, `slug`, draft state, and field data
- `CMSField`: typed content field such as string, boolean, number, color, date,
  image, file, link, enum, reference, multi-reference, formatted text, or array
- `Plugin`: extension runtime for editor, CMS, and project operations
- `PublishedRuntime`: live web output

The model is web runtime oriented rather than static design-file oriented.

## Interaction Model

Framer interaction is component and runtime oriented:

- canvas interactions and effects expose common web UI behavior
- code components expose behavior through React props and event handlers
- property controls let designers configure component behavior from the canvas
- overrides modify layer props or behavior during preview and published runtime
- routes model navigation between pages
- CMS and fetch/data features can drive stateful runtime output
- plugins can navigate the editor UI, access CMS collections, and sync data

Framer's interaction value for this research is not "product behavior truth."
It is evidence for how a web-native projection layer binds UI surfaces,
component props, data, events, routes, and runtime behavior.

## UI Layer Model

Framer's UI layer combines visual canvas objects and web runtime components:

- pages and routes
- frames, stacks, sections, and layers
- visual components and code-backed components
- property controls for component configuration
- responsive layout behavior
- styling and effects
- CMS-driven content surfaces
- published web runtime DOM/component output

Property controls are particularly useful as UI-layer parameter evidence:
they show how a component can expose editable props to a non-code canvas while
remaining backed by runtime logic.

## State / Variable / Logic Model

Framer state is implementation-adjacent and web runtime based:

- React props and component state
- event handlers inside code components
- code override state and effects
- route state
- CMS collection/item/field data
- managed and unmanaged CMS collections
- plugin mode state such as configure/sync modes
- plugin data / metadata
- fetched or integrated data

This is strong evidence for runtime binding and web projection, but weak as a
canonical product behavior model because product intent can be hidden inside
code.

## Motion / Runtime / Handoff Model

Framer is strong for web runtime and handoff:

- preview and published runtime
- effects and animation behavior
- code components with props
- code overrides active in preview/published sites
- route-based web navigation
- CMS-backed runtime pages
- plugin-based CMS sync and editor automation

Official docs warn that overrides can break built-in layer behavior if they
modify core props incorrectly. That is important evidence for this repository:
projection/runtime skills must preserve upstream behavior instead of inventing
or silently rewriting it.

## Confirmed / Inferred / Unknown

Confirmed:

- Framer developer docs cover code overrides, property controls, Plugin API,
  CMS, and runtime-oriented extension points.
- Property controls pass props to code components through the Framer interface.
- Code overrides modify layer properties or functionality in preview and on
  the published site.
- CMS APIs expose collections, fields, items, slugs, draft state, field data,
  managed collections, and sync/configuration plugin modes.

Inferred:

- Framer maps well to local runtime-binding, component-parameter, route, and
  web projection concepts.
- Framer is better treated as a web runtime/component donor than as a design
  file schema donor.

Unknown:

- Full editable project schema is not available.
- Stable project export/remix file structure is not confirmed.
- Full mapping from visual canvas interactions to developer API structures is
  not exhaustively documented in local evidence.

## Useful Later

- component props and property-control model
- code component / canvas component boundary
- override boundary between visual layer and runtime behavior
- route/published-runtime model
- CMS field/item/collection model for data-backed prototypes
- plugin mode and sync model
- warning model for runtime overrides that can break built-in behavior
- web projection distinction from production implementation

## Do Not Absorb

- production React architecture into the behavior DSL
- code component internals as product source of truth
- Framer published output as canonical product behavior
- CMS data model as product requirements
- editable project assumptions without official artifact access
- web runtime assumptions into Apple-native interaction contracts
- Framer-specific plugin mechanisms into generic Product Experience artifacts
