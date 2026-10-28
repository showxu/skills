# Governance and publication

## Identity and working copies

Owner commits use the owner's declared identity and registered signing key.
External and bot authors retain their own ownership; an owner gate for locally
prepared commits must not become an identity restriction on external PRs.
By default the owner sets signing up once per machine in global Git config:
identity, the signing key, signing of commits and tags, and a personal
allowed-signers list. A clone that inherits all of it needs no signing setup.
Never change global config; for a clone without that inheritance, configure its
local config. Local config, the default allowed-signers list and hooks belong
to the repository, so every worktree of a clone shares them.

The helpers take `OWNER_NAME`, `OWNER_EMAIL`, `SIGNING_KEY` and an optional
`ALLOWED_SIGNERS`. `scripts/configure-signing.sh` sets identity, SSH signing of
commits and tags, and the allowed-signers list; it suffices for a clone without
inherited signing that needs no owner push gate. `scripts/configure-clone.sh`
also sets them locally and installs that gate from `CONTENT_CHECK` and
`FAST_CHECK`; use it for every task clone that pushes owner commits:

```sh
# Signing only
sh scripts/configure-signing.sh <clone>
# Signing and the owner push gate
sh scripts/configure-clone.sh <task-clone>
```

Verify the first owner commit with `git -C <clone> verify-commit HEAD`.
`SIGNING_KEY` is the local private-key path; the helper reads only its adjacent
public key. No key is bundled. The existing signing agent performs signatures.

The owner's signing keys registered on GitHub are the source of truth for the
owner. GitHub verifies other authors' commits, so a personal list holds only
the owner's keys, retired ones included. A repository commits a list only for
signers no account publishes, such as release automation, and its release
verification adds the owner's keys from the account. An applicable standard may
name another list.

The helpers use `ALLOWED_SIGNERS` when set, otherwise the clone's configured
`gpg.ssh.allowedSignersFile`, otherwise `allowed_signers` in the repository's
common Git directory. Git config keeps the value as given, and Git resolves
`~/` and relative paths, which start at the working tree root. The helpers
append the owner's line when the list lacks it and keep every other line, such
as a release signer's. A list that is a symbolic link or repository content,
tracked or not ignored in a working tree, is only read; add a missing owner
line through its owner. Set `ALLOWED_SIGNERS` when the clone has no configured
list, or when its configured list is gone or is not the one the standard names;
never to bypass the standard's list.

A fresh clone has no local config. It inherits global signing where the machine
has it; otherwise rerun the helper on it, passing the list the standard names
as `ALLOWED_SIGNERS`, or the default applies. A list kept in a repository
returns with it. After reinstalling a machine, restore the global configuration
and regenerate the personal list from the keys registered on GitHub:

```sh
gh api --paginate users/<login>/ssh_signing_keys \
  --jq '.[] | "<email> namespaces=\"git\" \(.key)"' > <personal-list>
```

Keep the private signing key; `ssh-keygen -y -f <key> > <key>.pub` restores
its public key. When rotating the signing key, keep the retired public key
registered on GitHub and regenerate the personal list, so signatures it made
still verify. A committed list keeps retired keys too.

`CONTENT_CHECK` is a repository-owned commit scan receiving the candidate as
shell argument `$1`; `FAST_CHECK` is the clean candidate's fast validation.
The pre-push hook fails closed if either command is absent. It validates new
owner commits, signatures and trailers without rescanning unrelated published
history. It does not replace CI.

Prefer a fresh clone when another session owns the checkout or unpushable refs
exist. Push only the named task branch; never `--all`, `--mirror` or a bulk tag
push.

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

Follow the applicable VERSIONING: the repository's, its organization's or,
where neither is declared, one written from the
[VERSIONING template](../templates/VERSIONING.md.tpl). Do not impose another
project's version interpretation. Signed annotated tags bind release identity
to one commit under every policy. Preserve the repository's published
tag-name format; new repositories default to `vX.Y.Z`. Protect the declared
release-tag pattern against update and deletion. Existing lightweight or
unsigned tags are reported, not moved.

Release evidence must identify the exact accepted source, configuration and
checker in the task record. Releases attach no evidence assets. Verify downloaded
bytes and manifest identity through the ecosystem release owner. Never replace
release assets to make an old claim appear true.
