# Historical Provenance Only

This file records superseded upstream absorption history. It is not active product-management routing authority after the hard three-stage consolidation. Active public skills are only `product-feature-creator`, `product-discovery`, `product-requirements`, and `interaction-design`.

# Product Documentation First-Wave Post-Authoring Conservation Review

## Scope

- Review date: 2026-05-10
- Feed plan: `product-management/PLAN.md`
- Receipt bundle: `B1-product-doc-first-wave`
- Reviewed receipts: `H1` through `H11`
- Authoring result: six first-wave `product-management` skills plus collection
  README and marketplace metadata
- Closeout question: pass

This review checks whether accepted distiller receipt rows survived final
authoring. Verdicts use the feed/distiller contract terms:
`preserved`, `compressed-ok`, `missing`, `distorted`, `blocked`, or `deferred`.

## Review Packets

| Review id | Target | Receipt scope | Verdict | Evidence |
|---|---|---|---|---|
| `R-product-requirements` | `product-management/skills/product-requirements/` | `H1`, `H2`, `H3`, `H6`, `H8` | pass | `SKILL.md`, template, example, source ledger, eval fixtures, and manual metadata preserve PRD/source-of-truth behavior and boundaries. |
| `R-code-to-product-feature` | `product-management/skills/code-to-product-feature/` | `H7` | pass | Skill and references preserve code-derived evidence scan, uncertainty labeling, mock/live distinction, and non-intent boundary. |
| `R-product-user-stories` | `product-management/skills/product-user-stories/` | `H4`, `H9` | pass | Skill and references preserve persona/JTBD modes, traceability, 3C/INVEST checks, and route detailed acceptance work away. |
| `R-product-acceptance-criteria` | `product-management/skills/product-acceptance-criteria/` | `H5`, `H10` | pass | Skill and references preserve Given/When/Then, observable outcomes, edge/error coverage, and QA automation boundary. |
| `R-product-feature-creator` | `product-management/skills/product-feature-creator/` | `H11` plus local route rows | pass | Skill and references preserve package orchestration, sequencing, integration, decision routing, and subagent authorization boundaries. |
| `R-product-interaction` | `product-management/skills/product-interaction/` | local-first route rows | pass | Skill and references preserve product-owned flow/state behavior while routing UX craft, HIG, visual design, and implementation away. |
| `R-collection-surfaces` | README and marketplace metadata | `B1` collection routing packet | pass | README skill list, capability matrix, install commands, and marketplace plugin entries expose all six skills. |

## Row-Level Verdicts

### Product Requirements

