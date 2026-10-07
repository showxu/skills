#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage: check_play_assets.sh --kind KIND FILE_OR_DIR...

KIND:
  screenshot        Google Play generic screenshot requirements
  feature-graphic  1024x500 JPEG or 24-bit PNG, no alpha
  app-icon         512x512 PNG with alpha, max 1024KB
  large-screen     tablet/Chromebook recommendation check, 16:9 or 9:16
  wear-os          1:1 screenshot, minimum 384x384
  android-xr       8:5 screenshot, minimum 1920x1200, max 8MB

Uses macOS sips for image metadata. Exits 1 when any file fails.
USAGE
}

kind=""
paths=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --kind)
      if [ "$#" -lt 2 ]; then
        echo "error: --kind requires a value" >&2
        exit 2
      fi
      kind="$2"
      shift 2
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

case "$kind" in
  screenshot|feature-graphic|app-icon|large-screen|wear-os|android-xr) ;;
  "")
    echo "error: --kind is required" >&2
    usage >&2
    exit 2
    ;;
  *)
    echo "error: unsupported kind: $kind" >&2
    usage >&2
    exit 2
    ;;
esac

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

ratio_is() {
  local width="$1"
  local height="$2"
  local a="$3"
  local b="$4"
  [ $((width * b)) -eq $((height * a)) ]
}

status=0

for file in "${files[@]}"; do
  fail_reasons=()
  warn_reasons=()

  if [ ! -f "$file" ]; then
    echo "FAIL $file missing"
    status=1
    continue
  fi

  ext="$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')"
  case "$ext" in
    png|jpg|jpeg) ;;
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
  size_bytes="$(wc -c < "$file" | tr -d ' ')"
  min_dim="$width"
  max_dim="$height"
  if [ "$height" -lt "$min_dim" ]; then min_dim="$height"; fi
  if [ "$width" -gt "$max_dim" ]; then max_dim="$width"; fi
  dims="${width}x${height}"

  case "$kind" in
    screenshot)
      if [ "$min_dim" -lt 320 ]; then fail_reasons+=("min_dimension=${min_dim}<320"); fi
      if [ "$max_dim" -gt 3840 ]; then fail_reasons+=("max_dimension=${max_dim}>3840"); fi
      if [ "$max_dim" -gt $((min_dim * 2)) ]; then fail_reasons+=("ratio_long_side_gt_2x_short_side"); fi
      if [ "$alpha" = "yes" ]; then fail_reasons+=("alpha=yes"); fi
      ;;
    feature-graphic)
      if [ "$dims" != "1024x500" ]; then fail_reasons+=("dimension=${dims},expected=1024x500"); fi
      if [ "$alpha" = "yes" ]; then fail_reasons+=("alpha=yes"); fi
      ;;
    app-icon)
      if [ "$ext" != "png" ]; then fail_reasons+=("extension=${ext},expected=png"); fi
      if [ "$dims" != "512x512" ]; then fail_reasons+=("dimension=${dims},expected=512x512"); fi
      if [ "$alpha" != "yes" ]; then fail_reasons+=("alpha=${alpha:-unknown},expected=yes"); fi
      if [ "$size_bytes" -gt 1048576 ]; then fail_reasons+=("size=${size_bytes}>1048576"); fi
      ;;
    large-screen)
      if [ "$min_dim" -lt 1080 ]; then fail_reasons+=("min_dimension=${min_dim}<1080"); fi
      if ! ratio_is "$width" "$height" 16 9 && ! ratio_is "$width" "$height" 9 16; then
        fail_reasons+=("aspect_ratio=${dims},expected=16:9_or_9:16")
      fi
      if [ "$alpha" = "yes" ]; then fail_reasons+=("alpha=yes"); fi
      ;;
    wear-os)
      if [ "$width" -ne "$height" ]; then fail_reasons+=("aspect_ratio=${dims},expected=1:1"); fi
      if [ "$min_dim" -lt 384 ]; then fail_reasons+=("min_dimension=${min_dim}<384"); fi
      if [ "$alpha" = "yes" ]; then fail_reasons+=("alpha=yes"); fi
      ;;
    android-xr)
      if ! ratio_is "$width" "$height" 8 5; then fail_reasons+=("aspect_ratio=${dims},expected=8:5"); fi
      if [ "$width" -lt 1920 ] || [ "$height" -lt 1200 ]; then fail_reasons+=("dimension=${dims},min=1920x1200"); fi
      if [ "$size_bytes" -gt 8388608 ]; then fail_reasons+=("size=${size_bytes}>8388608"); fi
      if [ "$alpha" = "yes" ]; then warn_reasons+=("alpha=yes"); fi
      ;;
  esac

  case "$space" in
    *RGB*|*sRGB*) ;;
    "" ) warn_reasons+=("space=unknown") ;;
    * ) warn_reasons+=("space=${space}") ;;
  esac

  if [ "${#fail_reasons[@]}" -gt 0 ]; then
    echo "FAIL $file kind=$kind ${fail_reasons[*]}"
    status=1
  elif [ "${#warn_reasons[@]}" -gt 0 ]; then
    echo "WARN $file kind=$kind ${dims} alpha=${alpha:-unknown} ${warn_reasons[*]}"
  else
    echo "OK $file kind=$kind ${dims} alpha=${alpha:-unknown} size=${size_bytes}"
  fi
done

exit "$status"
