#!/bin/sh
set -eu
case "$1" in
  inspect)
    printf 'Workspace: %s\n' "$HOME/project"
    cat "$HOME/seed/message.txt"
    cat "$HOME/copied/note.txt"
    cat "$HOME/project/result.txt"
    ;;
  environment)
    printf '%s\n' "$LC_ALL $TERM $NO_COLOR $EXAMPLE"
    ;;
  empty) ;;
  failure) printf 'failed\n' >&2; exit 3 ;;
  stderr) printf 'warning\n' >&2 ;;
  sleep) sleep 30 ;;
  *) exit 2 ;;
esac
