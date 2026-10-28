# Governance and publication

## Identity and working copies

Owner commits use the owner's declared identity and registered signing key.
External and bot authors retain their own ownership; an owner gate for locally
prepared commits must not become an identity restriction on external PRs.

The owner's signing keys registered on GitHub are the source of truth for the
owner, and GitHub verifies other authors' commits. By default the owner
configures each machine once in global Git config: identity, the signing key,
signing of commits and tags, and a personal allowed-signers list, the file that
global `gpg.ssh.allowedSignersFile` names, holding only the owner's keys,
retired ones included. Clones inherit it. The owner maintains global config and
the personal list; never change them. Report a machine without them to the
owner and configure the clone locally.

A committed allowed-signers list holds only signers no account publishes, such
as release automation. A repository keeps it under `.github/`, or uses the
single list its organization keeps in the organization's `.github` repository.
Release verification adds the owner's keys from the account. Never add the
owner's key to a committed list.

The helpers take `OWNER_NAME`, `OWNER_EMAIL`, `SIGNING_KEY` and an optional
`ALLOWED_SIGNERS`, and write to the clone's local config only settings it does
not already inherit with the same value. Local config, the default list and
hooks live in the clone's common Git directory, so every worktree of a clone
shares them. `scripts/configure-signing.sh` sets identity, SSH signing of
commits and tags, and the allowed-signers list. `scripts/configure-clone.sh`
does the same and installs the owner push gate from `CONTENT_CHECK` and
`FAST_CHECK`. Every task clone that pushes owner commits runs it, whether or
not it inherits signing:

```sh
# A clone without inherited signing that pushes no owner commits
sh scripts/configure-signing.sh <clone>
# Every task clone that pushes owner commits
sh scripts/configure-clone.sh <task-clone>
```

Verify the first owner commit with `git -C <clone> verify-commit HEAD`.
`SIGNING_KEY` is the local private-key path; the helper reads only its adjacent
public key. No key is bundled. The existing signing agent performs signatures.

The helpers use `ALLOWED_SIGNERS` when set, otherwise the clone's local
`gpg.ssh.allowedSignersFile`, otherwise the inherited list when it already
authorizes the owner's key, otherwise `allowed_signers` in the common Git
directory. Git config keeps the value as given, and Git resolves `~/` and
relative paths, which start at the working tree root. The helpers append the
owner's line when the selected list lacks it and keep every other line. They
never write an inherited list. A symbolic link or repository content, tracked
or not ignored in a working tree, is only read; when it lacks the owner's line,
the helpers stop before any write. Set `ALLOWED_SIGNERS` to a list outside
working trees when the clone's local list is gone or committed, or when an
applicable standard names another list.

A fresh clone has no local signing settings and inherits global signing where
the machine has it; otherwise run the helper on it. A committed list returns
with the clone. When the owner reinstalls a machine or rotates the signing
key, the owner keeps every retired key registered on GitHub and regenerates the
personal list from the account, replacing it only after a complete fetch:

```sh
gh api --paginate users/<login>/ssh_signing_keys \
  --jq '.[] | "<email> namespaces=\"git\" \(.key)"' > <personal-list>.new &&
  test -s <personal-list>.new && mv <personal-list>.new <personal-list>
```

After a rotation, rerun the helper with the new `SIGNING_KEY` on clones whose
local config sets the signing key. Keep the private signing key;
`ssh-keygen -y -f <key> > <key>.pub` restores its public key. A committed list
keeps its signers' retired keys.

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
