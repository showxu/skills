# Clean-room reimplementation

Use this path when the accepted adoption decision is to rebuild independently,
instead of forking, adapting or retaining the donor implementation. Select it
before donor access and establish the reader boundary in the adoption packet.

## Roles and allowed inputs

The implementer never reads the donor's sources, tests, documentation or Git
history, including a renamed local copy, extracted snippets or donor-derived
summaries. An already exposed implementer is not made unexposed by deleting
files, clearing context or starting a new branch. Change the implementer or the
adoption path with the owner. Independent work needs an unexposed context/person.

The owner approves allowed inputs: independently stated behavior requirements,
platform/protocol standards, official platform APIs and specifically authorized
independent local code. Donor documentation is still prohibited even when public.
A packet derived from donor internals is not an allowed independent specification.
Record consulted inputs in a development log as work proceeds: source identity,
revision/digest where available, accessed scope, purpose and reader. Record new
inputs before use and surface accidental exposure immediately. Stop clean-room
implementation pending a new ownership/path decision if the boundary is crossed.

The separate auditor can inspect both sides in a restricted workspace. Give the
implementer only a sanitized decision, candidate-owned paths and independently
expressed requirements; raw overlap reports or donor excerpts stay with the
auditor. Do not send donor code back as a proposed fix. Delegating to another
agent requires authorization and a fresh, unexposed implementer context; a second
run by the same implementer is not an independent audit.

## Mandatory gate before first public push

Preparation can proceed locally. Before the first public branch/tag push or
public PR publication, someone other than the implementer must:

1. Review the development log and implementation boundary, not only similarity
   scores. Inventory every donor and renamed local copy, including their Git
   histories and any uncommitted local content. Confirm authorized source access.
2. Obtain complete donor history with all intended branches/tags. The tool
   scans all locally reachable refs; it cannot prove an unseen remote ref or
   unreachable object does not exist. Record retrieval/ref coverage. Shallow,
   missing-object, substituted-history or unaccounted source inputs block the gate.
3. Run the bundled overlap tool against the exact committed candidate and all
   donor repositories/local copies, using explicit donor names, former names,
   package identities and other relevant literal terms. Review every file,
   including matching notices, configuration and binaries.
4. Investigate shared commits and identical blobs, name hits in file paths and
   contents, author/committer/message metadata, normalized-line overlap at the
   declared length thresholds, and token n-gram overlap. Use per-file counts and
   source locations, not just a project-wide percentage. Distinguish supported
   boilerplate or required notices from unexplained implementation similarity.
5. Record an accept/block decision with auditor identity and independent role,
   candidate commit/tree, tool digest, parameters, donor ref inventory, local-copy
   digests, per-file dispositions, limitations and source/license conclusions.
   The publisher checks that this receipt names the commit being pushed. Any
   candidate commit/history or audit-input change needs renewed independent
   acceptance; a prior green run or changed filename cannot carry the gate.

Tool exit 0 means evidence was produced, never that publication is approved.
There is no universal overlap percentage that proves independent authorship or
redistribution rights. Missing review, unknown coverage and unexplained overlap
keep the public push blocked. Never strip license attribution from a copy that
remains. A rebuild decision does not relicense retained code, tests or notices.

## Bundled audit tool

Python 3 and Git are required; no donor code, build or checkout is executed.
An independent auditor runs this from their restricted workspace:

```sh
python3 <skill>/scripts/overlap_audit.py \
  --candidate <candidate-repo> --ref <accepted-commit> \
  --reference <donor-repo> --reference <another-donor> \
  --tree <renamed-local-copy> --term <donor-name> --term <former-name> \
  --output <ignored-audit-output>/overlap.json
```

The candidate scope is that commit's full ancestry and tree. Donor scope is
all reachable refs and all historical tree/blob versions, including deleted
and renamed paths. A Git local-copy root contributes both full history and its
current tracked/non-ignored untracked contents. A plain directory contributes
its files, without following symlinks. Pass the owning Git root for a tracked
subdirectory. Required submodules need their own separately audited inputs.

Defaults are diagnostic parameters, not acceptance thresholds:

| Option | Default and meaning |
| --- | --- |
| `--min-line-length` (repeatable) | 20 and 40 normalized characters; count occurrences after whitespace normalization and comment/import/brace-only exclusion |
| `--ngram-size` (repeatable) | 8 and 12 lexical tokens; compare distinct sequences for every candidate text file against the union of donor versions/copies |
| `--syntax` | `auto`; recognize C-style, hash and markup comments by file type; explicit `c`, `hash`, `markup`, `none` overrides the profile |
| `--max-examples` | 5 candidate lines per file/threshold; counts and file breakdowns are complete, and omitted example counts are explicit |
| `--exclude` (repeatable) | Local-copy globs supplied from its producer/ignore policy; no hardcoded build paths and no donor-history exclusions |

The JSON records tool/input identities, full ref inventory, shared commits,
exact content digests (including binary files), file/content/commit-metadata term
hits, all per-file line/token metrics and generic identifier intersections.
Zero denominators are null, not a claim of zero overlap. All files remain in the
breakdown. UTF-8 lexical parsing is heuristic: it preserves strings, strips
recognized comments (including nested block comments), and excludes recognized
imports and brace/punctuation-only lines. Unsupported syntax, raw/interpolated
strings and generated/minified content require manual inspection. Non-UTF8 and
binary contents retain exact-blob/name checks and are explicitly outside lexical
metrics. Lexical similarity does not establish semantic equivalence.

Outputs can contain donor material and private paths. Keep them in the auditor's
producer-owned ignored location, outside public READMEs and implementation input.
Exit 2 means incomplete/invalid input; never treat a stale report as current.
The tool does not fetch, mutate refs, strip notices, approve or push. Prepare
complete source access outside it, under workspace governance.

Git owns the mechanics of [NUL-safe tree enumeration](https://git-scm.com/docs/git-ls-tree),
[batch object reads](https://git-scm.com/docs/git-cat-file) and
[revision/shallow checks](https://git-scm.com/docs/git-rev-parse). Missing input
objects or unsupported repository state are errors, not empty audit evidence.
