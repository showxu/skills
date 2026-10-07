# Source Verification

Use source-backed evolution when a skill can improve from current authoritative
sources instead of from Codex conversation history.

The goal is not to let agents crawl the web and rewrite skills. The goal is to
let a skill declare the sources that can update its mutable facts, compare those
sources with the local rule, reference, script, or trigger that depends on them,
and produce an update packet for the correct authoring owner.

The source-verification phase owns primary evidence and per-target update
packets. This phase does not own final single-skill edits. For one existing target skill, hand the
packet to `skill-creator`. For several independently updatable existing skills,
produce one packet per target. For new skills, splits, renames, ownership
conflicts, or collection boundary changes, prepare a repository architecture
packet.

## Source Classes

Primary sources can directly justify a skill update when the relevant claim is
verified current:

- official product, platform, API, SDK, or framework documentation
- official design, asset, or resource pages and direct vendor download links
- current CLI or tool help from the installed tool
- current API schemas, OpenAPI specs, package manifests, or generated symbol
  graphs
- observed host behavior from a small local probe, build, test, or dry run

Secondary sources can propose questions, not local rules:

- curated indexes and awesome lists
- community articles, examples, talks, or repos
- prompt leaks, trend reports, and internal-doc-style material from elsewhere
- upstream skill repositories that encode another author's workflow

Secondary sources must be translated into a verification question and checked
against a primary source before they become trigger, workflow, validation, API,
platform, policy, or safety guidance.

## Per-Skill Source Maps

A skill that stores mutable external facts should make its source authority
machine-visible. Existing local patterns are enough:

- `references/official-sources.md`
- `references/official-authority.md`
- `references/*sources*.md`
- `references/*authority*.md`
- `references/*freshness*.md`
- `references/*drift*.md`
- source refresh or extractor scripts under `scripts/`

The source map should name:

- source URL, command, schema path, or probe command
- source class: official docs, tool help, API schema, resource endpoint,
  observed host behavior, any-to-skill handoff, or secondary signal
- local claim or file that depends on the source
- verification method and known failure mode
- last checked date only when it was actually checked

If no source map exists, propose adding one before accepting a broad
source-backed mutation.

## Workflow

Use the helper with an explicit repository root and exact target names:

    python3 <agent-evolver>/scripts/collect_sources.py --root <repository> --skill <name> --json

Repeat --skill for several exact targets. Use --term only for fuzzy discovery.
The inventory reports source locations; it does not verify their knowledge.

1. Inventory current skills and source/freshness references with
   `scripts/collect_sources.py`.
2. Pick only the skills whose rules depend on mutable facts. Do not refresh
   stable writing style, output structure, or project-local routing just
   because a web source exists.
3. For each selected skill, read its source map and identify the smallest
   claim to verify.
4. Verify the current primary source:
   - browse or fetch official pages only when docs are the authority
   - run local `--help`, version, schema, build, or dry-run probes when tool
     behavior is the authority
   - use source-specific scripts when the skill already has an extractor
5. Compare the verified source with the local skill claim.
6. Classify the result:
   - `accept update`: verified source contradicts or materially strengthens an
     existing skill rule, reference, trigger, script, or template
   - `watch`: source changed but the local impact is unclear
   - `no-change`: local guidance still matches, or the source is irrelevant
   - `needs owner decision`: update requires a new skill, split, removal,
     policy shift, broad rewrite, live service mutation, or new dependency
7. Prepare the smallest local repair as an update packet, not a patch:
   - update a focused reference before changing the trigger
   - add a validation or freshness rule before adding a new workflow
   - add an extractor or fixture test when exact numeric/API facts matter
   - create a new skill only when the source changes the workflow boundary
8. Route one packet per existing target to `skill-creator` when responsibilities
   are unchanged. Prepare a repository architecture packet for new skills,
   splits, renames, ownership conflicts, or collection-boundary work.

## Ledger

For recurring source freshness jobs, keep a source-freshness ledger separate
from the raw-session processed-evidence ledger. A practical row shape is:

```text
date | skill | source id/url/command | source version/hash | local claim | decision | checked by | closed by
```

Use the ledger to avoid repeatedly promoting the same source change. Do not
mark a source row closed unless the local claim was compared and assigned a
decision bucket.

For recurring maintenance, distinguish source inspection from verified skill
behavior. Record the inspected source revision or content hash and its check
result separately from the skill revision, host/toolchain, deployment target,
and evidence used for behavioral validation. A successful fetch does not
advance the last validated revision. A failed fetch does not advance the last
successful source check; record the attempt and failure separately.

Keep the ledger in the calling repository's local maintenance state. Useful
fields extend the existing row rather than introduce another eval format:

- source identity, inspected version/hash, successful check time, failed attempt
- target skill revision, affected claim, decision, evidence pointer
- last validated skill revision, environment, compiler and runtime results
- source/skill ownership, protected rule locations, unresolved owner decisions
- affected overlap or replacement relationships and the revisions compared
- pending work, applied batch, recovery evidence, and last notification key

Recheck affected overlap and replacement claims when either participant or its
source changes. Keep complementary capabilities and old-target compatibility
unless evidence changes their applicability. An unchanged source and skill
pair should reuse its prior disposition; a failed or untriaged item stays open.
Retirement requires evidence that the receiving owner completes the relevant
tasks in the actual host, followed by the owner's removal decision.

The caller may combine source verification, conservation review, and an
explicitly authorized authoring pass. This evidence workflow still returns
packets and does not execute downstream mutations or grant their authorization.

## Boundaries

- Do not browse arbitrary search results and treat them as authority.
- Do not copy external docs into local skills; keep links, source hierarchy,
  and distilled local rules.
- Do not let a community source override official docs, current tool help, or
  observed host behavior.
- Do not automatically mutate live service state, account configuration,
  package versions, or product code from a source freshness audit.
- Do not turn a broad source refresh into skill sprawl. Update the existing
  owner first when its trigger still fits.
- Do not make final single-skill edits, trigger hardening, fixtures, evals, or
  package-readiness claims here. `skill-creator` owns those steps after it
  receives the source-backed update packet.

## Examples

- `apple-hig`: HIG pages, Apple Design Resources, SwiftUI docs, and HIG metric
  extractors can refresh platform visual guidance.
- App Store operation skills: Apple docs, App Store Connect API behavior,
  backend command help, and account readbacks can refresh field limits and
  safe operation rules.
- Swift and SwiftUI pattern skills: official Swift Evolution proposals,
  language docs, SDK docs, symbol graphs, and current compiler diagnostics can
  refresh API availability and implementation constraints.
- CLI-backed skills: current `--help`, version output, dry runs, and command
  schemas can refresh flags, output shapes, and failure handling.
