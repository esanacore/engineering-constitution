#!/usr/bin/env bash
set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_product_discovery.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
root="$tmp/project"
mkdir -p "$root/docs/discovery"
count=0
fail() { echo "FAIL: $*"; exit 1; }
fixture() {
  cat > "$root/docs/PRODUCT_REQUIREMENTS.md" <<'DOC'
# Requirements
Intent revision: 2
**FR-001** A required behavior.
**NFR-002** A constraint.
- `FR-001-AC-1` is an acceptance criterion, not another declaration.
DOC
  hash=$(git -C "$root" hash-object --no-filters -- docs/PRODUCT_REQUIREMENTS.md)
  cat > "$root/docs/discovery/REVIEW.md" <<DOC
# Discovery review
Intent revision: 2
Requirements hash: $hash
Lifecycle: Draft
Product approval: Pending
Product approval revision: 2
Product approval hash: $hash
Product approval reviewer: -
Product approval evidence: -
Engineering readiness: Pending
Engineering readiness revision: 2
Engineering readiness hash: $hash
Engineering readiness reviewer: -
Engineering readiness evidence: -

## Unknowns
| ID | Kind | Status | Owner | Review date | Resolution |
| --- | --- | --- | --- | --- | --- |
| U-001 | blocker | open | Taylor | 2026-11-02 | - |

## Changed requirement evidence
| Requirement ID | Evidence status | Evidence reference |
| --- | --- | --- |
| FR-001 | pending | - |
DOC
}
replace() {
  sed "$1" "$root/docs/discovery/REVIEW.md" > "$tmp/edited"
  mv "$tmp/edited" "$root/docs/discovery/REVIEW.md"
}
run() {
  expected=$1; pattern=$2; shift 2
  status=0; out=$(bash "$checker" "$@" 2>&1) || status=$?
  [ "$status" -eq "$expected" ] || fail "expected exit $expected, got $status: $out"
  case "$out" in *"$pattern"*) ;; *) fail "missing '$pattern': $out" ;; esac
  count=$((count+1)); echo "PASS $count: $pattern"
}
retirement_cases() {
  fixture
  sed '/^\*\*FR-001\*\*/d' "$root/docs/PRODUCT_REQUIREMENTS.md" > "$tmp/requirements"
  mv "$tmp/requirements" "$root/docs/PRODUCT_REQUIREMENTS.md"
  run 1 'unknown requirement FR-001' --strict "$root"
  fixture
  awk '/^\*\*FR-001\*\*/ { print "**FR-001** WON\047T: retired in revision 2; rationale: no longer needed."; next } { print }' "$root/docs/PRODUCT_REQUIREMENTS.md" > "$tmp/requirements"
  mv "$tmp/requirements" "$root/docs/PRODUCT_REQUIREMENTS.md"
  new_hash=$(sed $'s/\r$//' "$root/docs/PRODUCT_REQUIREMENTS.md" | git -C "$root" hash-object --stdin)
  replace "s/$hash/$new_hash/g"
  run 0 'No structural or freshness findings' --strict "$root"
}
if [ "${1:-}" = '--focused' ]; then
  retirement_cases
  echo "FOCUSED TESTS PASSED ($count)"
  exit 0
