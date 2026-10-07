#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage: check_screenshots.sh [--target WIDTHxHEIGHT] [--allow-alpha] FILE_OR_DIR...

Inspects PNG/JPEG App Store screenshot candidates with macOS sips.
Use one or more --target values to require exact dimensions.
USAGE
}

targets=()
allow_alpha=0
paths=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      if [ "$#" -lt 2 ]; then
        echo "error: --target requires WIDTHxHEIGHT" >&2
        exit 2
      fi
      targets+=("$2")
      shift 2
      ;;
    --allow-alpha)
      allow_alpha=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        paths+=("$1")
        shift
      done
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      paths+=("$1")
      shift
      ;;
  esac
done

if ! command -v sips >/dev/null 2>&1; then
  echo "error: sips is required on macOS" >&2
  exit 2
fi

if [ "${#paths[@]}" -eq 0 ]; then
  usage >&2
  exit 2
fi

files=()
for path in "${paths[@]}"; do
  if [ -d "$path" ]; then
    while IFS= read -r -d '' file; do
      files+=("$file")
    done < <(find "$path" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0)
  else
    files+=("$path")
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "error: no PNG/JPEG files found" >&2
  exit 2
fi

matches_target() {
  local dims="$1"
  if [ "${#targets[@]}" -eq 0 ]; then
    return 0
  fi
  local target
  for target in "${targets[@]}"; do
    if [ "$dims" = "$target" ]; then
      return 0
    fi
  done
  return 1
}

status=0

for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "FAIL $file missing"
    status=1
    continue
  fi

  case "${file##*.}" in
    png|PNG|jpg|JPG|jpeg|JPEG) ;;
    *)
      echo "FAIL $file unsupported_extension"
      status=1
      continue
      ;;
  esac

  info="$(sips -g pixelWidth -g pixelHeight -g hasAlpha -g space "$file" 2>/dev/null)"
  if [ "$?" -ne 0 ] || [ -z "$info" ]; then
    echo "FAIL $file unreadable"
    status=1
    continue
  fi

  width="$(printf '%s\n' "$info" | awk '/pixelWidth:/ { print $2; exit }')"
  height="$(printf '%s\n' "$info" | awk '/pixelHeight:/ { print $2; exit }')"
  alpha="$(printf '%s\n' "$info" | awk '/hasAlpha:/ { print $2; exit }')"
  space="$(printf '%s\n' "$info" | awk -F': ' '/space:/ { print $2; exit }')"
  dims="${width}x${height}"

  fail_reasons=()
  warn_reasons=()

  if ! matches_target "$dims"; then
    fail_reasons+=("dimension=${dims}")
  fi

  if [ "$allow_alpha" -eq 0 ] && [ "$alpha" = "yes" ]; then
    fail_reasons+=("alpha=yes")
  fi

  case "$space" in
    *RGB*|*sRGB*) ;;
    "" ) warn_reasons+=("space=unknown") ;;
    * ) warn_reasons+=("space=${space}") ;;
  esac

  if [ "${#fail_reasons[@]}" -gt 0 ]; then
    echo "FAIL $file ${fail_reasons[*]}"
    status=1
  elif [ "${#warn_reasons[@]}" -gt 0 ]; then
    echo "WARN $file ${dims} alpha=${alpha:-unknown} ${warn_reasons[*]}"
  else
    echo "OK $file ${dims} alpha=${alpha:-unknown} space=${space:-unknown}"
  fi
done

exit "$status"
