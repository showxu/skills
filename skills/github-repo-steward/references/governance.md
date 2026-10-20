# Governance and publication

## Identity and working copies

Owner commits use the owner's declared identity and registered signing key.
External and bot authors retain their own ownership; an owner gate for locally
prepared commits must not become an identity restriction on external PRs.
Configure only the task clone, never global Git config. The helper accepts
`OWNER_NAME`, `OWNER_EMAIL`, `SIGNING_KEY`, `CONTENT_CHECK`, and `FAST_CHECK`:

```sh
sh scripts/configure-clone.sh <task-clone>
git -C <task-clone> verify-commit HEAD
```

`SIGNING_KEY` is the local private-key path; the helper reads only its adjacent
public key. No key is bundled. The existing signing agent performs signatures.
`CONTENT_CHECK` is a repository-owned commit scan receiving the candidate as
shell argument `$1`; `FAST_CHECK` is the clean candidate's fast validation.
The pre-push hook fails closed if either command is absent. It validates new
owner commits, signatures and trailers without rescanning unrelated published
history. It does not replace CI.

For worktrees, use worktree-scoped identity, signing and hooks. Enabling
`extensions.worktreeConfig` changes shared config, so account for that change
and remove it when the last task worktree retires. Prefer a fresh clone when
another session owns the checkout or unpushable refs exist. Push only the named
task branch; never `--all`, `--mirror` or a bulk tag push.

## Changes and bootstrap

Use the target's commit/PR convention; absent one, use Conventional Commits.
Keep settings declarations in MAINTENANCE with exact expected merge parameters,
branch/tag protections, check contexts and observed support. A settings change
and its declaration belong in the same reviewed change. Never print secret
values; metadata inspection needs names and scope only.

For a new empty repository, confirm the destination and reviewed source before
the initial push. Preserve accepted trees, ordering and external authorship if
signing unpublished history. Apply branch/tag rulesets immediately after the
initial history, then use PRs. This is not authority to replace an existing
published repository or re-sign its history.

Before merge, inspect current required checks and every review finding. Fix or
answer findings with evidence on the PR and resolve threads. A neutral advisory
check alone is insufficient. Merge the reviewed head:

```sh
gh pr merge <number> --squash --match-head-commit <sha> --subject '<PR title>' --body ''
```

Read back the merged SHA and GitHub signature verification. Preserve the PR
head receipt because squash merging does not make the branch tip an ancestor
of the default branch. Local branch cleanup requires matching that tip to the
merged PR or other tree evidence; never discard unproven local work.

## Release identity

Follow the repository/organization versioning policy, including its rules for
0.x. Do not impose a new minor/patch interpretation from another project.
Signed annotated tags bind release identity to one commit under every policy.
Where neither declares a policy, use the [Version policy default](standard.md#settings)
and [VERSIONING template](../templates/VERSIONING.md.tpl) for 0.x version
increments, owner-decided 1.0.0 and compatible evolution with planned majors
after 1.0. Preserve the repository's published tag-name format; new repositories
default to `vX.Y.Z`. Protect the declared release-tag pattern against update and deletion.
An untagged candidate can be
corrected at its intended version. Existing lightweight or unsigned tags are
reported, not moved.

Release evidence must identify the exact accepted source, configuration and
checker. Keep private build paths out of attachments. Verify downloaded bytes,
manifest identity and the documented installation through the ecosystem release
owner. Never replace release assets to make an old claim appear true.
