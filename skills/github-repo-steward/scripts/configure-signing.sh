#!/bin/sh
# Configure a clone's owner identity, SSH commit and tag signing, and its
# allowed-signers list in local config, which all of the clone's worktrees share.
# A setting the clone already inherits with the same value is not written.
#
# Set OWNER_NAME, OWNER_EMAIL, SIGNING_KEY and optionally ALLOWED_SIGNERS, then:
#   configure-signing.sh <repo-dir>
#
# SIGNING_KEY is the private SSH key path; its .pub file must sit next to it.
# The list is ALLOWED_SIGNERS, else the local gpg.ssh.allowedSignersFile, else
# the inherited one when it already authorizes the owner, else allowed_signers
# in the common Git directory. The setting keeps the value as given; Git
# resolves ~/ and relative paths, from the working tree root. The owner's line
# is appended when missing and other lines are kept. A list that is a symbolic
# link or repository content is only read. Every refusal precedes the first
# write.
set -eu

repo=${1:?usage: configure-signing.sh <repo-dir>}
: "${OWNER_NAME:?set OWNER_NAME}"
: "${OWNER_EMAIL:?set OWNER_EMAIL}"
: "${SIGNING_KEY:?set SIGNING_KEY}"
[ -f "$SIGNING_KEY.pub" ] || { echo "missing $SIGNING_KEY.pub" >&2; exit 1; }

key=$(cut -d' ' -f1,2 "$SIGNING_KEY.pub")
line="$OWNER_EMAIL namespaces=\"git\" $key"

path_of() {
  case $1 in
  /*) printf '%s\n' "$1" ;;
  "~/"*) printf '%s\n' "$HOME/${1#"~/"}" ;;
  *) printf '%s\n' "$(git -C "$repo" rev-parse --show-toplevel)/$1" ;;
  esac
}

# A line lists principals, optional options, then the key and a comment. It
# authorizes the owner when a principal is the email and the key matches,
# unless its options make the key a certificate authority or its namespaces
# pattern list does not admit git. As in OpenSSH, option names ignore case and
# patterns use *, ? and ! negation.
has_owner_line() {
  [ -f "$1" ] && awk -v email="$OWNER_EMAIL" -v key="$key" '
    function glob(p, s,    c) {
      if (p == "") return s == ""
      c = substr(p, 1, 1)
      if (c == "*") return glob(substr(p, 2), s) || (s != "" && glob(p, substr(s, 2)))
      return s != "" && (c == "?" || c == substr(s, 1, 1)) && glob(substr(p, 2), substr(s, 2))
    }
    function admits_git(options,    lower, quoted, patterns, n, i, p, negated, admitted) {
      lower = tolower(options)
      if (lower ~ /(^|[ ,])cert-authority([ ,]|$)/) return 0
      if (!match(lower, /(^|[ ,])namespaces="[^"]*"/)) return 1
      split(substr(options, RSTART, RLENGTH), quoted, "\"")
      n = split(quoted[2], patterns, ",")
      admitted = 0
      for (i = 1; i <= n; i++) {
        p = patterns[i]
        negated = sub(/^!/, "", p)
        if (glob(p, "git")) { if (negated) return 0; admitted = 1 }
      }
      return admitted
    }
    { sub(/\r$/, "") }
    /^[[:space:]]*(#|$)/ { next }
    {
      k = 2
      while (k < NF && $k !~ /^(ssh-|ecdsa-|sk-)/) k++
      options = ""
      for (i = 2; i < k; i++) options = options " " $i
      if ($k " " $(k + 1) != key || !admits_git(options)) next
      n = split($1, principals, ",")
      for (i = 1; i <= n; i++) if (principals[i] == email) found = 1
    }
    END { exit !found }' "$1"
}

common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)
setting=${ALLOWED_SIGNERS:-$(git -C "$repo" config --local --get gpg.ssh.allowedSignersFile || :)}
if [ -z "$setting" ]; then
  inherited=$(git -C "$repo" config --get gpg.ssh.allowedSignersFile || :)
  if [ -n "$inherited" ] && has_owner_line "$(path_of "$inherited")"; then
    setting=$inherited
  fi
fi
setting=${setting:-$common/allowed_signers}
list=$(path_of "$setting")

refuse() {
  echo "$list $1; name a list outside working trees in ALLOWED_SIGNERS for:" >&2
  echo "$line" >&2
  exit 1
}

if ! has_owner_line "$list"; then
  [ ! -L "$list" ] || refuse "is a symbolic link, which is not written through"
  dir=$(dirname "$list")
  if [ "$(git -C "$dir" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] &&
    ! git -C "$dir" check-ignore -q -- "$(basename "$list")"; then
    [ -e "$list" ] || refuse "is missing from a working tree"
    refuse "is repository content, which takes no owner key"
  fi
  if [ -s "$list" ] && [ -n "$(tail -c 1 "$list")" ]; then echo >>"$list"; fi
  printf '%s\n' "$line" >>"$list"
fi

# A local value is replaced; an inherited one is overridden only when it differs.
set_config() {
  if git -C "$repo" config --local --get-all "$1" >/dev/null ||
    [ "$(git -C "$repo" config --get "$1" || :)" != "$2" ]; then
    git -C "$repo" config --replace-all "$1" "$2"
  fi
}

set_config user.name "$OWNER_NAME"
set_config user.email "$OWNER_EMAIL"
set_config gpg.format ssh
set_config user.signingkey "$SIGNING_KEY"
set_config gpg.ssh.allowedSignersFile "$setting"
set_config commit.gpgsign true
set_config tag.gpgsign true
