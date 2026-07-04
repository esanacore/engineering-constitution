#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_source_summaries.sh
#
# Covers the positive scan/record flow plus the negative cases the
# constitution requires of governance tooling (TESTING.md, "Governance
# Tooling Must Be Tested"): a file with no manifest row must be reported as
# NEW rather than silently passing, and `record` must refuse to run when the
# summary has not been written yet.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_source_summaries.sh"

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

make_root() {
  dest=$1
  mkdir -p "$dest/raw" "$dest/summaries"
}

# ---------------------------------------------------------------------------
# 1. Empty raw/ -> exit 0, nothing to report as pending.
# ---------------------------------------------------------------------------
root="$test_dir/1"
make_root "$root"

run_check scan "$root"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 for empty raw/, got $status"; exit 1; }
echo "$output" | grep -q "Pending: 0 " || { echo "FAIL(1): expected zero pending"; exit 1; }
echo "SUCCESS(1): empty raw/ reports nothing pending."

# ---------------------------------------------------------------------------
# 2. New file, no manifest row -> reported NEW, exit 1.
# ---------------------------------------------------------------------------
root="$test_dir/2"
make_root "$root"
echo "book contents" > "$root/raw/book.md"

run_check scan "$root"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 for a new file, got $status"; exit 1; }
echo "$output" | grep -q "NEW              book.md" || { echo "FAIL(2): book.md not reported NEW"; exit 1; }
echo "SUCCESS(2): new file with no manifest row is reported NEW."

# ---------------------------------------------------------------------------
# 3. Manifest row + matching hash + summary present -> OK, exit 0.
# ---------------------------------------------------------------------------
root="$test_dir/3"
make_root "$root"
echo "book contents" > "$root/raw/book.md"
echo "summary" > "$root/summaries/book.md"

run_check record book.md "$root"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected record to succeed, got $status"; exit 1; }

run_check scan "$root"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected exit 0 once recorded, got $status"; exit 1; }
echo "$output" | grep -q "OK               book.md" || { echo "FAIL(3): book.md not reported OK"; exit 1; }
echo "SUCCESS(3): recorded file with matching hash and summary is OK."

# ---------------------------------------------------------------------------
# 4. Manifest row + changed hash -> CHANGED, exit 1.
# ---------------------------------------------------------------------------
root="$test_dir/4"
make_root "$root"
echo "book contents v1" > "$root/raw/book.md"
echo "summary" > "$root/summaries/book.md"
run_check record book.md "$root"
[ "$status" -eq 0 ] || { echo "FAIL(4): setup record failed"; exit 1; }

echo "book contents v2 - different" > "$root/raw/book.md"
run_check scan "$root"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 for changed file, got $status"; exit 1; }
echo "$output" | grep -q "CHANGED          book.md" || { echo "FAIL(4): book.md not reported CHANGED"; exit 1; }
echo "SUCCESS(4): file with a changed hash is reported CHANGED."

# ---------------------------------------------------------------------------
# 5. Manifest row + matching hash + summary deleted -> SUMMARY_MISSING, exit 1.
# ---------------------------------------------------------------------------
root="$test_dir/5"
make_root "$root"
echo "book contents" > "$root/raw/book.md"
echo "summary" > "$root/summaries/book.md"
run_check record book.md "$root"
[ "$status" -eq 0 ] || { echo "FAIL(5): setup record failed"; exit 1; }
rm "$root/summaries/book.md"

run_check scan "$root"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(5): expected exit 1 when summary is missing, got $status"; exit 1; }
echo "$output" | grep -q "SUMMARY_MISSING  book.md" || { echo "FAIL(5): book.md not reported SUMMARY_MISSING"; exit 1; }
echo "SUCCESS(5): recorded file whose summary was deleted is SUMMARY_MISSING."

