#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/run_declared_tests.sh
#
# Covers the negative cases the constitution requires of governance tooling
# (TESTING.md, "Governance Tooling Must Be Tested"): a repository with no
# declared test command must not silently pass as "tested", and a declared
# command that fails must fail this checker even without --strict.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/run_declared_tests.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

run_check() {
  set +e
  output=$("$check_script" "$@" 2>&1)
  status=$?
  set -e
}

write_test_plan() {
  local dest=$1 full_suite_line=$2
  mkdir -p "$dest/docs"
  cat > "$dest/docs/TEST_PLAN.md" <<EOF
# Test Plan

## How to Run Tests

- Full suite: $full_suite_line
- With coverage: \`<command>\`
- A single test or subset: \`<command>\`
EOF
}

# ---------------------------------------------------------------------------
# 1. No docs/TEST_PLAN.md -> warn, exit 0; --strict -> exit 1.
# ---------------------------------------------------------------------------
repo="$test_dir/1"
mkdir -p "$repo"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 by default with no TEST_PLAN.md, got $status"; exit 1; }
echo "$output" | grep -qi "No docs/TEST_PLAN.md found" || { echo "FAIL(1): missing explanation"; exit 1; }

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(1): expected exit 1 under --strict, got $status"; exit 1; }
echo "SUCCESS(1): missing TEST_PLAN.md warns by default and fails under --strict."

# ---------------------------------------------------------------------------
# 2. Placeholder command still present -> warn, exit 0; --strict -> exit 1.
# ---------------------------------------------------------------------------
repo="$test_dir/2"
write_test_plan "$repo" '`<command>`'

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2): expected exit 0 by default with a placeholder command, got $status"; exit 1; }
echo "$output" | grep -qi "still a placeholder" || { echo "FAIL(2): missing placeholder explanation"; exit 1; }

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 under --strict, got $status"; exit 1; }
echo "SUCCESS(2): placeholder command warns by default and fails under --strict."

# ---------------------------------------------------------------------------
# 3. Real passing command -> it actually runs (side effect) and exits 0.
# ---------------------------------------------------------------------------
repo="$test_dir/3"
marker="$repo/ran.marker"
write_test_plan "$repo" "\`touch $marker\`"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected exit 0 for a passing declared command, got $status"; exit 1; }
[ -f "$marker" ] || { echo "FAIL(3): declared command did not actually run"; exit 1; }
echo "SUCCESS(3): a declared passing command runs and succeeds."

# ---------------------------------------------------------------------------
# 4. Real failing command -> exit 1 even WITHOUT --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/4"
write_test_plan "$repo" '`exit 7`'

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 for a failing declared command (no --strict), got $status"; exit 1; }
echo "$output" | grep -qi "failed" || { echo "FAIL(4): missing failure explanation"; exit 1; }
echo "SUCCESS(4): a declared failing command is always enforced, regardless of --strict."

# ---------------------------------------------------------------------------
# 5. Usage error -> exit 2.
# ---------------------------------------------------------------------------
run_check --bogus-flag
echo "$output"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected exit 2 for an unknown flag, got $status"; exit 1; }
echo "SUCCESS(5): usage errors report exit 2."

echo
echo "All run_declared_tests.sh tests passed."
