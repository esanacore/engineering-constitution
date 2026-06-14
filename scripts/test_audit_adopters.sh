#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/audit_adopters.sh

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
audit_script="$script_dir/audit_adopters.sh"

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

# 2. Parent directory holding the adopting repositories.
adopters="$test_dir/adopters"
mkdir -p "$adopters"

# 2a. A current adopter: submodule pinned at the latest release (v1.1.0).
current="$adopters/current-project"
mkdir -p "$current"
cd "$current"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git commit -q --allow-empty -m "Initial commit"
git_quiet submodule add "$canonical" constitution >/dev/null 2>&1
git commit -q -m "Adopt constitution"

# 2b. A behind adopter: submodule pinned at the older release (v1.0.0).
behind="$adopters/behind-project"
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

# 2c. A non-adopter repo that must be ignored.
plain="$adopters/plain-project"
mkdir -p "$plain"
cd "$plain"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git commit -q --allow-empty -m "Initial commit"

# 3. Run the audit. It must exit non-zero because one repo is behind.
set +e
output=$("$audit_script" --fetch "$adopters" 2>&1)
status=$?
set -e

echo "$output"

echo "$output" | grep -q "current-project.*CURRENT" || { echo "FAIL: current-project not reported CURRENT"; exit 1; }
echo "$output" | grep -q "behind-project.*BEHIND" || { echo "FAIL: behind-project not reported BEHIND"; exit 1; }
echo "$output" | grep -q "plain-project" && { echo "FAIL: non-adopter plain-project should be ignored"; exit 1; }
echo "$output" | grep -q "Checked 2 adopting repositories; 1 behind." || { echo "FAIL: summary line incorrect"; exit 1; }
[ "$status" -eq 1 ] || { echo "FAIL: expected exit status 1 when a repo is behind, got $status"; exit 1; }

echo "SUCCESS: audit reports current/behind status and exits non-zero when behind."

# 4. With only current adopters, the audit must exit zero.
mkdir -p "$test_dir/adopters-current-only"
cp -r "$current" "$test_dir/adopters-current-only/only-current"

set +e
output2=$("$audit_script" --fetch "$test_dir/adopters-current-only" 2>&1)
status2=$?
set -e

echo "$output2"
echo "$output2" | grep -q "only-current.*CURRENT" || { echo "FAIL: only-current not reported CURRENT"; exit 1; }
[ "$status2" -eq 0 ] || { echo "FAIL: expected exit status 0 when all current, got $status2"; exit 1; }

echo "SUCCESS: audit exits zero when all adopters are current."

echo "ALL TESTS PASSED"
