#!/bin/sh
# Configure a fresh clone for owner-only, signed work and install the pre-push gate.
#
# Set the configure-signing.sh inputs, CONTENT_CHECK and FAST_CHECK, then:
#   configure-clone.sh <repo-dir>
#
# configure-signing.sh sets identity, signing and the allowed-signers list.
# CONTENT_CHECK receives a commit as $1; FAST_CHECK validates the clean checkout.
set -eu

repo=${1:?usage: configure-clone.sh <repo-dir>}
: "${CONTENT_CHECK:?set CONTENT_CHECK to the repository content scan command}"
: "${FAST_CHECK:?set FAST_CHECK to the repository fast check command}"
here=$(cd "$(dirname "$0")" && pwd)

sh "$here/configure-signing.sh" "$repo"
git -C "$repo" config steward.contentCheck "$CONTENT_CHECK"
git -C "$repo" config steward.fastCheck "$FAST_CHECK"
git -C "$repo" config credential.helper '!gh auth git-credential'

hooks=$(git -C "$repo" rev-parse --git-path hooks)
case $hooks in /*) ;; *) hooks="$repo/$hooks" ;; esac
mkdir -p "$hooks"
cp "$here/prepush-check.sh" "$hooks/pre-push"
chmod +x "$hooks/pre-push"
