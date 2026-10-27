#!/bin/sh
# Configure a clone's owner identity, SSH commit and tag signing, and its
# allowed-signers list.
#
# Set OWNER_NAME, OWNER_EMAIL, SIGNING_KEY and optionally ALLOWED_SIGNERS, then:
#   configure-signing.sh <repo-dir>
#
# SIGNING_KEY is the private SSH key path; its .pub file must sit next to it.
# The list is ALLOWED_SIGNERS, else the clone's gpg.ssh.allowedSignersFile, else
# allowed_signers in its Git directory. A relative path is relative to the
# working tree root, as Git resolves it. The owner's line is appended when
# missing and other lines are kept. A list that is repository content, tracked
# or not ignored in a working tree, is never written. All checks precede writes.
set -eu

repo=${1:?usage: configure-signing.sh <repo-dir>}
: "${OWNER_NAME:?set OWNER_NAME}"
: "${OWNER_EMAIL:?set OWNER_EMAIL}"
: "${SIGNING_KEY:?set SIGNING_KEY}"
[ -f "$SIGNING_KEY.pub" ] || { echo "missing $SIGNING_KEY.pub" >&2; exit 1; }

gitdir=$(git -C "$repo" rev-parse --absolute-git-dir)
signers=${ALLOWED_SIGNERS:-$(git -C "$repo" config --local --get gpg.ssh.allowedSignersFile || :)}
signers=${signers:-$gitdir/allowed_signers}
case $signers in
/*) list=$signers ;;
"~/"*) list=$HOME/${signers#"~/"} ;;
*) list=$(git -C "$repo" rev-parse --show-toplevel)/$signers ;;
esac

key=$(cut -d' ' -f1,2 "$SIGNING_KEY.pub")
line="$OWNER_EMAIL namespaces=\"git\" $key"
# A line lists principals first and may put options before the key.
if ! { [ -f "$list" ] && awk -v email="$OWNER_EMAIL" -v key="$key" '
  /^[[:space:]]*(#|$)/ { next }
  {
    n = split($1, principals, ",")
    for (i = 1; i <= n; i++)
      if (principals[i] == email)
        for (j = 2; j < NF; j++)
          if ($j " " $(j + 1) == key) found = 1
  }
  END { exit !found }' "$list"; }; then
  dir=$(dirname "$list")
  if [ "$(git -C "$dir" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] &&
    ! git -C "$dir" check-ignore -q -- "$(basename "$list")"; then
    echo "$list is repository content; add this line through its review or set ALLOWED_SIGNERS:" >&2
    echo "$line" >&2
    exit 1
  fi
  if [ -s "$list" ] && [ -n "$(tail -c 1 "$list")" ]; then echo >>"$list"; fi
  printf '%s\n' "$line" >>"$list"
fi

git -C "$repo" config user.name "$OWNER_NAME"
git -C "$repo" config user.email "$OWNER_EMAIL"
git -C "$repo" config gpg.format ssh
git -C "$repo" config user.signingkey "$SIGNING_KEY"
git -C "$repo" config gpg.ssh.allowedSignersFile "$signers"
git -C "$repo" config commit.gpgsign true
git -C "$repo" config tag.gpgsign true
