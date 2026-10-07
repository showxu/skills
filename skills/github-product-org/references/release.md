# Releases and Distribution

## Versions

- Semantic Versioning 2.0.0. While `0.x`, fixes bump the patch and new
  capabilities or incompatible changes bump the minor; prereleases use
  `-alpha.N`, `-beta.N`, `-rc.N`; `1.0.0` marks a stable public interface.
- Documentation, CI, and cleanup changes alone do not require a release.
- A package collection keeps its shared compatibility contract in the
  organization's `VERSIONING.md`. Each repository links that policy and owns
  package-specific consequences in its versioning document; `MAINTENANCE.md`
  owns maintenance, not a competing version policy.

## Tags and Records

- New tags are signed annotated `vX.Y.Z`; forks tag `X.Y.Z-<org>.N`.
- Published tags, releases, and assets are immutable. A fix ships as a new
  version. Earlier lightweight or unsigned tags stay as they are; report them,
  do not move them.
- The GitHub Release is the formal record. `CHANGELOG.md` keeps
  `## Unreleased` and `## X.Y.Z — YYYY-MM-DD` sections; release notes render
  from it and version-independent templates.
- Editing a published release's notes is allowed but is a remote change;
  back up the original body first.

## Homebrew Tap

- Formulae render from reviewed templates. An update workflow verifies source
  tags, artifact checksums, and acceptance records, then proposes the result as
  a pull request through the Updater App with auto-merge; `brew test-bot`
  jobs are required checks.
- After a release lands in the tap, install it on a real machine, run its
  smoke command, and uninstall.
- Formula and tap behavior: `homebrew`.

## Plugins

- Each plugin declares its minimum host version in its manifest and notifies
  the website after release events (`references/website.md`).
- Plugin catalogs read verified releases only; a plugin never pushes catalog
  data.

## Before a Release

Release readiness of the component itself (builds, smoke tests, notes) belongs
to the release skills below. At organization level, before tagging:

- the settings check reports no differences and the releasing repository's
  required checks are green on the default branch;
- release notes derive from the canonical CHANGELOG section for the candidate
  version, following that repository’s versioning contract;
- downstream automation is healthy: the Updater App can open pull requests in
  the tap and website, and plugins' notifier pins resolve.

The audit checklist is not a release gate; it serves takeover and upkeep.

## Cross-Repository Release Order

In a product family, release in this order. In a package collection each
package releases on its own; follow the order only for a package other
repositories depend on.

1. Release the component that others depend on (app or CLI).
2. Let automation propose tap and website updates; confirm they merged green.
3. Release dependent plugins; confirm their notifications reached the website.
4. Run the acceptance scan.

Swift package and CLI readiness: `swiftpm-github-release`. App Store
releases: the `app-store-*` skills.

## Shared Release Workflows

Keep reusable validation and publication mechanics in the organization’s
`.github`, pinned by full commit. Each repository owns its release configuration:
products, platform/toolchain matrix, traits, checks, documentation and validation
budgets. Exercise a new shared revision in one representative consumer before a
broader pin rollout. SDK selection and Swift toolchain selection are separate
inputs and must agree across `swift`, `xcrun` and `xcodebuild` where used.

Bind release provenance to the immutable tag commit. Scan the exact release
notes and every attachment, recursively inspecting archive members for local
paths, internal folders, attribution and secrets under the owning content
policy. After publication, download the asset, compare its digest and confirm
its manifests name the accepted commit. A filename or successful upload alone
is insufficient.

## Publishing a New Repository

1. Confirm owner, destination, scope, redistribution facts and accepted source.
2. Preserve unpublished history and validation evidence. Prepare the signed
   history and prove tree/order preservation where re-signing is required.
3. Run identity, content and version gates over the intended first publication;
   select checks from the package contract and the owner’s current instructions.
4. Push to the confirmed empty repository, align the default branch and install
   branch/tag rulesets immediately. Inspect live settings after the mutation.
5. Make further changes by PR. Require current default-branch checks, create
   a signed immutable release tag and verify its remote target.
6. Run the owned release workflow, verify canonical notes and published assets,
   and resolve an independent consumer using the documented version range.
7. Deploy documentation, verify URLs and identity, then apply About, topics and
   homepages from the accepted surface record. Keep the repository’s install
   instructions consistent with the published tag.