# ---------------------------------------------------------------------------
# 6. Manifest row whose raw file was deleted -> ORPHANED SUMMARY, exit 0
#    (warning only, no other pending items).
# ---------------------------------------------------------------------------
root="$test_dir/6"
make_root "$root"
echo "book contents" > "$root/raw/book.md"
echo "summary" > "$root/summaries/book.md"
run_check record book.md "$root"
[ "$status" -eq 0 ] || { echo "FAIL(6): setup record failed"; exit 1; }
rm "$root/raw/book.md"

run_check scan "$root"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(6): expected exit 0 for an orphaned summary alone, got $status"; exit 1; }
echo "$output" | grep -q "ORPHANED SUMMARY book.md (raw file removed: book.md)" || { echo "FAIL(6): orphaned summary not reported"; exit 1; }
echo "SUCCESS(6): summary whose raw file was removed is reported as an orphan warning, not a failure."

# ---------------------------------------------------------------------------
# 7. Negative case: record with no summary written yet -> exit 1.
# ---------------------------------------------------------------------------
root="$test_dir/7"
make_root "$root"
echo "book contents" > "$root/raw/book.md"

run_check record book.md "$root"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(7): expected exit 1 when summary is missing, got $status"; exit 1; }
echo "$output" | grep -qi "write the summary before recording" || { echo "FAIL(7): missing summary error not reported"; exit 1; }
echo "SUCCESS(7): record refuses to run without a summary."

# ---------------------------------------------------------------------------
# 8. record on a valid pair updates the manifest; a follow-up scan is OK.
#    (Also covered by case 3, but assert the manifest row content directly.)
# ---------------------------------------------------------------------------
root="$test_dir/8"
make_root "$root"
mkdir -p "$root/raw/nested" "$root/summaries/nested"
echo "book contents" > "$root/raw/nested/book.epub"
echo "summary" > "$root/summaries/nested/book.md"

run_check record "nested/book.epub" "$root"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(8): expected record to succeed for nested path, got $status"; exit 1; }
grep -q "^nested/book.epub	" "$root/manifest.tsv" || { echo "FAIL(8): manifest row for nested path not written"; exit 1; }
grep -q "nested/book.md" "$root/manifest.tsv" || { echo "FAIL(8): manifest row does not reference the mirrored summary path"; exit 1; }

run_check scan "$root"
[ "$status" -eq 0 ] || { echo "FAIL(8): expected exit 0 after recording nested path, got $status"; exit 1; }
echo "$output" | grep -q "OK               nested/book.epub" || { echo "FAIL(8): nested/book.epub not reported OK"; exit 1; }
echo "SUCCESS(8): record handles nested paths and mirrors the summary location."

# ---------------------------------------------------------------------------
# 9. Unknown subcommand -> exit 2.
# ---------------------------------------------------------------------------
run_check bogus
echo "$output"
[ "$status" -eq 2 ] || { echo "FAIL(9): expected exit 2 for unknown subcommand, got $status"; exit 1; }
echo "SUCCESS(9): unknown subcommand fails with usage error."

# ---------------------------------------------------------------------------
# 10. A README left in raw/ (to guide users where to drop files) is not
#     treated as a source, even though .md is a recognized extension, and
#     `record` refuses to record one.
# ---------------------------------------------------------------------------
root="$test_dir/10"
make_root "$root"
echo "drop your files here" > "$root/raw/README.md"
echo "book contents" > "$root/raw/book.md"

run_check scan "$root"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(10): expected exit 1 (book.md is NEW), got $status"; exit 1; }
echo "$output" | grep -q "README.md" && { echo "FAIL(10): README.md should not be reported at all"; exit 1; }
echo "$output" | grep -q "NEW              book.md" || { echo "FAIL(10): book.md not reported NEW"; exit 1; }
echo "$output" | grep -q "Pending: 1 " || { echo "FAIL(10): expected exactly one pending entry, got: $output"; exit 1; }

run_check record README.md "$root"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(10): expected record to refuse a README, got $status"; exit 1; }
echo "$output" | grep -qi "not a source to record" || { echo "FAIL(10): record did not explain why it refused the README"; exit 1; }
echo "SUCCESS(10): a README in raw/ is invisible to scan and record refuses to process it."

echo
echo "All check_source_summaries.sh tests passed."