fi
fixture
run 0 'No structural or freshness findings' --strict "$root"
# A checkout with CRLF represents the same normalized requirements as LF.
awk '{printf "%s\r\n", $0}' "$root/docs/PRODUCT_REQUIREMENTS.md" > "$tmp/crlf"
mv "$tmp/crlf" "$root/docs/PRODUCT_REQUIREMENTS.md"
run 0 'No structural or freshness findings' --strict "$root"
# An incomplete package warns normally and fails strictly.
printf '\nChanged requirements.\n' >> "$root/docs/PRODUCT_REQUIREMENTS.md"
run 0 'Requirements hash is stale' "$root"
run 1 'Requirements hash is stale' --strict "$root"
fixture
replace 's/^Intent revision: 2$/Intent revision: 3/'
run 1 'Intent revision is stale' --strict "$root"
fixture
replace 's/^Product approval revision: 2$/Product approval revision: 1/'
run 1 'Product approval revision is stale' --strict "$root"
fixture
replace 's/^Engineering readiness hash: .*/Engineering readiness hash: deadbeef/'
run 1 'Engineering readiness hash is stale' --strict "$root"
fixture
printf '\nLifecycle: Draft\n' >> "$root/docs/discovery/REVIEW.md"
run 1 'exactly one Lifecycle' --strict "$root"
fixture
printf '\n**FR-001** Duplicate.\n' >> "$root/docs/PRODUCT_REQUIREMENTS.md"
run 1 'duplicate requirement declaration FR-001' --strict "$root"
fixture
replace '/| U-001 |/a\
| U-001 | metric | open | Pat | 2026-11-03 | - |'
run 1 'duplicate unknown ID U-001' --strict "$root"
fixture
replace '/| FR-001 | pending/a\
| FR-001 | reassessed | report-2 |'
run 1 'duplicate changed requirement ID FR-001' --strict "$root"
fixture
replace 's/| FR-001 | pending/| FR-999 | pending/'
run 1 'unknown requirement FR-999' --strict "$root"
fixture
replace 's/| blocker | open |/| hypothesis | open |/'
run 1 'invalid kind' --strict "$root"
fixture
replace 's/| blocker | open |/| blocker | resolved |/'
run 1 'resolved item needs a resolution' --strict "$root"
fixture
replace 's/^Lifecycle: Draft$/Lifecycle: Approved/; s/^Product approval: Pending$/Product approval: Approved/'
run 1 'needs a named reviewer' --strict "$root"
run 1 'Approved or Ready review has open blockers' --strict "$root"
run 1 'Approved or Ready review has pending changed requirement evidence' --strict "$root"
fixture
replace 's/^Engineering readiness: Pending$/Engineering readiness: Ready/; s/^Engineering readiness reviewer: -$/Engineering readiness reviewer: Morgan/; s/^Engineering readiness evidence: -$/Engineering readiness evidence: review-17/'
run 1 'Approved or Ready review has open blockers' --strict "$root"
fixture
replace 's/^Lifecycle: Draft$/Lifecycle: Approved/; s/^Product approval: Pending$/Product approval: Approved/; s/^Product approval reviewer: -$/Product approval reviewer: Taylor/; s/^Product approval evidence: -$/Product approval evidence: decision-42/; s/| blocker | open | Taylor | 2026-11-02 | - |/| blocker | resolved | Taylor | 2026-11-02 | decision-42 |/; s/| FR-001 | pending | - |/| FR-001 | reassessed | review-17 |/'
run 0 'No structural or freshness findings' --strict "$root"
replace 's/| FR-001 | reassessed | review-17 |/| FR-001 | reassessed | TBD |/'
run 1 'reassessed needs an evidence reference' --strict "$root"
fixture
replace 's/| ID | Kind | Status | Owner | Review date | Resolution |/| ID | Kind | Status | Owner | Review date |/'
run 1 'invalid header' --strict "$root"
fixture
replace 's/^| --- | --- | --- | --- | --- | --- |$/| nope | nope | nope | nope | nope | nope |/'
run 1 'invalid table separator' --strict "$root"
fixture
printf '\n```\nLifecycle: Approved\n```\n' >> "$root/docs/discovery/REVIEW.md"
run 0 'No structural or freshness findings' --strict "$root"
fixture
# Hidden comments cannot create a visible approval or a duplicate record.
printf '\n<!--\nLifecycle: Approved\n-->\n' >> "$root/docs/discovery/REVIEW.md"
run 0 'No structural or freshness findings' --strict "$root"
awk '/^Product approval reviewer: -$/ { print "<!--"; print; print "-->"; next } { print }' "$root/docs/discovery/REVIEW.md" > "$tmp/edited"
mv "$tmp/edited" "$root/docs/discovery/REVIEW.md"
run 1 'exactly one Product approval reviewer' --strict "$root"
fixture
run 2 'Unknown option' --invalid
run 0 'Usage:' --help
rm "$root/docs/discovery/REVIEW.md"
run 0 'skipped' "$root"
run 1 'No optional discovery review' --strict "$root"
fixture
rm "$root/docs/PRODUCT_REQUIREMENTS.md"
run 1 'PRODUCT_REQUIREMENTS.md is missing' --strict "$root"
retirement_cases
echo "ALL TESTS PASSED ($count)"