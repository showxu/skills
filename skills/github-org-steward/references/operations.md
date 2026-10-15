# Organization operations

## Scope and local preservation

Snapshot local checkout state before organization work:

```sh
python3 scripts/scan_org.py snapshot --root <checkouts> > <ignored-output>/baseline.json
```

Use bounded named paths and metadata; do not crawl agent state, dependency
caches, unrelated archives or another session's scratch work. Every repository
uses a task clone or worktree prepared by `github-repo-steward`; the owner's
index, stashes and unrelated work remain untouched. Push only task-owned named
branches. Build/test from a repository, worktree or Git archive, never a copied
full checkout or `.git` in output/cache directories. Reuse each producer's
ignored output location and retire task outputs at closeout.

Triage current findings as fix, keep, distill to the owning artifact, or
insufficient evidence. Apply already authorized fixes. Destructive choices,
unclear ownership, new legal/visibility decisions or expanded scope need the
owner. Preserve current historical/provenance records and source notices.

Local-only files are report-only unless changing them was authorized. Compare
actual bytes and meaning with the remote revision; do not assume Git status
alone finds every differing file. Route useful unique changes to a reviewed PR,
with exact path ownership. Never `reset`, `clean`, clear stashes or discard a
whole checkout as generic retirement.

## Authorized handoffs

Delegate only when authorized. Give each participant shared rules and its own
task file naming input revisions, owned paths, expected output and validation.
No concurrent writes to the same files. Keep subjective design approval with
its owner; one publisher coordinates accepted source and live operations.
Do not infer authority to message unrelated sessions.

Preparation ends with facts, review findings, accepted source and validation
before first publication. Completion messages point to evidence; the publisher
verifies it rather than accepting intent as delivery. A handoff whose facts do
not identify the current source stays incomplete.

## Cross-repository acceptance

Invoke the repository steward for each member. The organization scanner
aggregates observations supplied by that package; it is not a second repository
standard. It observes latest runs per workflow ID, license digest groups and
historical review items alongside current publication state.

```sh
python3 scripts/scan_org.py remote --org <org> --identity <owner-email> --allowed-signers <file> --work-dir <ignored-empty-directory>
python3 scripts/scan_org.py compare --root <checkouts> --baseline <ignored-output>/baseline.json
```

Supply `--repo-steward <skill-dir>` if it is not a sibling installation. The
output directory must be empty and producer-owned; observations remove their
fresh clones and leave the directory reusable. Do not accept unavailable APIs,
pending checks or explained legacy tags as implicit conformance. Keep every
REVIEW disposition in private evidence. A timeout while observing a live run is
not cancellation; inspect the same run before any retry.

Acceptance also needs the shared settings check, member reports, actual App
scope/reviewer evidence, current profile/catalog/pins, website delivery and
relevant distribution checks. Compare local state with the initial snapshot.
Status/index/stash/worktree changes fail preservation; deliberate ref changes
remain review items with evidence.

## Retirement

Fix recurring failures in their actual check/template/skill owner. Remove task
worktrees without force after reconciling their unique work; prove squash-merged
branches from PR head receipts rather than ancestry. Remove only task-created
scratch clones and caches. Backups or owner state require their own authority.
Report every retained output with size and reason.
