#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_traceability.sh
#
# These cover the positive case plus the negative cases the constitution requires
# of governance tooling (TESTING.md, "Governance Tooling Must Be Tested"),
# including the substring-collision case where a layered ID (BB-FR-007) must not
# satisfy a check for a same-numbered system-layer ID (FR-007).

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_traceability.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

# Helper: write a product requirements file from the bold IDs passed as args.
write_reqs() {
  dest=$1
  shift
  {
    echo "# Product Requirements"
    echo
    echo "## Functional Requirements"
    echo
    for id in "$@"; do
      echo "**$id** \`MUST\` example requirement $id."
      echo
      echo "- Acceptance criteria:"
      echo "  - \`$id-AC-1\`: observable condition."
      echo
    done
  } > "$dest"
}

# Helper: start a matrix file with the standard header.
start_matrix() {
  dest=$1
  {
    echo "# Requirements Traceability Matrix"
    echo
    echo "| Requirement ID | Level | Description | Acceptance Criteria | Verifying Tests | Status |"
    echo "| --- | --- | --- | --- | --- | --- |"
  } > "$dest"
}

matrix_row() {
  dest=$1
  id=$2
  verifying=$3
  echo "| $id | MUST | desc | $id-AC-1 | $verifying | Verified |" >> "$dest"
}

run_check() {
  set +e
  output=$("$check_script" "$1" "$2" 2>&1)
  status=$?
  set -e
}

# ---------------------------------------------------------------------------
# 1. Happy path: every declared requirement has a verifying test -> exit 0.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr1.md"
matrix="$test_dir/tm1.md"
write_reqs "$reqs" FR-001 NFR-001
start_matrix "$matrix"
matrix_row "$matrix" FR-001 "tests/test_login.py::test_login"
matrix_row "$matrix" NFR-001 "tests/test_auth.py::test_authz"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 when all covered, got $status"; exit 1; }
echo "$output" | grep -q "OK       FR-001" || { echo "FAIL(1): FR-001 not reported OK"; exit 1; }
echo "$output" | grep -q "OK       NFR-001" || { echo "FAIL(1): NFR-001 not reported OK"; exit 1; }
echo "SUCCESS(1): all-covered case passes."

# ---------------------------------------------------------------------------
# 2. Gap entry: a requirement whose Verifying Tests cell is a gap marker -> exit 1.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr2.md"
matrix="$test_dir/tm2.md"
write_reqs "$reqs" FR-001 FR-002
start_matrix "$matrix"
matrix_row "$matrix" FR-001 "tests/test_a.py::test_a"
matrix_row "$matrix" FR-002 "none — GAP"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 on gap, got $status"; exit 1; }
echo "$output" | grep -q "GAP      FR-002" || { echo "FAIL(2): FR-002 gap not detected"; exit 1; }
echo "SUCCESS(2): gap-marker case fails as required."

# ---------------------------------------------------------------------------
# 3. Missing row: a declared requirement absent from the matrix -> exit 1.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr3.md"
matrix="$test_dir/tm3.md"
write_reqs "$reqs" FR-001 FR-009
start_matrix "$matrix"
matrix_row "$matrix" FR-001 "tests/test_a.py::test_a"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected exit 1 on missing row, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  FR-009" || { echo "FAIL(3): FR-009 missing row not detected"; exit 1; }
echo "SUCCESS(3): missing-row case fails as required."

# ---------------------------------------------------------------------------
# 4. Substring collision: FR-007 is declared, but the matrix only has a covered
#    row for the layered ID BB-FR-007. A non-anchored matcher would let the
#    BB-FR-007 row satisfy FR-007. The checker must still report FR-007 MISSING.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr4.md"
matrix="$test_dir/tm4.md"
write_reqs "$reqs" FR-007
start_matrix "$matrix"
matrix_row "$matrix" BB-FR-007 "tests/test_blueprint.py::test_bb"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 — BB-FR-007 must not satisfy FR-007, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  FR-007" || { echo "FAIL(4): FR-007 not reported MISSING (substring collision)"; exit 1; }
echo "$output" | grep -q "OK       FR-007" && { echo "FAIL(4): FR-007 wrongly satisfied by BB-FR-007"; exit 1; }
echo "SUCCESS(4): layered ID BB-FR-007 does not satisfy system-layer FR-007."

