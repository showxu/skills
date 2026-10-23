# Versioning

## Tags

Versions use SemVer 2.0.0. Release tags are signed and annotated, named
`vX.Y.Z`, with the message `skills X.Y.Z`. A tagged version is never
moved, reused or decreased.

## When to release

Where a delivery workflow governs the project, it decides when to release;
otherwise:

Release once a change is complete: everything it needs, including
documentation, is merged and verified. A change that spans several pull
requests or repositories releases once, when all of it has landed, or at
milestones its owner names before the work starts. Its intermediate steps,
review fixes, documentation fixes and pin updates do not release on their own.

## Choosing the next version

### 0.x (initial development)

Anything may change at any time, without deprecation windows or a release
cadence. Breaking changes (removing or incompatibly changing a documented
interface) bump MINOR; everything else bumps PATCH.

Minor-bounded dependency ranges such as `"0.1.1"..<"0.2.0"` and caret semantics
treat `0.MINOR` as the boundary, so automatic updates never pull a breaking
change.

### 1.0.0

Release `1.0.0` when the owner decides the interface is stable and
compatibility is promised.

### 1.0 and later

Change an interface by adding the new form compatibly, keeping the old form
working and deprecating it. Remove the old form only in a planned major.

Breaking changes appear only in planned majors, on a roughly yearly cadence
like platform releases. A major may also mark a significant feature release.
Never cut a major because of a single change.

New features, including value or output changes consumers absorb without
changing their usage (such as regenerating outputs), bump MINOR. Fixes bump
PATCH.

Reset less significant components to zero when bumping MAJOR or MINOR.
Version numbers never tagged or published to users do not constrain the first
release, which may start at `0.1.0`.

## Version source

The version source is the [`VERSION`](VERSION) file.

Files that mirror it:

- [plugin.json](plugin.json): `version`
- [.claude-plugin/plugin.json](.claude-plugin/plugin.json): `version`
- [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json): `metadata.version`

Update the source and its mirrors together in the release change.

## Changelog

Keep `CHANGELOG.md` with `## Unreleased` first, followed by `## X.Y.Z`
sections newest first. Describe what each version ships. Every breaking change
includes instructions for upgrading.
From `1.0` onward, record deprecations in the changelog and list a planned
major's removals beforehand.

## Release procedure

1. Choose the next version using the rules above.
2. In the change's final PR, set the version source and its mirrors, move the
   Unreleased entries into the new `## X.Y.Z` section, and leave an empty
   `## Unreleased` section at the top.
3. Run the repository checks and complete the ecosystem release preparation
   below. Resolve review findings before accepting the PR.
4. Squash merge the accepted PR.
5. Create the signed annotated tag with the name and message above on the
   accepted merge commit.
6. Publish the tag and verify that the remote tag's peeled commit equals the
   accepted merge commit.

For each release tag, verify that the version source at its commit matches the
tag's version and that `CHANGELOG.md` at that commit has the matching section.

Repository checks:

```sh
python3 -B scripts/check_repository.py
claude plugin validate .
```

Ecosystem builds, packages and stores belong to the
[release reference](docs/reference/release.md).