| Receipt | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| `H1` | trigger cues | `product-requirements/SKILL.md` | compressed-ok | Frontmatter and `When To Use` trigger on PRDs, product requirements, specs, and source-of-truth artifacts. |
| `H1` | clarification gate | `product-requirements/SKILL.md`; eval fixtures | compressed-ok | Workflow clarifies only material decisions and fixtures cover thin-evidence behavior. |
| `H1` | PRD backbone | `product-requirements/references/template.md` | compressed-ok | Template includes problem, evidence, goals, scope, requirements, metrics, risks, dependencies, and questions. |
| `H1` | story and criteria quality bar | `product-requirements/SKILL.md`; sibling boundaries | compressed-ok | Requirements skill preserves testable requirement quality while routing stories and criteria to owners. |
| `H1` | non-implementation boundary | `product-requirements/SKILL.md` | compressed-ok | Boundary excludes implementation plans, QA automation, and engineering tasks. |
| `H1` | UI and typecheck verification clause | `software-engineering` owner | deferred | Explicitly routed outside product-management; no local QA or build execution added. |
| `H1` | output placement rule | `product-requirements/SKILL.md`; template | compressed-ok | Output path and durable artifact guidance are present. |
| `H1` | example and completion checklist | example; eval fixtures | compressed-ok | Example and fixtures calibrate PRD quality. |
| `H1` | frontmatter naming and style metadata | source ledger / no local behavior | compressed-ok | Non-capability row intentionally omitted from runtime behavior. |
| `H2` | use and do-not-use boundaries | `product-requirements/SKILL.md` | compressed-ok | Trigger and `When Not To Use` preserve major PRD fit and false-match boundaries. |
| `H2` | PRD question model | `product-requirements/SKILL.md`; template | compressed-ok | Workflow and template preserve problem, users, why now, solution, metrics, requirements, non-goals, and open questions. |
| `H2` | ten-section template | template | compressed-ok | Local template compresses source sections without dropping required content. |
| `H2` | evidence-first framing | workflow; eval fixtures | compressed-ok | Evidence precedence and no-fabrication fixtures are present. |
| `H2` | metrics model | template; fixtures | compressed-ok | Success metric section includes baseline, target, method, and guardrails. |
| `H2` | scope, risks, dependencies, and questions | template | compressed-ok | All are first-class template sections. |
| `H2` | anti-patterns and pitfalls | eval fixtures; validation rules | compressed-ok | Missing metrics, weak scope, unsupported decisions, and timeline leakage are checked. |
| `H2` | multi-phase orchestration references | `product-feature-creator`; future PM owners | deferred | Package orchestration exists; discovery/persona/sizing extensions remain future-owner rows. |
| `H2` | facilitation protocol delegation | future orchestration owner | deferred | Not added to PRD authoring; no unsupported conversation protocol was imported. |
| `H2` | day-by-day sequencing and approval cadence | future product ops or project owner | deferred | Calendar mechanics are excluded and covered by a fixture. |
| `H2` | external reading list and placeholders | source ledger / no local behavior | compressed-ok | Unverified bibliography was not promoted to runtime authority. |
| `H3` | trigger contract | `product-requirements/SKILL.md` | compressed-ok | PRD/spec drafting and review trigger is present. |
| `H3` | intake and context gathering | workflow; source ledger | compressed-ok | Inputs and workflow require provided docs, research, and context. |
| `H3` | pre-write reasoning checklist | workflow | compressed-ok | Workflow requires problem, users, success, constraints, and tradeoffs before drafting. |
| `H3` | eight-section template | template | compressed-ok | Source shape is represented in local template sections. |
| `H3` | outcome measurement framing | template; fixtures | compressed-ok | Goals and metric expectations are preserved. |
| `H3` | accessibility and clarity writing bar | quality rules | compressed-ok | Plain-language and cross-functional readability guidance is preserved. |
| `H3` | output artifact persistence | output format | compressed-ok | Durable path guidance is present. |
| `H3` | optional UX and technical subsections | boundary notes | compressed-ok | UX/technical material is treated as reference or handoff, not ownership. |
| `H3` | external reading links | source ledger / no local behavior | compressed-ok | Supplemental links were not made local authority. |
| `H6` | toolkit trigger and scope | `product-requirements`; future backlog | compressed-ok | PRD-relevant trigger cues are preserved and broader toolkit scope is split. |
| `H6` | PRD template selection | template | compressed-ok | Feature brief, one-page PRD, and full PRD modes are present. |
| `H6` | PRD development flow | workflow | compressed-ok | Scope, draft, review, refine, and track outcome logic is compressed into workflow and handoff notes. |
| `H6` | problem-first PRD guidance | quality rules | compressed-ok | Problem, success metrics, scope, and evidence-first rules are present. |
| `H6` | review cycle roles | source ledger; handoff notes | compressed-ok | Stakeholder review lenses survive as handoff readiness, not mandatory workflow. |
| `H6` | post-launch tracking | future product metrics or ops | deferred | Outcome tracking is not first-wave PRD ownership. |
| `H6` | RICE prioritization workflow | future `product-prioritization` | deferred | Prioritization is deferred and not folded into PRD authoring. |
| `H6` | roadmap capacity planning | future prioritization or roadmap owner | deferred | Roadmap mechanics remain deferred. |
| `H6` | customer discovery workflow | future `product-discovery` | deferred | Discovery operations remain deferred. |
| `H6` | interview best practices | future `product-discovery` | deferred | Interview workflow is not imported into PRD skill. |
| `H6` | metrics frameworks | `product-requirements`; future `product-metrics` | compressed-ok | Success metric prompts are present; full metric frameworks are deferred. |
| `H6` | GTM checklist | `go-to-market`; future product launch-readiness owner | deferred | Market execution remains out of scope. |
| `H6` | integration platform list | source ledger / evidence categories | compressed-ok | Tool list is not treated as stable workflow behavior. |
| `H6` | common pitfalls | quality rules; fixtures | compressed-ok | Pitfalls are represented as PRD quality checks. |
| `H6` | best-practice summaries | workflow; template | compressed-ok | Problem-first, metric, scope, evidence, and appendix guidance is preserved. |
| `H8` | trigger boundary | `product-requirements/SKILL.md` | compressed-ok | PRD timing and boundary are present. |
| `H8` | PRD drafting recipe | workflow; template | compressed-ok | Problem, goals, solution, requirements, scope, constraints, and risks are present. |
| `H8` | metric rigor | template; fixtures | compressed-ok | Baselines, targets, and measurement method are present. |
| `H8` | requirement quality | validation rules | compressed-ok | Requirements must be testable and unambiguous. |
| `H8` | scope partitioning | template | compressed-ok | In-scope, out-of-scope, and later are separate. |
| `H8` | constraints, dependencies, and risks | template | compressed-ok | Dependency and risk sections exist. |
| `H8` | timeline and milestones | future ops or roadmap owner | deferred | Schedule mechanics are excluded and captured only as risk/dependency. |
| `H8` | quality checklist | eval fixtures | compressed-ok | Checklist behavior is represented in fixtures and validation rules. |
| `H8` | template and completed example assets | template; example | compressed-ok | Scaffold and worked example are present. |
| `H8` | command wrapper | no local behavior | compressed-ok | Provider wrapper intentionally omitted. |
| `H8` | frontmatter framework tags and branding metadata | no local behavior | compressed-ok | Packaging metadata intentionally omitted. |

