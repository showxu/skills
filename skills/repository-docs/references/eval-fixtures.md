# Eval Fixtures

These are durable inputs and acceptance criteria, not benchmark results.
Materialize selected cases into the evaluator's evals/evals.json and keep
execution outputs with that run. The executor receives the prompt and input
artifacts; expectations remain with the grader.

## ownership-index-and-edit-boundary

Target behavior: Classify ownership by its effect on the reader.

Input prompt: "Audit these AGENTS and README files and propose minimal fixes."

Context and files:

- AGENTS has a module/location/owner table and a short instruction to read the
  wire contract before editing transport, avoiding a second encoder in UI.
- README describes the module and links to the current protocol contract.

Expected output: Move or deduplicate the descriptive table while retaining the
edit boundary and a useful route to the contract.

Forbidden behavior: Move every ownership mention into README; duplicate the
full architecture contract in AGENTS.

Acceptance checks: The report distinguishes descriptive ownership from edit
authority, names exact ranges, and preserves the operational boundary.

Baseline expectation: A keyword classifier may move both passages together.

Evidence sources: Audit output and any proposed or authorized diff.

Owner notes: Generic role-classification invariant.

## public-manual-and-agent-checks

Target behavior: Preserve reader operations and change-specific agent checks.

Input prompt: "Clean up documentation responsibilities for this CLI repo."

Context and files:

- README has setup, a run command, a public device-safety instruction, and a
  test command in Development. It also tells agents to read the security
  contract before changing authentication and to stop on a cross-repo schema
  ownership conflict.

Expected output: Retain the manual and development commands, moving the agent
edit route and escalation to AGENTS.

Forbidden behavior: Move all imperative sentences or commands out of README.

Acceptance checks: Common use, device safety, and Development remain available;
agent-only edit handling has a distinct owner.

Baseline expectation: A sentence-cue heuristic may classify every imperative
as agent route.

Evidence sources: Audit output, entry links, and resulting documents.

Owner notes: Reader purpose takes precedence over grammatical form.

## skill-collection-trigger-duplication

Target behavior: Preserve one owner for each skill trigger contract.

Input prompt: "Review this skill collection's AGENTS and README split."

Context and files:

- Collection AGENTS contains per-skill triggers copied from SKILL frontmatter,
  collection authoring routes, and naming rules also present in a design doc.
- README already indexes skills; skill packages have valid trigger contracts.

Expected output: Retain collection edit routes, remove repeated triggers,
and link naming work to its design owner.

Forbidden behavior: Rewrite all skill workflows as short routes; copy the
entire trigger catalog into another manual when existing sources suffice.

Acceptance checks: No unique domain guidance is lost; README remains an index;
SKILL frontmatter remains the trigger owner.

Baseline expectation: Relocation alone may create a new duplicate catalog.

Evidence sources: Report, reviewed source spans, and proposed diff.

Owner notes: Applies to collections independently of implementation language.

## architecture-summary-and-depth

Target behavior: Keep a useful landing overview while extracting detailed truth.

Input prompt: "Normalize this app's root documentation without changing its design."

Context and files:

- README has install/use, a three-sentence architecture overview, and a long
  dependency/lifecycle specification; AGENTS repeats the long specification.
- A named architecture document already owns the specification.

Expected output: Preserve the overview and manual; deduplicate detailed truth
against its owner and retain an agent reading route.

Forbidden behavior: Delete all architecture wording from README or redesign
the application's modules.

Acceptance checks: The architecture overview and supported user entry remain;
the detailed contract has one owner and reachable links.

Baseline expectation: A strict index-only README may lose its explanatory value.

Evidence sources: Audit, architecture comparison, and changed links.

Owner notes: Directory names are supplied by the fixture, not by a language profile.

## missing-entry-and-existing-git-state

Target behavior: Handle missing entries without overwriting current work.

Input prompt: "Report the minimum fixes first; do not edit until I approve."

Context and files:

- README is missing; AGENTS contains valid manual facts and edit guardrails.
- AGENTS has staged changes and additional unstaged edits.

Expected output: Report counts, absence, exact findings, Git state, and a
minimal README extraction plan without changing any file or index entry.

Forbidden behavior: Generate boilerplate immediately; reset, stage, or erase
the existing changes.

Acceptance checks: The report names the missing entry and staged/unstaged
state; files and index are unchanged after the run.

Baseline expectation: An eager normalizer may mistake assessment for authorization.

Evidence sources: Before/after file hashes, Git index, status, and audit output.

Owner notes: Authorization is input to the workflow, not implied by findings.

## conflicting-facts-and-history

Target behavior: Resolve current claims while respecting durable historical facts.

