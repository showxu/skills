# Evidence Filtering

## Include

Include changes when a user could notice them directly or benefit from them:

- new features or capabilities
- UI, navigation, onboarding, settings, or workflow changes
- behavior changes, defaults, or compatibility updates
- bug fixes that affect login, sync, purchases, media, notifications, crashes,
  data loss, performance, accessibility, localization, or core tasks
- visible performance or reliability improvements
- new supported platforms, devices, languages, or integrations

## Exclude

Drop changes that are internal unless the user explains a visible impact:

- refactors, module moves, dependency upgrades, formatting, linting, and tests
- CI, release scripts, build settings, packaging, and infrastructure
- analytics, logging, telemetry, or diagnostics that do not change user privacy
  or behavior
- developer tooling, documentation, generated files, and repo governance
- vague maintenance commits when there is no evidence of user impact

## Ambiguous Evidence

Use touched files to clarify vague commits:

- UI files, localization files, feature modules, assets, and permissions often
  indicate user-facing changes.
- tests, CI files, package manifests, build scripts, and internal utilities
  often indicate internal-only work.

When ambiguity remains, write a `Needs confirmation` note instead of inventing
impact.

## Commit Message Translation

| Source evidence | User-facing note |
| --- | --- |
| `fix(auth): resolve token refresh race condition` | Fixed a login issue that could unexpectedly sign some users out. |
| `feat(search): add voice input` | Added voice input for faster search. |
| `perf(feed): cache image thumbnails` | Improved feed scrolling performance. |
| `refactor(network): extract client` | Drop unless a visible behavior changed. |
| `ci: add nightly build` | Drop. |

## Grouping

Group after filtering, not before. Suggested groups:

- `New`: new capabilities users can try.
- `Improved`: meaningful changes to existing behavior.
- `Fixed`: bugs and reliability fixes.

Use a flat list for small releases or when groups would create empty headings.
