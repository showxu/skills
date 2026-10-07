# Eval Fixtures

These fixtures are durable behavior inputs for `code-to-arch`. They
are not dated run artifacts and do not replace real eval execution.

Eval fixtures are not example captures by default. A fixture may seed an
example capture only when the capture is labeled honestly, separates synthetic
input from validated evidence, and does not claim architecture truth or formal
orchestrator run evidence without the required proof.

## trigger-selection-fixtures

Target behavior: trigger only when upstream or donor evidence is being
reconstructed into local architecture, local framework boundaries, docs truth,
or implementation planning.

Positive examples:

- "Study Swift Testing performance style, swift-benchmark runner concepts,
  SwiftNIO benchmarks, and Apple signposts, then design our local
  Benchmark/Instruments architecture."
- "Compare Remodex, codexflow, CodexMobile, official Codex app-server concepts,
  and relay/gateway patterns to decide our local endpoint/gateway/relay
  architecture."
- "Extract a Settings DSL from Apple Settings and SwiftUI Form, Section,
  Toggle, Picker, and LabeledContent semantics."
- "Use GitHub Markdown, swift-markdown, MarkdownUI, and streaming renderer
  practice to define our Markdown Streaming syntax/block taxonomy."

Negative examples:

- "Fix this compile error."
- "Update README formatting."
- "Find me popular Swift repos."
- "Write a product landing page."
- "Implement this function from the existing design."
- "Create a generic benchmark runner from scratch."

Ambiguous examples:

- "Research Swift benchmark libraries."
- "Compare MarkdownUI and swift-markdown."
- "Look at Remodex."
- "Review our Settings DSL."

Ambiguous examples trigger this skill only when the task includes donor or
upstream evidence being reconstructed into local architecture, local framework
boundaries, docs truth, or implementation planning. Without that local
reconstruction goal, route to ordinary research, docs, product, coding, or
domain-specific review workflows.

Forbidden behavior:

- Treats all upstream research as this skill's scope.
- Treats ordinary docs cleanup or implementation-only work as distillation.
- Starts a new framework from scratch without donor/upstream evidence.

## benchmark-instruments-dry-run

Target behavior: distill benchmark and instrumentation donors into an
Instruments-first local architecture while keeping benchmark runner concerns
separate from production instrumentation.

Input prompt:

```text
Study Swift Testing performance style, swift-benchmark-style runner concepts,
SwiftNIO benchmark practices, Apple Instruments/signpost concepts, and
os_signpost-style instrumentation. Distill the useful ideas into our local
Benchmark/Instruments architecture. Do not implement runtime code.
```

Expected output:

- Reads local architecture truth first.
- Classifies donors as official platform/API, mature community implementation,
  test/fixture, naming/documentation, or anti-pattern donors as appropriate.
- Extracts benchmark declaration shape, warmup, iteration, sampling,
  statistics, baseline/regression gates, span recording, static names with
  dynamic attributes, safe span ending, and nested/contextual spans.
- Rejects production instrumentation depending on benchmark runners,
  over-generalized benchmark APIs, and wholesale adoption of one donor model.
- Reconstructs an Instruments-first public model where macro/declarative API
  maps into instrumentation runtime.
- Keeps recorder abstraction open to signpost and future in-memory/timeline
  recorders.
- Keeps benchmark runner and benchmark policy in a separate testing layer.
- Uses subagent mode or per-source findings when donor inspection is split.
- Produces synthesis before architecture truth changes.
- Produces architecture truth updates, risks/non-goals, and a self-contained
  Codex follow-up prompt.

Forbidden behavior:

- Forces warmup, iteration, sampling, statistics, baseline, or regression gates
  into the production instrumentation runtime.
- Makes production instrumentation depend on a benchmark runner.
- Copies one upstream library's API or file layout wholesale.
- Lets subagents directly edit `Docs/Architecture`.

## remote-codex-orchestration

Target behavior: split official, product/community, and network-pattern donors
into findings, then synthesize endpoint/gateway/relay boundaries.

Input prompt:

```text
Compare Remodex, codexflow, CodexMobile, official Codex app-server concepts,
and relay/gateway patterns for our Remote Codex architecture. Produce the
distillation before updating Docs/Architecture.
```

