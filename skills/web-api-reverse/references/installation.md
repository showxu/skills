# Local Installation

## Supported Install

Run the skill-owned installer from the `web-api-reverse` directory:

```bash
scripts/install-local
web-api-reverse doctor --json
```

The default install builds the release executable, installs the pinned private
Playwright runtime, and publishes the command under `~/.local/bin`. Override
the command directory with either `--prefix DIRECTORY` or
`WEB_API_REVERSE_INSTALL_PREFIX`. The explicit flag takes precedence.

Use `--skip-playwright-install` only when the pinned runtime is already
installed or when testing read-only CLI installation. `--force` permits
replacement of an existing command link that the installer does not own.
`--bin-path` accepts a prebuilt SwiftPM binary directory and is intended for
installer tests and controlled packaging workflows.

## Release Layout

For the default prefix, the installer owns:

```text
~/.local/bin/web-api-reverse
~/.local/bin/.web-api-reverse-current
~/.local/bin/.web-api-reverse-releases/<release-id>/
```

Each release is immutable after publication and contains the executable, every
SwiftPM `.bundle` resource directory, and a content manifest. The public
command is a relative symlink through `.web-api-reverse-current`, so moving the
entire prefix does not embed its previous absolute path.

Installation stages and hashes a complete release in a sibling transaction
directory, moves that directory into the release store, atomically replaces
the `current` symlink, and atomically replaces the public command symlink. The
two replacements form one activation transaction: any failure after the first
replacement restores both the previous `current` pointer and previous public
command. A staging or validation failure leaves both unchanged.

The installer holds `<prefix>/.lifewear-install.lock` from preflight through
activation, rollback, and release collection. LifeWear, Taobao, JD, and the
ecosystem orchestrator share this per-prefix lock, so independently owned
installers cannot publish or prune each other's release graph concurrently.
The lock records its owner process and can recover after process termination;
symbolic-link and non-regular lock substitutions are rejected.

## Release Retention

After both activation pointers have switched successfully, the installer
garbage-collects expired immutable releases. The default retention is three
total releases:

- the release referenced by `.web-api-reverse-current`;
- the two newest non-active releases for rollback.

Set a different bounded total with either:

```bash
scripts/install-local --retain-releases 5
WEB_API_REVERSE_RELEASE_RETENTION=5 scripts/install-local
```

The explicit flag takes precedence over the environment. Accepted values are
`2...20`; at least one rollback release is always preserved. Collection
resolves the active target again after activation and never deletes that
directory, including when `current` intentionally points to an older release.
Cleanup failure is warning-only after both activation pointers are healthy; it
cannot turn a successful activation into a reported failure.

Rollback is an atomic pointer operation performed by an operator: point a new
temporary symlink at one retained release and rename it over
`.web-api-reverse-current`. Do not modify files inside a retained release.
Running `scripts/install-local` again returns to a newly built release and
reapplies the configured retention bound.

## Resource Safety

A top-level `.bundle` symbolic link or any symbolic link nested inside a
resource bundle is rejected. Validation happens both on the build output and
on the staged copy before publication. This prevents a release from depending
on mutable files outside its immutable directory and keeps the release hash
self-contained.

The installer accepts ordinary files and directories inside a resource bundle.
Replace linked resources with real copied files before installation.

## Playwright Ownership

The CLI release store and Playwright runtime have separate ownership and
lifecycle:

```text
CLI releases: <prefix>/.web-api-reverse-releases/
Playwright:    ~/Library/Application Support/web-api-reverse/playwright/
```

`WEB_API_REVERSE_PLAYWRIGHT_ROOT` may select another private Playwright root.
`install-local` delegates setup to `scripts/install-playwright`; release
retention never scans or removes that root. `--skip-playwright-install` skips
the delegation but does not change ownership or move Playwright into a CLI
release.

Removing old CLI releases therefore cannot invalidate a separately installed
browser runtime. Conversely, deleting the Playwright root does not change the
active CLI pointer; `web-api-reverse doctor --json` reports the missing browser
dependency.
