#!/bin/sh
# Configure a clone's owner identity, SSH commit and tag signing, and its
# allowed-signers list in local config, which all of the clone's worktrees share.
#
# Set OWNER_NAME, OWNER_EMAIL, SIGNING_KEY and optionally ALLOWED_SIGNERS, then:
#   configure-signing.sh <repo-dir>
#
# SIGNING_KEY is the private SSH key path; its .pub file must sit next to it.
# The list is ALLOWED_SIGNERS, else the configured gpg.ssh.allowedSignersFile,
# else allowed_signers in the common Git directory. The setting keeps the value
# as given; Git resolves ~/ and relative paths, from the working tree root.
# The owner's line is appended when missing and other lines are kept. A list
# that is a symbolic link or repository content is only read. Every refusal
# precedes the first write.
set -eu

repo=${1:?usage: configure-signing.sh <repo-dir>}
: "${OWNER_NAME:?set OWNER_NAME}"
: "${OWNER_EMAIL:?set OWNER_EMAIL}"
: "${SIGNING_KEY:?set SIGNING_KEY}"
[ -f "$SIGNING_KEY.pub" ] || { echo "missing $SIGNING_KEY.pub" >&2; exit 1; }

common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)
setting=${ALLOWED_SIGNERS:-$(git -C "$repo" config --local --get gpg.ssh.allowedSignersFile || :)}
setting=${setting:-$common/allowed_signers}
case $setting in
/*) list=$setting ;;
"~/"*) list=$HOME/${setting#"~/"} ;;
*) list=$(git -C "$repo" rev-parse --show-toplevel)/$setting ;;
esac

key=$(cut -d' ' -f1,2 "$SIGNING_KEY.pub")
line="$OWNER_EMAIL namespaces=\"git\" $key"

# A line lists principals, optional options, then the key and a comment. It
# authorizes the owner when a principal is the email and the key matches,
# unless its options make the key a certificate authority or omit the git
# namespace.
has_owner_line() {
  [ -f "$list" ] && awk -v email="$OWNER_EMAIL" -v key="$key" '
    { sub(/\r$/, "") }
    /^[[:space:]]*(#|$)/ { next }
    {
      k = 2
      while (k < NF && $k !~ /^(ssh-|ecdsa-|sk-)/) k++
      options = ""
      for (i = 2; i < k; i++) options = options " " $i
      if ($k " " $(k + 1) != key || options ~ /cert-authority/) next
      if (options ~ /namespaces=/ && options !~ /namespaces="([^"]*,)?git[,"]/) next
      n = split($1, principals, ",")
      for (i = 1; i <= n; i++) if (principals[i] == email) found = 1
    }
    END { exit !found }' "$list"
}

refuse() {
  echo "$list $1, or set ALLOWED_SIGNERS to another list:" >&2
  echo "$line" >&2
  exit 1
}

if ! has_owner_line; then
  [ ! -L "$list" ] || refuse "is a symbolic link; add this line to its target"
  dir=$(dirname "$list")
  if [ "$(git -C "$dir" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] &&
    ! git -C "$dir" check-ignore -q -- "$(basename "$list")"; then
    [ -e "$list" ] || refuse "is missing from a working tree; restore it through its review"
    refuse "is repository content; add this line through its review"
  fi
  if [ -s "$list" ] && [ -n "$(tail -c 1 "$list")" ]; then echo >>"$list"; fi
  printf '%s\n' "$line" >>"$list"
fi

git -C "$repo" config --replace-all user.name "$OWNER_NAME"
git -C "$repo" config --replace-all user.email "$OWNER_EMAIL"
git -C "$repo" config --replace-all gpg.format ssh
git -C "$repo" config --replace-all user.signingkey "$SIGNING_KEY"
git -C "$repo" config --replace-all gpg.ssh.allowedSignersFile "$setting"
git -C "$repo" config --replace-all commit.gpgsign true
git -C "$repo" config --replace-all tag.gpgsign true