Expected output:

- Reads local truth first.
- Uses subagent mode or per-source findings for official app-server,
  product/community donors, and relay/gateway/network donors.
- Produces main-agent synthesis of endpoint, gateway, bridge, and relay
  boundaries.
- Requires HITL before architecture truth changes.
- Keeps donor product architecture from becoming local architecture by default.

Forbidden behavior:

- Lets donor products define local architecture wholesale.
- Treats relay/gateway layers as accepted truth without the Architecture Truth
  Gate.
- Lets subagents directly edit `Docs/Architecture`.

## hitl-boundary-gates

Target behavior: require HITL for material boundary and architecture truth
decisions.

Input prompts:

```text
Turn upstream findings into our public Settings DSL surface.
Decide whether benchmark runner concepts belong in production instrumentation runtime.
```

Expected output:

- Uses Local Reconstruction Gate and Architecture Truth Gate for the Settings
  DSL public surface.
- Uses Boundary Gate for benchmark runner concepts versus production
  instrumentation runtime.
- States options, recommended direction, risks, and docs destination before
  asking.

Forbidden behavior:

- Writes accepted `Docs/Architecture` changes without the required gate.
- Hides donor baggage decisions inside implementation planning.

## hitl-before-material-work

Target behavior: use HITL before material scope, boundary, or
architecture-truth decisions.

Input prompts:

```text
Use upstream benchmark libraries to rethink our Benchmark/Instruments architecture.
Run a dry-run eval using the already accepted Benchmark/Instruments objective and produce findings only.
Decide whether benchmark runner policy belongs inside production Instruments runtime.
```

Expected output:

- For "rethink architecture", triggers Scope / Goal Gate first because the goal
  is broad.
- Clarifies primary target, secondary targets, explicit non-goals, and output
  mode.
- For the dry-run eval with an accepted objective, proceeds without Scope Gate
  and produces findings only.
- For benchmark runner policy inside production Instruments runtime, uses
  Boundary Gate before local reconstruction or `Docs/Architecture` updates.
- Does not immediately edit `Docs/Architecture`.

Forbidden behavior:

- Starts broad donor work when the architecture goal is ambiguous.
- Treats dry-run findings as accepted architecture truth.
- Moves benchmark policy into production runtime without the Boundary Gate.

## synthetic-remote-codex-scope-gate

Target behavior: test Scope / Goal Gate behavior and donor/orchestration routing
without reading real product repositories or validating real architecture facts.

Fixture type: synthetic skill-behavior fixture. It must not require reading the
user's real Remote Codex repos.

Input prompt:

```text
Use Remodex, codexflow, CodexMobile, official Codex app-server concepts, and
relay/gateway patterns to rethink our Remote Codex endpoint/gateway/relay
architecture.
```

Synthetic local context:

- The local product is a Remote Codex app.
- The intended direction is roughly RemoteApp -> Connectivity Endpoint ->
  CodexAppServerSDK -> codex app-server.
- Bridge, Gateway, and Relay are not all accepted as Phase 1 runtime
  requirements.
- Tailscale-style private networking and Cloudflare-style relay are candidate
  connectivity patterns, not mandatory architecture truth.
- The user wants donor ideas distilled into local framework boundaries, not a
  clone of any donor product.

Synthetic donors:

- Official Codex app-server concepts: high-authority protocol/API donor for
  endpoint, session, approval, and event boundaries.
- Remodex: product/implementation donor for bridge and remote-access flow.
- codexflow: product/UX/community donor for remote session workflow ideas.
- CodexMobile: product/mobile donor for endpoint/session UX references.
- Relay/gateway patterns: architecture pattern donor for endpoint, gateway,
  relay, auth, and transport separation.

Expected output:

- Triggers `code-to-arch`.
- Stops at Scope / Goal Gate before donor work.
- Asks for primary target, secondary targets, explicit non-goals, and output
  mode.
- Explains that subagent/per-source findings are appropriate only after scope
  is accepted.
- Does not synthesize final architecture, produce architecture truth, create
  product artifacts, or treat synthetic donor facts as verified evidence.

Forbidden behavior:

- Reads the user's real Remote Codex repos.
- Creates `.agent/code-to-arch-distillation/*` artifacts in a product
  repo.
