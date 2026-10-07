#!/bin/sh
# Pre-push gate: every pushed commit and tag carries the clone's configured owner
# identity, a signature from an allowed signer, and no tool attribution trailer.
# Repository-owned content and fast commands match the policy enforced in CI.
# Installed as .git/hooks/pre-push by configure-clone.sh; reads the pre-push stdin.
set -u

name=$(git config user.name)
email=$(git config user.email)
zero=0000000000000000000000000000000000000000
trailer='^(Co-authored-by|Made-with|Generated-by|Generated-with|Assisted-by|Signed-off-by):|Generated with|cursor\.com|anthropic\.com|claude\.ai|openai\.com'
status=0
new_commits=
has_candidate=0

fail() {
  echo "pre-push: $*" >&2
  status=1
}

while read -r local_ref local_sha remote_ref remote_sha; do
  [ "$local_sha" = "$zero" ] && continue

  case $local_ref in
  refs/tags/*)
    if [ "$(git cat-file -t "$local_sha")" != tag ]; then
      fail "$local_ref is not an annotated tag"
    elif ! git verify-tag "$local_sha" >/dev/null 2>&1; then
      fail "$local_ref has no valid signature"
    fi
    target=$(git rev-parse "$local_sha^{commit}") || { fail "invalid tag target"; continue; }
    ;;
  *) target=$local_sha ;;
  esac

  # Commits already on a remote were checked when they were pushed or merged.
  commits=$(git rev-list "$target" --not --remotes) || { fail "cannot inspect $target"; continue; }
  [ -n "$commits" ] || continue
  has_candidate=1
  if [ "$(git rev-parse HEAD)" != "$target" ]; then
    fail "check out candidate $target before validating its new commits"
  fi
  new_commits="$new_commits $commits"
  for c in $commits; do
    meta=$(git log -1 --format='%an|%ae|%cn|%ce|%G?' "$c")
    case $meta in
    "$name|$email|$name|$email|G") ;;
    "$name|$email|$name|$email|"*) fail "$c is not signed by an allowed signer ($meta)" ;;
    *) fail "$c has a foreign identity ($meta)" ;;
    esac
    if git log -1 --format=%B "$c" | grep -Eiq "$trailer"; then
      fail "$c carries a tool attribution trailer"
    fi
  done
done

[ "$status" -eq 0 ] || exit "$status"
[ "$has_candidate" -eq 1 ] || exit 0

content_check=$(git config org.contentCheck || :)
fast_check=$(git config org.fastCheck || :)
[ -n "$content_check" ] || fail "configure org.contentCheck with the repository's commit content scan"
[ -n "$fast_check" ] || fail "configure org.fastCheck with the repository's fast validation command"
[ -z "$(git status --porcelain)" ] || fail "candidate worktree and index must be clean"
[ "$status" -eq 0 ] || exit "$status"

for c in $new_commits; do
  sh -c "$content_check" org-content "$c" || fail "content scan failed for $c"
done
[ "$status" -eq 0 ] || exit "$status"
sh -c "$fast_check" org-fast || fail "repository fast check failed"

exit $status
