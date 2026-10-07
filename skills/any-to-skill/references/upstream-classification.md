# Upstream Classification

`upstreams.yaml` may attach an optional `classification` block to a source.
The block is source-routing metadata: it helps prioritize intake and route
distillation, but it is not proof that a capability has been reviewed,
integrated, or closed.

`any-to-skill` owns this definition because `upstreams.yaml` is a concrete
manifest produced and maintained per repository, while source classification is
part of the source-orchestration contract.

## Fields

```yaml
classification:
  provenance: official | official-adjacent | third-party
  focus: focused-domain | broad-catalog | checklist-heavy
  domains:
    - <domain>
  absorption_priority: high | medium | low
```

- `provenance` records source authority.
  - `official`: source is published by the product, platform, or skill host.
  - `official-adjacent`: source is published by a directly adjacent expert,
    lab, framework owner, former official contributor, or well-known platform
    team, but is not itself official policy.
  - `third-party`: independent source.
- `focus` records the shape of the source.
  - `focused-domain`: source has a coherent professional domain boundary.
  - `broad-catalog`: source is a mixed catalog; inspect by segment.
  - `checklist-heavy`: source is mainly large checklists or reference data;
    use for recall and gap checks rather than direct skill structure.
- `domains` records the local professional topics worth routing or absorbing.
  Use stable capability words, not upstream branding.
- `absorption_priority` records triage order for future distillation passes.

## Domain Vocabulary

Use stable capability words, not upstream branding. Cross-functional sources
may include product or engineering domains because one source row can route to
multiple collections.

For design and user-experience intake, prefer these domain names unless a later
collection decision adds a sharper owner:

- `design-md-template`
- `interface-design`
- `interaction-design`
- `interface-review`
- `ux-audit`
- `visual-design`
- `layout-composition`
- `design-system`
- `design-tokens`
- `component-spec`
- `ui-patterns`
- `typography`
- `color-system`
- `motion-system`
- `accessibility`
- `severity-remediation`
- `ux-writing`
- `interface-naming`
- `design-handoff`
- `design-research`
- `usability-testing`
- `brand-system`
- `visual-identity`
- `theme-system`
- `artifact-design`
- `canvas-design`
- `generative-visuals`
- `chart-design`
- `frontend-quality`
- `react-quality`

## Routing Notes

- Keep `classification` separate from `review_coverage`. A high-priority
  source can still be unreviewed.
- For `broad-catalog` sources, use `review_segments` to route concrete slices.
- Prefer professional-domain skills for design absorption. Do not convert a
  broad upstream workflow catalog into a local process chain unless the local
  collection explicitly decides to own that workflow.
- Treat checklist-heavy sources as recall aids and audit inputs; distillation
  must remove generic or duplicated checklist material before authoring.

## Future Split Boundary

Keep this reference in `any-to-skill` while source classification is only
routing metadata for skill intake.

Prefer splitting by artifact evidence type before inventing a generic
subscription owner. `skill-distiller` already owns skill-source to local-skill
conservation for upstream skills, prompts, workflows, and copied skill
material. The Swift collection also has `swiftpm-distiller`, which distills
SwiftPM package and Swift library evidence into skill-creation handoff
material. Similar specialized artifact distillers may be appropriate if future
inputs become large enough, such as codebase-to-skill, design-to-skill,
docs-to-skill, or API/SDK-docs-to-skill. These specialized skills can run
directly when the user already provides a clear artifact and goal;
`any-to-skill` remains the total router when the work starts from upstream
tracking, mixed sources, owner routing, or receipt bundle coordination.

If upstream tracking grows, split it before it crowds the router. A future
tracking owner could own source discovery, persistent checkout refresh,
HEAD/cursor comparison, `watch_paths`, `review_segments`, changed-path
summaries, source health, scoring, notifications, duplicate-source
consolidation, and tracking-state recommendations. That split would leave
`any-to-skill` with intake routing, owner selection, distiller selection,
receipt-bundle
coordination, and final handoff gates. `skill-distiller` would continue to own
skill-source conservation, and specialized artifact distillers would own
non-skill-source evidence extraction.