- Treats synthetic donor facts as verified evidence.
- Starts donor analysis before Scope / Goal Gate is answered.

## artifact-flow-before-docs

Target behavior: produce staged artifacts before accepted architecture truth.

Input prompt:

```text
Run a multi-donor distillation before updating Docs/Architecture.
```

Expected output:

- Writes or returns per-source findings first.
- Produces main-agent synthesis after findings.
- Keeps donor evidence in the staged workspace and writes accepted reference
  facts to `Docs/Reference` in product language when useful.
- Uses `Docs/Proposals` for unaccepted reconstruction.
- Updates `Docs/Architecture` only after required HITL gates.

Forbidden behavior:

- Skips straight from donor scan to architecture truth.
- Treats `.agent/code-to-arch-distillation/<topic>/findings/*` or
  `.agent/code-to-arch-distillation/<topic>/synthesis.md` as current
  architecture truth.

## negative-orchestration-boundaries

Target behavior: avoid orchestration when the task lacks local reconstruction
or distillation scope.

Input prompts:

```text
Review this one upstream file and summarize what it does.
Fix this compile error using existing architecture.
```

Expected output:

- Does not use subagent mode for a one-file summary unless local reconstruction
  is requested.
- Does not trigger this skill for compile-error fixing under accepted
  architecture.

Forbidden behavior:

- Converts a simple summary into a full distillation.
- Uses this skill for implementation-only coding with no new donor evidence.

## upstream-intake-no-copy

Target behavior: turn donor evidence into local architecture recommendations
without copying upstream structure.

Input prompt:

```text
Use upstream Project A, official API B, and community implementation C to design
the local framework direction for our telemetry API. Do not implement code.
```

Expected output:

- Reads local architecture truth before accepting donor conclusions.
- Classifies each donor.
- Extracts capabilities, semantics, API ergonomics, tests, and boundaries.
- Lists rejected donor baggage.
- Reconstructs a local model rather than copying donor file layout.
- Produces a self-contained next Codex prompt.

Forbidden behavior:

- Copies donor architecture as the local architecture.
- Treats upstream as current truth without local docs.
- Starts implementation without an accepted architecture direction.

## architecture-review-doc-truth

Target behavior: review local docs against upstream evidence and separate
current truth from reference evidence.

Input prompt:

```text
Review whether Docs/Architecture matches the donor findings in Docs/Reference
for the Remote Codex app-server route. Recommend docs edits only.
```

Expected output:

- Gives phase / stage judgment.
- Summarizes what local docs say.
- Compares upstream evidence against local truth.
- Reports over-copying, under-absorption, and boundary risks.
- Recommends doc changes by destination: Architecture, Reference, Proposals,
  Decisions, AGENTS.md, README, or execution plan.

Forbidden behavior:

- Mixes donor evidence into architecture truth without labels.
- Treats `.agent` plans as architecture truth.
- Performs runtime implementation.

## implementation-plan-after-distillation

Target behavior: convert an accepted distilled design into a phased
implementation plan without hidden context.

Input prompt:

```text
Using the accepted Markdown Streaming architecture docs, create an implementation
plan for the smallest syntax/block streaming slice. Do not write code yet.
```

Expected output:

- Reads architecture truth and local code paths first.
- Preserves module boundaries.
- Names affected files or file families.
- Defines phased slices, tests, validation commands, risks, non-goals,
  acceptance criteria, and implementation seams.
- References architecture truth for major design choices.

Forbidden behavior:

- Assumes hidden conversation context.
- Collapses renderer behavior into syntax truth.
- Skips test and validation planning.

## reusable-case-capture

Target behavior: add a compact curated case capture only when explicitly asked,
rather than preserving a transcript or creating scaffold cases by default.

Input prompt:

```text
Capture this Swift Settings donor-distillation case so future agents know what
to extract and what not to copy.
```

Expected output:

- Uses the standard case capture sections.
- Records donors, extracted capabilities, rejected baggage, local
  reconstruction, architecture truth produced, reusable lesson, and Codex
  follow-up.
- States that the case is a reusable example, not an exhaustive historical
  record.

Forbidden behavior:

- Includes private conversation details.
- Claims the case is a complete historical record.
- Omits rejected baggage or local reconstruction.
