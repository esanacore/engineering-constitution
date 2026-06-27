#!/usr/bin/env bash
set -euo pipefail

# Verify that every requirement ID declared in a product requirements document
# has a verifying-test entry in the requirements traceability matrix.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
# The checker matches requirement IDs by exact cell value, never by substring, so
# a layered ID such as BB-FR-007 can never satisfy a check for the system-layer
# ID FR-007. See constitution DOCUMENTATION.md, "Requirement ID Grammars Must Not
# Collide".
#
# Exit status:
#   0  every declared requirement maps to a non-empty verifying-test entry
#   1  at least one requirement has no matrix row, or only a gap entry
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_traceability.sh [product-requirements] [traceability-matrix]

Description:
  Confirm that every requirement ID declared in the product requirements file
  has a verifying-test entry in the traceability matrix.

Arguments:
  product-requirements   Path to the product requirements file.
                         Default: docs/PRODUCT_REQUIREMENTS.md
  traceability-matrix    Path to the traceability matrix file.
                         Default: docs/REQUIREMENTS_TRACEABILITY.md

Requirement IDs are read from bold declarations in the product requirements
file (for example **FR-001** or **BB-FR-001**). A matrix row covers an ID only
when its Requirement ID cell equals that ID exactly and its Verifying Tests cell
is populated with something other than a gap marker (empty, "none", "GAP",
"TBD", "N/A", "-", or an unfilled <placeholder>).
USAGE
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

reqs=${1:-docs/PRODUCT_REQUIREMENTS.md}
matrix=${2:-docs/REQUIREMENTS_TRACEABILITY.md}

if [ ! -f "$reqs" ]; then
  echo "Product requirements file not found: $reqs" >&2
  exit 2
fi

if [ ! -f "$matrix" ]; then
  echo "Traceability matrix file not found: $matrix" >&2
  exit 2
fi

# Requirement IDs are the bold declarations in the product requirements file.
# Acceptance-criteria sub-IDs (for example `FR-001-AC-1`) appear in backticks,
# not bold, so they are intentionally excluded. Extraction is exact: the ID is
# whatever sits between the ** markers.
required_ids=$(
  grep -oE '\*\*[A-Z][A-Z0-9]*(-[A-Z0-9]+)*-[0-9]+\*\*' "$reqs" 2>/dev/null \
    | sed 's/\*\*//g' \
    | sort -u || true
)

if [ -z "$required_ids" ]; then
  echo "No requirement IDs declared in $reqs; nothing to verify."
  exit 0
fi

# Parse the matrix into "<id>\t<verifying-tests-cell>" lines. Columns are located
# by header name so the checker tolerates extra or reordered columns and multiple
# tables (for example separate Functional and Non-Functional sections). Matching
# is by exact cell value, which is inherently anchored on both sides.
parsed=$(
  awk '
    function trim(s) {
      gsub(/^[ \t]+|[ \t]+$/, "", s)
      gsub(/`/, "", s)
      return s
    }
    # Emit the buffered row if it is a data row of an active (Requirement ID)
    # table. A table is only active between a header that names "Requirement ID"
    # and the end of that table, so unrelated tables (for example a Coverage
    # Summary) are skipped rather than parsed with stale column indices.
    function flush() {
      if (havep && active && idcol > 0 && idcol <= prevn) {
        id = prev[idcol]
        v = (vcol > 0 && vcol <= prevn) ? prev[vcol] : ""
        if (id != "") print id "\t" v
      }
    }
    {
      if ($0 ~ /^[ \t]*\|/) {
        n = split($0, f, "|")
        curn = 0
        for (i = 2; i < n; i++) { curn++; cur[curn] = trim(f[i]) }

        if (curn >= 1 && cur[1] ~ /^:?-+:?$/) {
          # Separator row: the buffered row above it is this table'\''s header.
          idcol = 0; vcol = 0; active = 0
          if (havep) {
            for (i = 1; i <= prevn; i++) {
              if (prev[i] == "Requirement ID") { idcol = i; active = 1 }
              else if (prev[i] == "Verifying Tests") vcol = i
            }
          }
          havep = 0
          next
        }

        # A normal table row: the previously buffered row (if any) was a data
        # row, so emit it before buffering this one.
        flush()
        prevn = curn
        for (i = 1; i <= curn; i++) prev[i] = cur[i]
        havep = 1
        next
      }
      # Any non-table line ends the current table; flush the last data row.
      flush()
      havep = 0
    }
    END { flush() }
  ' "$matrix"
)

# Load the matrix rows into an associative map of ID -> verifying-tests cell.
declare -A coverage
matrix_ids=()
if [ -n "$parsed" ]; then
  while IFS=$'\t' read -r id verifying; do
    [ -z "$id" ] && continue
    coverage["$id"]="$verifying"
    matrix_ids+=("$id")
  done <<< "$parsed"
fi

# A verifying-tests cell counts as a gap when it is empty or a known placeholder.
is_gap() {
  local raw lc
  raw=$(printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ -z "$raw" ] && return 0
  lc=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')
  case "$lc" in
    none*|gap*|tbd*|n/a|-) return 0 ;;
  esac
  case "$lc" in
    *gap*|*"<"*">"*) return 0 ;;
  esac
  return 1
}

failures=0
covered=0
echo "Requirement coverage ($reqs -> $matrix):"
while IFS= read -r id; do
  [ -z "$id" ] && continue
  if [ -z "${coverage[$id]+set}" ]; then
    echo "  MISSING  $id has no row in the traceability matrix"
    failures=$((failures + 1))
  elif is_gap "${coverage[$id]}"; then
    echo "  GAP      $id has no verifying test (\"${coverage[$id]}\")"
    failures=$((failures + 1))
  else
    echo "  OK       $id -> ${coverage[$id]}"
    covered=$((covered + 1))
  fi
done <<< "$required_ids"

# Surface matrix rows that reference IDs the requirements file does not declare.
# These are informational and never fail the check on their own.
required_set=" $(printf '%s ' $required_ids)"
orphans=()
for id in "${matrix_ids[@]:-}"; do
  [ -z "$id" ] && continue
  case "$required_set" in
    *" $id "*) ;;
    *) orphans+=("$id") ;;
  esac
done
if [ "${#orphans[@]}" -gt 0 ]; then
  echo
  echo "Note: matrix rows with no matching declared requirement:"
  printf '  - %s\n' $(printf '%s\n' "${orphans[@]}" | sort -u)
fi

total=$(printf '%s\n' "$required_ids" | grep -c . || true)
echo
echo "Checked $total requirement(s); $covered covered, $failures gap(s)/missing."

if [ "$failures" -gt 0 ]; then
  exit 1
fi
exit 0
