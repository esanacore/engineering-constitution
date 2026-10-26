#!/usr/bin/env bash
# Regression test for the adopter workflow templates: every checker a template
# runs must be called through the `constitution/` submodule path, and a template
# that does so must check out submodules. A bare `scripts/check_*.sh` path exists
# only in this repository, so in an adopter the step silently skips or fails.
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
templates_dir="$script_dir/../templates/.github/workflows"

pass_count=0
fail_count=0

pass() { echo "  PASS $1"; pass_count=$((pass_count + 1)); }
fail() { echo "  FAIL $1"; fail_count=$((fail_count + 1)); }

shopt -s nullglob
templates=("$templates_dir"/*.yml)
if [ "${#templates[@]}" -eq 0 ]; then
  echo "FAIL: no workflow templates found in $templates_dir"
  exit 1
fi

for template in "${templates[@]}"; do
  name=$(basename "$template")
  echo "Template: $name"

  # Non-comment lines that name a checker script without the submodule prefix.
  bare=$(grep -nE 'scripts/check_[a-z_]+\.sh' "$template" \
    | grep -vE '^[0-9]+:[[:space:]]*#' \
    | grep -vE 'constitution/scripts/check_[a-z_]+\.sh' || true)
  if [ -z "$bare" ]; then
    pass "checkers are called through constitution/scripts/"
  else
    fail "bare scripts/ path outside a comment:"
    echo "$bare" | sed 's/^/      /'
  fi

  if grep -vE '^[[:space:]]*#' "$template" | grep -qE 'constitution/scripts/'; then
    if grep -qE 'submodules:[[:space:]]*(true|recursive)' "$template"; then
      pass "checks out submodules"
    else
      fail "uses constitution/scripts/ but never checks out submodules"
    fi
  fi
done

echo
echo "Passed: $pass_count, Failed: $fail_count"
[ "$fail_count" -eq 0 ]
