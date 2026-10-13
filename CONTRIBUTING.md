# Contributing

External contributions are welcome. Read [AGENTS.md](AGENTS.md) and the owning
skill before editing; keep skill-specific behavior and fixtures together.

Commit subjects and pull request titles follow Conventional Commits:
`type(scope)!: subject`, using build, chore, ci, docs, feat, fix, perf,
refactor, revert, style or test. Pull requests check the title and added lines;
external and automated authors are accepted. Do not add attribution trailers,
credentials or private execution paths.

Run `python3 -B scripts/check_repository.py`, the changed skill's validation,
and `git diff --check`. Include the checks and their results in the pull request.

Maintainer commits are signed. Follow the
[shared signing instructions](https://github.com/swift-library/.github/blob/master/MAINTENANCE.md#signing).
Changes merge into `master` only after required checks pass and review threads
are resolved. Squash using the PR title, an empty body and an exact head match.
Published history and version tags remain immutable; rotate exposed credentials.
The [shared maintenance standard](https://github.com/swift-library/.github/blob/master/MAINTENANCE.md)
owns these contribution and merge conventions.
