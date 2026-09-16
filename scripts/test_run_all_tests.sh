#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/run_all_tests.sh (the framework's own "Full
# suite" runner). A test runner that could only pass would be worse than no
# runner, so the important cases are the ones where it must fail.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runner="$script_dir/run_all_tests.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make_suite() {
  # make_suite <dir> <name> <exit-code>
  local path="$1/$2"
  printf '#!/usr/bin/env bash\necho "output from %s"\nexit %s\n' "$2" "$3" > "$path"
  chmod +x "$path"
}

echo "Test 1: every suite passing exits 0 and reports each suite"
mkdir -p "$tmp/all-pass"
make_suite "$tmp/all-pass" test_alpha.sh 0
make_suite "$tmp/all-pass" test_beta.sh 0
output=$("$runner" --dir "$tmp/all-pass")
grep -q '^PASS  test_alpha.sh' <<< "$output" || { echo "FAIL: test_alpha.sh not reported as PASS"; echo "$output"; exit 1; }
grep -q '^PASS  test_beta.sh' <<< "$output" || { echo "FAIL: test_beta.sh not reported as PASS"; echo "$output"; exit 1; }
grep -q 'Suites: 2; passed: 2; failed: 0' <<< "$output" || { echo "FAIL: summary line wrong"; echo "$output"; exit 1; }
echo "PASS"

echo "Test 2: one failing suite fails the run and is named"
mkdir -p "$tmp/one-fail"
make_suite "$tmp/one-fail" test_good.sh 0
make_suite "$tmp/one-fail" test_bad.sh 3
status=0
output=$("$runner" --dir "$tmp/one-fail") || status=$?
[ "$status" -eq 1 ] || { echo "FAIL: expected exit 1, got $status"; echo "$output"; exit 1; }
grep -q '^FAIL  test_bad.sh (exit 3' <<< "$output" || { echo "FAIL: failing suite not named with its exit code"; echo "$output"; exit 1; }
grep -q '^FAIL: test_bad.sh' <<< "$output" || { echo "FAIL: summary does not list the failing suite"; echo "$output"; exit 1; }
echo "PASS"

echo "Test 3: --quiet still replays a failing suite's output"
status=0
output=$("$runner" --quiet --dir "$tmp/one-fail") || status=$?
[ "$status" -eq 1 ] || { echo "FAIL: expected exit 1 under --quiet, got $status"; exit 1; }
grep -q 'output from test_bad.sh' <<< "$output" || { echo "FAIL: failing suite output was hidden under --quiet"; echo "$output"; exit 1; }
if grep -q 'output from test_good.sh' <<< "$output"; then
  echo "FAIL: --quiet leaked a passing suite's output"; echo "$output"; exit 1
fi
echo "PASS"

echo "Test 4: a directory with no suites is an error, not a pass"
mkdir -p "$tmp/empty"
status=0
"$runner" --dir "$tmp/empty" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || { echo "FAIL: expected exit 2 for no suites, got $status"; exit 1; }
echo "PASS"

echo "Test 5: usage errors exit 2, --help exits 0"
status=0
"$runner" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || { echo "FAIL: expected exit 2 for an unknown option, got $status"; exit 1; }
status=0
"$runner" --dir "$tmp/does-not-exist" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || { echo "FAIL: expected exit 2 for a missing directory, got $status"; exit 1; }
"$runner" --help | grep -q '^Usage:' || { echo "FAIL: --help did not print usage"; exit 1; }
echo "PASS"

echo "Test 6: under GitHub Actions a failure emits an ::error:: annotation"
status=0
output=$(GITHUB_ACTIONS=true "$runner" --quiet --dir "$tmp/one-fail") || status=$?
grep -q '^::error::run_all_tests.sh: 1 of 2 suites failed: test_bad.sh' <<< "$output" || { echo "FAIL: no ::error:: annotation under GITHUB_ACTIONS"; echo "$output"; exit 1; }
output=$("$runner" --quiet --dir "$tmp/all-pass")
if grep -q '^::' <<< "$output"; then
  echo "FAIL: annotation emitted outside GitHub Actions"; echo "$output"; exit 1
fi
echo "PASS"

echo "ALL TESTS PASSED"