### Code To Product Feature

| Receipt | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| `H7` | trigger contract | `code-to-product-feature/SKILL.md` | compressed-ok | Description and usage trigger on code-derived product documentation. |
| `H7` | dual audience framing | `SKILL.md`; template | compressed-ok | Output remains product-readable with engineering traceability. |
| `H7` | phase 1 global scan | workflow | compressed-ok | Workflow scans framework, routes, APIs, models, auth, config, flags, and shared state. |
| `H7` | route and endpoint inventory | template | compressed-ok | Template includes surface inventory with route/API fields. |
| `H7` | global context mapping | template | compressed-ok | Shared components, permissions, config, models, and relationships are represented. |
| `H7` | page-by-page analysis | workflow; template | compressed-ok | Surface analysis sections cover layout, fields, interactions, APIs, and rules. |
| `H7` | field extraction priority | guardrails | compressed-ok | Visible labels and translations are preferred over variable names. |
| `H7` | action-response interaction format | template | compressed-ok | User action, system response, validation, success, and failure paths are captured. |
| `H7` | API dependency handling | guardrails | compressed-ok | Real, mock, fixture, hardcoded, and missing integrations are distinguished. |
| `H7` | enum and model extraction | template | compressed-ok | Constants, statuses, roles, constraints, and relationships are included. |
| `H7` | uncertainty marking | quality checklist | compressed-ok | Unknowns and inferred intent are explicitly labeled. |
| `H7` | output directory shape | output contract | compressed-ok | Evidence package structure replaces upstream directory shape. |
| `H7` | framework-specific lookup guidance | `references/framework-patterns.md` | compressed-ok | Framework lookup guidance is preserved as progressive reference material. |
| `H7` | PRD quality checklist | eval fixtures | compressed-ok | Hidden modals, permissions, mocks, errors, and unlinked pages are fixture risks. |
| `H7` | large-project pacing | workflow | compressed-ok | Batching guidance is present. |
| `H7` | attribution and external inspiration | source ledger / no local behavior | compressed-ok | Provenance remains in ledger, not public runtime behavior. |

### Product User Stories

