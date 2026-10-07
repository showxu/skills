#!/usr/bin/env bash
set -euo pipefail

since_ref="${1:-}"
until_ref="${2:-HEAD}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git worktree." >&2
  exit 2
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "No commits found in this git worktree." >&2
  exit 2
fi

if [[ -z "${since_ref}" ]]; then
  if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    since_ref="$(git describe --tags --abbrev=0)"
  fi
fi

if [[ -n "${since_ref}" ]] && ! git rev-parse --verify "${since_ref}^{commit}" >/dev/null 2>&1; then
  echo "Invalid since ref: ${since_ref}" >&2
  exit 2
fi

if ! git rev-parse --verify "${until_ref}^{commit}" >/dev/null 2>&1; then
  echo "Invalid until ref: ${until_ref}" >&2
  exit 2
fi

if [[ -n "${since_ref}" ]]; then
  range="${since_ref}..${until_ref}"
  range_label="${since_ref}..${until_ref}"
else
  range="${until_ref}"
  range_label="start..${until_ref} (no tags found)"
fi

repo_root="$(git rev-parse --show-toplevel)"

printf "Repo: %s\n" "${repo_root}"
printf "Range: %s\n" "${range_label}"

printf "\n== Commits ==\n"
git log --reverse --date=short --pretty=format:'%h|%ad|%an|%s' "${range}"

printf "\n\n== Files Touched ==\n"
git log --reverse --name-only --pretty=format:'--- %h %s' "${range}" | sed '/^$/d'

printf "\n\n== Summary ==\n"
git diff --stat "${range}" || true