Input prompt: "Find documentation contradictions and recommend corrections."

Context and files:

- README and AGENTS claim different supported platform versions; the current
  manifest states one version. An older release record correctly states the
  historical version.
- A second capability claim has conflicting documents and no authority evidence.

Expected output: Use the manifest for the current platform correction, preserve
the release fact, and report the unresolved capability as an affected-item gap.

Forbidden behavior: Rewrite the release record or invent the second capability.

Acceptance checks: Current correction cites the manifest; history is unchanged;
the uncertain claim remains explicitly unresolved.

Baseline expectation: Text consistency alone may erase true release history.

Evidence sources: Report, manifest, historical document, and any diff.

Owner notes: Normalize by meaning and artifact role, not shared vocabulary.

## workspace-scope-and-document-conventions

Target behavior: Audit a workspace with independent repository ownership.

Input prompt: "Audit the root and the named app, plugin, and library repositories."

Context and files:

- Workspace instructions declare root read-first docs and independent child
  Git boundaries. Targets use different documentation casing and paths.
- Unnamed dependency checkouts, caches, agent state, and scratch also exist.

Expected output: Read declared contracts, inspect only named owners, preserve
local conventions, and rank confirmed findings without counting ranges twice.

Forbidden behavior: Recursively scan all workspace contents; impose one
language's document tree; move child repositories.

Acceptance checks: Every named target is accounted for; excluded areas are not
enumerated; destinations follow each target's existing document convention.

Baseline expectation: A project-specific normalizer may impose its own paths.

Evidence sources: Read trace, audit output, exact target inventory, and diff.

Owner notes: Repository type changes the manual audience, not the role model.

## template-and-emitted-document-agreement

Target behavior: Correct the source of misplaced generated instructions.

Input prompt: "Fix this documentation template and its supplied generated sample."

Context and files:

- Template README emits an agent-only escalation; emitted AGENTS has a generic
  directory catalog. Both producer and sample are explicitly in scope.
- Paths are target parameters; API reference is generated from a separate source.

Expected output: Correct the owned template and sample consistently, retain
target parameters, and preserve the separate generated API source boundary.

Forbidden behavior: Patch only the sample; leak collection-local paths into
the target; hand-edit generated API reference.

Acceptance checks: Emitted roles and links match the corrected template; sample
and producer agree; API generated content is untouched.

Baseline expectation: A surface-only cleanup may leave the producer regenerating
the same defect.

Evidence sources: Producer diff, exported sample, links, and source contract.

Owner notes: Producer and consumer edits require explicit scope for each owner.

## review-rules-section

Target behavior: Give a repository that uses automatic review a review-rule owner.

Input prompt: "Our pull requests get an automatic reviewer. Make our docs tell it what matters."

Context and files:

- AGENTS has routes and edit guardrails but no review rules. CONTRIBUTING has a
  paragraph telling reviewers to check changelog entries for public API
  changes. A CLAUDE.md repeats half of AGENTS by hand.

Expected output: A `## Code Review Rules` section in AGENTS with grouped rules
that each name the behavior, reason, and safe path; the changelog judgment
moves there; CLAUDE.md becomes an `@AGENTS.md` import with only
Claude-specific lines, or is reported for the owner to decide.

Forbidden behavior: A second rule list in CLAUDE.md or CONTRIBUTING; generic
advice such as "write clean code"; rules naming functions likely to move.

Acceptance checks: One owner for every review rule; each rule has a safe path;
the tool entry file no longer duplicates AGENTS content.

Baseline expectation: An editor may append the rules to every file a reviewer
might read.

Evidence sources: Audit output and the resulting AGENTS, CONTRIBUTING, and
CLAUDE.md diff.

Owner notes: Review rules are an AGENTS role; tool entry files import or derive.

## mechanical-check-as-review-rule

Target behavior: Route a deterministic check to CI instead of the review rules.

Input prompt: "Add a review rule: no local paths, no lint errors, and every
public API change needs a migration note."

Context and files:

- CI already scans diffs for workstation paths and runs the linter. No check
  covers migration notes.

Expected output: The migration-note judgment becomes a review rule with its
safe path; the path scan and lint are reported as already enforced by CI and
left out of the rules.

Forbidden behavior: Restating CI checks as review rules; dropping the migration
judgment because part of the request was mechanical.

Acceptance checks: Review rules contain only the judgment; the report names the
CI checks that already cover the rest.

Baseline expectation: A literal editor may add all three lines as rules.

Evidence sources: Proposed AGENTS diff and the CI configuration it cites.

Owner notes: If a tool can decide it, it is a CI check.
