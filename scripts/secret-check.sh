#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=secret-check

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '%s: HOST_REQUIREMENT_MISSING: required command not found: %s\n' "$SCRIPT_NAME" "$1" >&2
    exit 1
  }
}

require_command git
require_command grep

patterns=(
  "private-key-block:-----BEGIN (RSA |DSA |EC |OPENSSH |)PRIVATE KEY-----"
  "openai-api-key:(^|[^A-Za-z0-9_])sk-[A-Za-z0-9_-]{30,}"
  "github-token:gh[pousr]_[A-Za-z0-9_]{20,}"
  "aws-access-key:AKIA[0-9A-Z]{16}"
  "slack-token:xox[baprs]-[A-Za-z0-9-]{20,}"
)

failures=0
files=()

while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  files+=("$file")
done < <(git ls-files --cached --others --exclude-standard)

for file in "${files[@]}"; do
  grep -Iq . "$file" || continue
  for item in "${patterns[@]}"; do
    label=${item%%:*}
    regex=${item#*:}
    if grep -Eq -- "$regex" "$file"; then
      printf 'SECRET_LEAK_RISK: %s found in %s\n' "$label" "$file" >&2
      failures=$((failures + 1))
    fi
  done
done

if [[ "$failures" -gt 0 ]]; then
  printf 'secret-check: FAIL (%s findings; values intentionally not printed)\n' "$failures" >&2
  exit 1
fi

printf 'secret-check: PASS (%s files scanned)\n' "${#files[@]}"