# ---------------------------------------------------------------------------
# 5. Layered collision, both rows present: FR-007 has only a gap entry while the
#    same-numbered BB-FR-007 is fully covered. Both are declared. FR-007 must
#    fail; BB-FR-007 must pass. This proves coverage is keyed per-exact-ID.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr5.md"
matrix="$test_dir/tm5.md"
write_reqs "$reqs" FR-007 BB-FR-007
start_matrix "$matrix"
matrix_row "$matrix" FR-007 "none — GAP"
matrix_row "$matrix" BB-FR-007 "tests/test_blueprint.py::test_bb"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(5): expected exit 1 when FR-007 is a gap, got $status"; exit 1; }
echo "$output" | grep -q "GAP      FR-007" || { echo "FAIL(5): FR-007 gap not detected next to BB-FR-007"; exit 1; }
echo "$output" | grep -q "OK       BB-FR-007" || { echo "FAIL(5): BB-FR-007 not reported OK"; exit 1; }
echo "SUCCESS(5): per-exact-ID keying keeps FR-007 and BB-FR-007 independent."

# ---------------------------------------------------------------------------
# 6. Unfilled template placeholder counts as a gap -> exit 1.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr6.md"
matrix="$test_dir/tm6.md"
write_reqs "$reqs" FR-001
start_matrix "$matrix"
matrix_row "$matrix" FR-001 '`<test reference or "none — GAP">`'

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(6): expected exit 1 on unfilled placeholder, got $status"; exit 1; }
echo "$output" | grep -q "GAP      FR-001" || { echo "FAIL(6): placeholder not treated as gap"; exit 1; }
echo "SUCCESS(6): unfilled placeholder treated as a gap."

# ---------------------------------------------------------------------------
# 7. No declared requirements -> vacuously passes with exit 0.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr7.md"
matrix="$test_dir/tm7.md"
{ echo "# Product Requirements"; echo; echo "No requirements yet."; } > "$reqs"
start_matrix "$matrix"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(7): expected exit 0 when no IDs declared, got $status"; exit 1; }
echo "SUCCESS(7): no-requirements case passes vacuously."

# ---------------------------------------------------------------------------
# 8. Missing input file -> usage error exit 2.
# ---------------------------------------------------------------------------
run_check "$test_dir/does-not-exist.md" "$matrix"
[ "$status" -eq 2 ] || { echo "FAIL(8): expected exit 2 on missing input, got $status"; exit 1; }
echo "SUCCESS(8): missing input file reports usage error."

# ---------------------------------------------------------------------------
# 9. Multiple tables: separate Functional and Non-Functional matrices parse, and
#    an unrelated trailing table (Coverage Summary) is not parsed as if its rows
#    were requirements. This guards the per-table column scoping.
# ---------------------------------------------------------------------------
reqs="$test_dir/pr9.md"
matrix="$test_dir/tm9.md"
write_reqs "$reqs" FR-001 NFR-001
{
  echo "# Requirements Traceability Matrix"
  echo
  echo "## Functional Requirements"
  echo
  echo "| Requirement ID | Level | Description | Acceptance Criteria | Verifying Tests | Status |"
  echo "| --- | --- | --- | --- | --- | --- |"
  echo "| FR-001 | MUST | desc | FR-001-AC-1 | tests/test_f.py::test_f | Verified |"
  echo
  echo "## Non-Functional Requirements"
  echo
  echo "| Requirement ID | Level | Description | Acceptance Criteria | Verifying Tests | Status |"
  echo "| --- | --- | --- | --- | --- | --- |"
  echo "| NFR-001 | MUST | desc | NFR-001-AC-1 | tests/test_n.py::test_n | Verified |"
  echo
  echo "## Coverage Summary"
  echo
  echo "| Metric | Count |"
  echo "| --- | --- |"
  echo "| Total requirements | 2 |"
  echo "| Verified | 2 |"
} > "$matrix"

run_check "$reqs" "$matrix"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(9): expected exit 0 across multiple tables, got $status"; exit 1; }
echo "$output" | grep -q "OK       FR-001" || { echo "FAIL(9): FR-001 not parsed from Functional table"; exit 1; }
echo "$output" | grep -q "OK       NFR-001" || { echo "FAIL(9): NFR-001 not parsed from Non-Functional table"; exit 1; }
echo "$output" | grep -qi "Total requirements" && { echo "FAIL(9): Coverage Summary row parsed as a requirement"; exit 1; }
echo "SUCCESS(9): multiple tables parse and the summary table is ignored."

echo "ALL TESTS PASSED"
