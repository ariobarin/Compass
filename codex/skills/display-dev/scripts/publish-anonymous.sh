#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: publish-anonymous.sh <file>\n' >&2
  exit 1
fi

file="$1"
if [[ "$file" == "-" || ! -r "$file" ]]; then
  printf 'file must be readable and may not be -: %s\n' "$file" >&2
  exit 1
fi

case "$file" in
  *.[Hh][Tt][Mm][Ll]|*.[Mm][Dd]) ;;
  *)
    printf 'file must end in .html or .md: %s\n' "$file" >&2
    exit 1
    ;;
esac

if [[ "$file" == *'"'* || "$file" == *';'* || "$file" == *','* || "$file" =~ [[:cntrl:]] ]]; then
  printf 'file path may not contain ", ;, comma, or control characters\n' >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  printf 'curl is required\n' >&2
  exit 1
fi

response="$(
  curl -sS \
    -X POST 'https://api.display.dev/v1/public/artifacts' \
    -H 'X-Client-Type: cli' \
    -H 'X-Client-Source: compass-display-dev' \
    -F "file=@$file" \
    -w $'\n%{http_code}'
)"

http_code="${response##*$'\n'}"
body="${response%$'\n'*}"

if [[ "$http_code" != "201" ]]; then
  printf 'Display.dev returned HTTP %s\n' "$http_code" >&2
  printf '%s\n' "$body" >&2
  exit 1
fi

printf '%s\n' "$body"
