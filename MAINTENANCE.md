# Repository Maintenance

This repository publishes authored skills and their permitted resources.
The root license governs original material; bundled third-party notices retain
their own scope. Private design downloads, local configuration, plans and
validation outputs are excluded from the published tree.

## Validation

Run `python3 -B scripts/check_repository.py` from the clean candidate checkout.
It checks publication content, both marketplace formats, shared versions, and
skill package structure. It does not establish behavioral readiness: use each
changed skill's fixtures and declared validation route.

CI also exercises the organization governance scripts, documentation-rule
derivation and repository policy tests. Temporary outputs belong in `.build/`.

## GitHub Settings

- The default branch is `main`. Changes after the initial signed publication
  use pull requests and squash merges. Merge commits and rebase merges are
  disabled, and merged branches are deleted.
- The active `default branch` ruleset has no bypass actors. It prevents branch
  deletion and force pushes, requires signed commits, resolved review threads,
  pull requests and successful `policy` and `result` checks from GitHub Actions.
  A single owner does not require a second approving review.
- The active `release tags` ruleset prevents updates and deletion of `v*` tags,
  with no bypass actors. New release tags are signed and annotated.
- Actions tokens default to read access and cannot approve pull requests.
  Workflows declare their permissions and pin actions to full commits.
  Dependabot checks action updates weekly.

Automatic advisory review remains deferred by the owner. Review rules are in
`AGENTS.md`; this declaration does not claim that Codex automatic review is
enabled. Required policy and validation checks still gate every merge.

## Publication

Keep the Codex plugin version equal to Claude marketplace `metadata.version`.
Unversioned Claude entries use commit-based installation versions. The Codex
marketplace points to the repository's `main` branch.

After publication, verify the README's marketplace and plugin installation
commands against the public revision in isolated host configuration directories.
Compare the installed skill files with the published tree and preserve the real
host configuration. A local manifest check does not prove remote installation.