| Receipt | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| `H4` | persona-story trigger | `product-user-stories/SKILL.md` | compressed-ok | Description and usage trigger on persona stories. |
| `H4` | job-story trigger | `product-user-stories/SKILL.md` | compressed-ok | JTBD mode is supported. |
| `H4` | input arguments | template | compressed-ok | Input preflight captures context, assumptions, constraints, and design references. |
| `H4` | persona process rules | workflow; fixtures | compressed-ok | 3C, INVEST, role/journey decomposition, and value slicing are present. |
| `H4` | JTBD process rules | workflow; fixtures | compressed-ok | Situation, motivation, and outcome reasoning is present. |
| `H4` | story statement templates | template | compressed-ok | Persona and JTBD statement forms are present. |
| `H4` | acceptance-depth guidance | `product-acceptance-criteria` handoff | deferred | Detailed acceptance authoring is routed to acceptance criteria owner. |
| `H4` | design-link expectations | guardrails; template | compressed-ok | Design links are references only, not design authority. |
| `H4` | example artifacts | example; fixtures | compressed-ok | Persona and JTBD examples are present. |
| `H4` | deliverable constraints | quality checklist | compressed-ok | Independent, small, valuable, and traceable constraints are present. |
| `H4` | external reading links | no local behavior | compressed-ok | Off-repo educational links are not local authority. |
| `H9` | trigger and when-to-use | `product-user-stories/SKILL.md` | compressed-ok | Requirements-to-story trigger and review mode are present. |
| `H9` | requirement traceability | workflow; source ledger | compressed-ok | Stories must map back to specs or evidence. |
| `H9` | persona identification | workflow | compressed-ok | Persona specificity is required. |
| `H9` | goal-based decomposition | workflow | compressed-ok | Stories split by user value and workflow step. |
| `H9` | story statement rule | template | compressed-ok | Persona, action, and benefit are represented. |
| `H9` | INVEST checklist | validation rules; fixtures | compressed-ok | INVEST checks are explicit. |
| `H9` | Given/When/Then emphasis | `product-acceptance-criteria` handoff | deferred | Acceptance detail is routed out of story owner. |
| `H9` | template traceability fields | template | compressed-ok | Traceability, context, non-goals, and open questions are present. |
| `H9` | planning fields | `software-engineering` planning owners | deferred | Backlog and sprint mechanics are excluded. |
| `H9` | technical notes | `software-engineering` owners | deferred | Implementation and architecture hints are excluded. |
| `H9` | design notes | template with boundary | compressed-ok | Design links remain references only. |
| `H9` | example story set | example; fixtures | compressed-ok | Story example and fixtures are present. |
| `H9` | command wrapper | `agents/openai.yaml`; source ledger | compressed-ok | Manual entry exists without upstream command coupling. |
| `H9` | frontmatter metadata | no local behavior | compressed-ok | Non-behavioral metadata is omitted. |

### Product Acceptance Criteria

| Receipt | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| `H5` | trigger and use cases | `product-acceptance-criteria/SKILL.md` | compressed-ok | Description and usage trigger on acceptance criteria and testable behavior. |
| `H5` | input contract | template; fixtures | compressed-ok | Story slice, context, assumptions, and constraints are required. |
| `H5` | workflow recipe | workflow | compressed-ok | Story review, objective, preconditions, roles, actions, outcomes, and edge cases are represented. |
| `H5` | scenario structure | template | compressed-ok | Given/When/Then and pass/fail structure preserves scenario behavior. |
| `H5` | worked example | example; fixtures | compressed-ok | Example and fixtures preserve behavior pattern. |
| `H5` | deliverable quality expectations | quality checklist | compressed-ok | Observable outcomes, edge/error behavior, and clear results are required. |
| `H5` | QA execution-ready framing | future QA or test-scenarios owner | deferred | Product criteria remain in scope; QA run mechanics are excluded. |
| `H5` | upstream metadata and branding | no local behavior | compressed-ok | Non-behavioral metadata is omitted. |
| `H10` | trigger and usage boundary | `product-acceptance-criteria/SKILL.md` | compressed-ok | Given/When/Then usage boundary is present. |
| `H10` | scope confirmation rule | workflow | compressed-ok | Workflow identifies story, feature slice, context, exclusions, and constraints. |
| `H10` | observable criterion rule | validation rules | compressed-ok | Criteria must be observable and independently testable. |
| `H10` | flow coverage rule | template | compressed-ok | Happy path, edge cases, error states, and recovery are present. |
| `H10` | non-functional expectations | `SKILL.md`; template | compressed-ok | Product-level non-functional criteria are supported when relevant. |
| `H10` | single-outcome rule | validation rules | compressed-ok | One expected outcome per criterion is required. |
| `H10` | testability rewrite rule | quality rules; fixtures | compressed-ok | Subjective language is rewritten into measurable outcomes. |
| `H10` | output contract | template | compressed-ok | Context, grouped criteria, assumptions, and questions are present. |
| `H10` | template and example assets | template; example; fixtures | compressed-ok | Scaffold, example, and fixtures are present. |
| `H10` | command wrapper and metadata | no local behavior | compressed-ok | Provider wrapper and metadata are omitted. |

