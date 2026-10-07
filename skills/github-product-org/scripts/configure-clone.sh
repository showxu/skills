#!/bin/sh
# Configure a fresh clone for owner-only, signed work and install the pre-push gate.
#
# Set OWNER_NAME, OWNER_EMAIL, SIGNING_KEY, CONTENT_CHECK and FAST_CHECK, then:
#   configure-clone.sh <repo-dir>
#
# SIGNING_KEY is the private SSH key path; its .pub file must sit next to it.
# CONTENT_CHECK receives a commit as $1; FAST_CHECK validates the clean checkout.
set -eu

repo=${1:?usage: configure-clone.sh <repo-dir>}
: "${OWNER_NAME:?set OWNER_NAME}"
: "${OWNER_EMAIL:?set OWNER_EMAIL}"
: "${SIGNING_KEY:?set SIGNING_KEY}"
: "${CONTENT_CHECK:?set CONTENT_CHECK to the repository content scan command}"
: "${FAST_CHECK:?set FAST_CHECK to the repository fast check command}"
[ -f "$SIGNING_KEY.pub" ] || { echo "missing $SIGNING_KEY.pub" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)

gitdir=$(git -C "$repo" rev-parse --absolute-git-dir)
printf '%s namespaces="git" %s\n' "$OWNER_EMAIL" "$(cut -d' ' -f1,2 "$SIGNING_KEY.pub")" >"$gitdir/allowed_signers"

git -C "$repo" config user.name "$OWNER_NAME"
git -C "$repo" config user.email "$OWNER_EMAIL"
git -C "$repo" config gpg.format ssh
git -C "$repo" config user.signingkey "$SIGNING_KEY"
git -C "$repo" config gpg.ssh.allowedSignersFile "$gitdir/allowed_signers"
git -C "$repo" config commit.gpgsign true
git -C "$repo" config tag.gpgsign true
git -C "$repo" config org.contentCheck "$CONTENT_CHECK"
git -C "$repo" config org.fastCheck "$FAST_CHECK"
git -C "$repo" config credential.helper '!gh auth git-credential'

hooks=$(git -C "$repo" rev-parse --git-path hooks)
case $hooks in /*) ;; *) hooks="$repo/$hooks" ;; esac
mkdir -p "$hooks"
cp "$here/prepush-check.sh" "$hooks/pre-push"
chmod +x "$hooks/pre-push"
