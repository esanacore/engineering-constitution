#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_constitution_freshness.sh

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_constitution_freshness.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

git_quiet() {
  git -c protocol.file.allow=always -c advice.detachedHead=false "$@"
}

# 1. Build a fake canonical constitution repo with two tagged releases.
canonical="$test_dir/constitution-source"
mkdir -p "$canonical"
cd "$canonical"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
echo "1.0.0" > VERSION
git add VERSION
git commit -q -m "Release 1.0.0"
git tag v1.0.0
echo "1.1.0" > VERSION
git add VERSION
git commit -q -m "Release 1.1.0"
git tag v1.1.0

# 2a. A current adopter: submodule pinned at the latest release (v1.1.0).
current="$test_dir/current-project"
mkdir -p "$current"
cd "$current"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git commit -q --allow-empty -m "Initial commit"
git_quiet submodule add "$canonical" constitution >/dev/null 2>&1
git commit -q -m "Adopt constitution"

set +e
output=$("$check_script" --no-fetch "$current" 2>&1)
status=$?
set -e
echo "$output"
echo "$output" | grep -q "CURRENT (v1.1.0)" || { echo "FAIL: current project not reported CURRENT"; exit 1; }
[ "$status" -eq 0 ] || { echo "FAIL: expected exit status 0 for current project, got $status"; exit 1; }
echo "SUCCESS: current project reports CURRENT and exits 0."

# 2b. A behind adopter: submodule pinned at the older release (v1.0.0).
behind="$test_dir/behind-project"
mkdir -p "$behind"
cd "$behind"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git commit -q --allow-empty -m "Initial commit"
git_quiet submodule add "$canonical" constitution >/dev/null 2>&1
git_quiet -C constitution checkout -q v1.0.0
git add constitution
git commit -q -m "Adopt constitution (older release)"

set +e
output=$("$check_script" --no-fetch "$behind" 2>&1)
status=$?
set -e
echo "$output"
echo "$output" | grep -q "BEHIND -- pinned v1.0.0, latest v1.1.0" || { echo "FAIL: behind project not reported BEHIND with correct versions"; exit 1; }
echo "$output" | grep -q "git submodule update --remote constitution" || { echo "FAIL: behind project missing remediation instructions"; exit 1; }
echo "$output" | grep -q "INTEGRATION.md" || { echo "FAIL: behind project missing migration checklist pointer"; exit 1; }
[ "$status" -eq 1 ] || { echo "FAIL: expected exit status 1 for behind project, got $status"; exit 1; }
echo "SUCCESS: behind project reports BEHIND with remediation steps and exits 1."

# 2c. A non-adopter repo (no constitution/ submodule at all).
plain="$test_dir/plain-project"
mkdir -p "$plain"
cd "$plain"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git commit -q --allow-empty -m "Initial commit"

set +e
output=$("$check_script" --no-fetch "$plain" 2>&1)
status=$?
set -e
echo "$output"
echo "$output" | grep -q "No constitution/ submodule found" || { echo "FAIL: non-adopter project did not report missing submodule"; exit 1; }
[ "$status" -eq 2 ] || { echo "FAIL: expected exit status 2 for non-adopter project, got $status"; exit 1; }
echo "SUCCESS: non-adopter project reports UNKNOWN and exits 2."

# 3. Default (fetching) behavior still detects a repo that is behind, proving
#    the fetch-by-default design actually reaches the network rather than only
#    ever comparing stale local tags.
behind_fetch="$test_dir/behind-fetch-project"
mkdir -p "$behind_fetch"
cd "$behind_fetch"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git commit -q --allow-empty -m "Initial commit"
git_quiet submodule add "$canonical" constitution >/dev/null 2>&1
git_quiet -C constitution checkout -q v1.0.0
git add constitution
git commit -q -m "Adopt constitution (older release)"

# New tags land on the canonical remote after this repo already adopted it,
# simulating a release that happened after this repo last fetched.
cd "$canonical"
echo "1.2.0" > VERSION
git add VERSION
git commit -q -m "Release 1.2.0"
git tag v1.2.0

set +e
output=$("$check_script" "$behind_fetch" 2>&1)
status=$?
set -e
echo "$output"
echo "$output" | grep -q "BEHIND -- pinned v1.0.0, latest v1.2.0" || { echo "FAIL: default fetch did not pick up the newly tagged v1.2.0 release"; exit 1; }
[ "$status" -eq 1 ] || { echo "FAIL: expected exit status 1 after fetching a newer release, got $status"; exit 1; }
echo "SUCCESS: default (fetching) run detects a release tagged after last update."

echo "ALL TESTS PASSED"