### Product Feature Creator

| Receipt | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| `H11` | feature kickoff command | `product-feature-creator/SKILL.md`; workflow | compressed-ok | Package flow sequences problem, hypothesis, requirements, stories, and acceptance. |
| `H11` | multi-artifact workflow | workflow; template | compressed-ok | Later artifacts build on earlier decisions and package integration resolves conflicts. |
| `H11` | problem and hypothesis prelude | template | compressed-ok | Package template captures problem, users, hypothesis, and success signal. |
| `H11` | skill idea entry modes | `B1` collection-routing packet | preserved | Used to classify this first-wave work as `new-skill-needed`; not part of product runtime. |
| `H11` | gap analysis against existing skills | `B1` collection-routing packet | preserved | Collection routing records no existing product skills and creates six new targets. |
| `H11` | why and kill gates | `B1` and plan authorization | compressed-ok | Scope and stop conditions are in the plan; product runtime keeps decision routing. |
| `H11` | split-skill signals | `B1`; README capability matrix | preserved | Six-skill split is implemented and discoverable. |
| `H11` | classification and repo fit | `B1`; marketplace metadata | preserved | Collection and marketplace placement are complete. |
| `H11` | implementation packet shape | `B1`; target skill packets | compressed-ok | Required file set, fixtures, manual metadata, and validation are present. |
| `H11` | staging and promotion mechanics | no local product-management behavior | compressed-ok | Source-specific staging flow intentionally omitted. |
| `H11` | frontmatter linter note | package validators | compressed-ok | All six skill packages validate; descriptions avoid angle brackets. |
| `H11` | command wrapper conventions | source ledger / no command files | compressed-ok | No command files added; manual entry metadata used instead. |
| `H11` | AGENTS entry convention | existing `product-management/AGENTS.md` | compressed-ok | Local route model remains concise and unchanged. |
| `H11` | validation checklist | validators; completion audit | compressed-ok | Single-skill validators and collection validator cover package readiness. |

### Product Interaction

| Receipt | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| local-first | product-owned behavior layer | `product-interaction/SKILL.md`; template; fixtures | preserved | Skill owns flows, states, responses, permissions, interruptions, recovery, and edge cases. |
| local-first | UX craft boundary | `product-interaction/SKILL.md` | preserved | UX craft, HIG, visual design, design systems, implementation, and QA automation are out of scope. |

### Collection Surfaces

| Packet | Row | Assigned target | Verdict | Evidence |
|---|---|---|---|---|
| `B1` | six new first-wave skills | `product-management/skills/*` | preserved | All six skill directories exist with `SKILL.md`, references, fixtures, and `agents/openai.yaml`. |
| `B1` | README skill list and capability matrix | `product-management/README.md` | preserved | README lists six skills and marks deferred/out-of-scope capabilities. |
| `B1` | marketplace metadata | `.claude-plugin/marketplace.json` | preserved | Marketplace has plugin entries for all six skill paths. |
| `B1` | route stubs | `product-management/AGENTS.md` | preserved | Existing route rules remain correct and do not duplicate source ledgers. |
| `B1` | future product discovery, prioritization, metrics | future product-management owners | deferred | Future families remain deferred in README, source ledgers, and upstream closeout outcomes. |
| `B1` | GTM and engineering boundaries | `go-to-market`; `software-engineering` | deferred | Out-of-scope rows are routed by README, skill boundaries, and upstream closeout outcomes. |

## Result

Conservation review passes. No accepted receipt row is missing or distorted.
Rows intentionally not absorbed into a first-wave skill are either assigned to
future product-management owners, moved by collection boundary, or recorded as
non-capability with no local runtime behavior.
