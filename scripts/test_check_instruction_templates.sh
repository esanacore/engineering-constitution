#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_instruction_templates.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_instruction_templates.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $*"; exit 1; }

consistent="$tmp/consistent"
mkdir -p "$consistent/.github/agents" "$consistent/docs"
for f in AGENTS.md CLAUDE.md .cursorrules .github/agents/solon.agent.md docs/HELP.md; do
  printf '# %s\n\nCheck docs/SESSION_PLAN.md first. Read docs/MEMORY.md for context.\n' "$f" > "$consistent/$f"
done
# A file the checker does not know about must be ignored even when it lacks everything.
printf 'nothing here\n' > "$consistent/NOTES.md"

echo "Test 1: consistent files pass, even under --strict, and unknown files are ignored"
out=$("$checker" --strict "$consistent")
grep -q 'Checked 5 instruction file(s); 0 with missing anchors' <<< "$out" || { echo "$out"; fail "expected 5 files checked with no gaps"; }
if grep -q 'NOTES.md' <<< "$out"; then fail "NOTES.md is not an instruction file and must not be scanned"; fi
echo "PASS"

echo "Test 2: a file missing an anchor is flagged: warn by default, fail under --strict"
drift="$tmp/drift"
cp -r "$consistent" "$drift"
printf '# Cursor\n\nRead docs/MEMORY.md.\n' > "$drift/.cursorrules"
status=0; out=$("$checker" "$drift") || status=$?
[ "$status" -eq 0 ] || fail "warn mode exited $status, expected 0"
grep -q 'MISSING  .cursorrules lacks: SESSION_PLAN' <<< "$out" || { echo "$out"; fail "drifted file not named with its missing anchor"; }
grep -q '^WARN:' <<< "$out" || fail "no WARN summary in warn mode"
status=0; out=$("$checker" --strict "$drift") || status=$?
[ "$status" -eq 1 ] || fail "--strict exited $status, expected 1"
grep -q '^FAIL:' <<< "$out" || fail "no FAIL summary under --strict"
echo "PASS"

echo "Test 3: custom --anchor values replace the defaults"
status=0; out=$("$checker" --strict --anchor "TODO.md" --anchor "CHANGELOG.md" "$consistent") || status=$?
[ "$status" -eq 1 ] || fail "custom anchors absent from every file should fail under --strict, got $status"
grep -q 'lacks: TODO.md CHANGELOG.md' <<< "$out" || { echo "$out"; fail "custom anchors not reported"; }
status=0; "$checker" --strict --anchor "SESSION_PLAN" "$drift" >/dev/null || status=$?
[ "$status" -eq 1 ] || fail "drift should still fail when only SESSION_PLAN is required, got $status"
status=0; "$checker" --strict --anchor "MEMORY.md" "$drift" >/dev/null || status=$?
[ "$status" -eq 0 ] || fail "drift should pass when only MEMORY.md is required, got $status"
echo "PASS"

echo "Test 4: a directory with no instruction files is not a failure"
mkdir -p "$tmp/none"
out=$("$checker" --strict "$tmp/none")
grep -q 'No instruction files found' <<< "$out" || fail "expected the no-files note"
echo "PASS"

echo "Test 5: usage errors exit 2"
status=0; "$checker" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
status=0; "$checker" "$tmp/does-not-exist" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing directory exited $status, expected 2"
status=0; "$checker" --anchor >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "--anchor without a value exited $status, expected 2"
echo "PASS"

echo "ALL TESTS PASSED"
