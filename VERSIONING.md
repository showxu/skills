# Versioning

## Tags

Versions use SemVer 2.0.0. Release tags are signed and annotated, named
`vX.Y.Z`, with the message `skills X.Y.Z`. A tagged version is never
moved, reused or decreased.

## Choosing the next version

| Change | 0.x | 1.0+ |
| --- | --- | --- |
| Breaking change | Bump MINOR | Bump MAJOR |
| Compatible addition | Bump PATCH | Bump MINOR |
| Fix | Bump PATCH | Bump PATCH |

Reset less significant components to zero when bumping MAJOR or MINOR.
Version numbers never tagged or published to users do not constrain the first
release, which may start at `0.1.0`.

## Version source

The version source is `metadata.version` in the [Claude marketplace manifest](.claude-plugin/marketplace.json).

Files that mirror it:

- [.claude-plugin/plugin.json](.claude-plugin/plugin.json): `version`
- [.codex-plugin/plugin.json](.codex-plugin/plugin.json): `version`

Update the source and its mirrors together in the release PR.

## Changelog

Keep `CHANGELOG.md` with `## Unreleased` first, followed by `## X.Y.Z`
sections newest first. Describe what each version ships. Every breaking change
includes instructions for upgrading.

## Release procedure

1. Choose the next version using the table above.
2. Prepare a release PR that sets the version source and its mirrors, moves
   the Unreleased entries into the new `## X.Y.Z` section, and leaves an empty
   `## Unreleased` section at the top.
3. Run the repository checks and complete the ecosystem release preparation
   below. Resolve review findings before accepting the PR.
4. Squash merge the accepted release PR.
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

Ecosystem builds, packages, stores and consumer installation checks belong to
the [plugin distribution workflow](docs/skill-authoring.md#plugin-distribution).
