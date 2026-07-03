#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
expected_version=$(tr -d '\r\n' < "$repo_root/VERSION")

check_contains_version() {
  local file="$1"
  if grep -Fq "$expected_version" "$file"; then
    echo "PASS: $(basename "$file") mentions $expected_version"
  else
    echo "FAIL: $file does not mention VERSION $expected_version"
    exit 1
  fi
}

check_contains_version "$repo_root/README.md"
check_contains_version "$repo_root/CONSTITUTION.md"
check_contains_version "$repo_root/wiki/Home.md"

echo "ALL TESTS PASSED"
