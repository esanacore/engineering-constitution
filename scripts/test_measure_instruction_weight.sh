#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/measure_instruction_weight.sh
#
# Covers the cases the constitution requires of governance tooling
# (TESTING.md, "Governance Tooling Must Be Tested"), and the two properties
# that define this tool: it measures only the reading sections (bullets in
# checklists elsewhere must not count), and it is a meter, not a gate (the
# HEAVY advisory never fails; only a listed-but-missing file does).

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
measure="$script_dir/measure_instruction_weight.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() { rm -rf "$test_dir"; }
trap cleanup EXIT

run() {
  set +e
  output=$("$measure" "$@" 2>&1)
  status=$?
  set -e
}

fail() { echo "FAIL: $1"; echo "---- output ----"; echo "$output"; exit 1; }

# ---------------------------------------------------------------------------
# 1. Reading section measured: two listed files reported with a TOTAL, exit 0.
# ---------------------------------------------------------------------------
repo="$test_dir/1"; mkdir -p "$repo"
printf 'alpha content here\n' > "$repo/A.md"
printf 'beta content that is a little longer\n' > "$repo/B.md"
cat > "$repo/CLAUDE.md" <<'EOF'
# CLAUDE.md

## Required Reading

- `A.md`
- `B.md`
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 1: expected exit 0, got $status"
echo "$output" | grep -q "A.md" || fail "case 1: A.md not reported"
echo "$output" | grep -q "B.md" || fail "case 1: B.md not reported"
echo "$output" | grep -q "TOTAL" || fail "case 1: no TOTAL line"
echo "PASS: reading section measured with total"

# ---------------------------------------------------------------------------
# 2. Listed file missing -> MISSING line and exit 1 (broken reading order).
# ---------------------------------------------------------------------------
repo="$test_dir/2"; mkdir -p "$repo"
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `GONE.md`
EOF
run "$repo"
[ "$status" -eq 1 ] || fail "case 2: expected exit 1, got $status"
echo "$output" | grep -q "MISSING.*GONE.md" || fail "case 2: missing file not named"
echo "PASS: missing listed file fails"

# ---------------------------------------------------------------------------
# 3. Bullets outside reading sections are not counted; AGENTS.md
#    "Before Beginning Work" section is.
# ---------------------------------------------------------------------------
repo="$test_dir/3"; mkdir -p "$repo"
printf 'doc\n' > "$repo/READ_ME_AGENT.md"
printf 'doc\n' > "$repo/CHECKLIST_ONLY.md"
cat > "$repo/AGENTS.md" <<'EOF'
# AGENTS.md

## Before Beginning Work

Read:

- `READ_ME_AGENT.md`

## Completion Checklist

- Update `CHECKLIST_ONLY.md` when needed.
- `CHECKLIST_ONLY.md`
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 3: expected exit 0, got $status"
echo "$output" | grep -q "READ_ME_AGENT.md" || fail "case 3: reading-section file not measured"
echo "$output" | grep -q "CHECKLIST_ONLY.md" && fail "case 3: checklist bullet was wrongly counted"
echo "PASS: only reading sections are counted"

# ---------------------------------------------------------------------------
# 4. --files explicit mode measures exactly the named files.
# ---------------------------------------------------------------------------
repo="$test_dir/4"; mkdir -p "$repo"
printf 'one\n' > "$repo/one.md"
printf 'two two\n' > "$repo/two.md"
( cd "$repo" && set +e; out=$("$measure" --files one.md two.md 2>&1); st=$?; set -e
  [ "$st" -eq 0 ] || { echo "FAIL: case 4 exit $st"; echo "$out"; exit 1; }
  echo "$out" | grep -q "one.md" || { echo "FAIL: case 4 one.md missing"; exit 1; }
  echo "$out" | grep -q "two.md" || { echo "FAIL: case 4 two.md missing"; exit 1; } )
echo "PASS: explicit --files mode"

# ---------------------------------------------------------------------------
# 5. HEAVY advisory flags a large file but does not fail.
# ---------------------------------------------------------------------------
repo="$test_dir/5"; mkdir -p "$repo"
head -c 40000 /dev/zero | tr '\0' 'x' > "$repo/BIG.md"
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `BIG.md`
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 5: HEAVY advisory must not fail (got $status)"
echo "$output" | grep -q "HEAVY" || fail "case 5: HEAVY flag absent for 40KB file"
echo "PASS: heavy file flagged, run still succeeds"

# ---------------------------------------------------------------------------
# 6. Duplicate entries within one reading list are measured once.
# ---------------------------------------------------------------------------
repo="$test_dir/6"; mkdir -p "$repo"
printf 'dup\n' > "$repo/DUP.md"
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `DUP.md`
- `DUP.md`
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 6: expected exit 0, got $status"
count=$(echo "$output" | grep -c "DUP.md" || true)
[ "$count" -eq 1 ] || fail "case 6: DUP.md reported $count times, expected 1"
echo "PASS: duplicates deduplicated"

# ---------------------------------------------------------------------------
# 7. Usage errors: unknown option, and --files with no files -> exit 2.
# ---------------------------------------------------------------------------
run --bogus
[ "$status" -eq 2 ] || fail "case 7a: unknown option should exit 2 (got $status)"
run --files
[ "$status" -eq 2 ] || fail "case 7b: bare --files should exit 2 (got $status)"
echo "PASS: usage errors exit 2"

# ---------------------------------------------------------------------------
# 8. No instruction files / no reading sections -> friendly message, exit 0.
# ---------------------------------------------------------------------------
repo="$test_dir/8"; mkdir -p "$repo"
run "$repo"
[ "$status" -eq 0 ] || fail "case 8: expected exit 0, got $status"
echo "$output" | grep -qi "nothing to measure" || fail "case 8: no friendly empty message"
echo "PASS: empty repository handled"

# ---------------------------------------------------------------------------
# 9. Prose-style reading section (the sample-project shape): a plain
#    "Before beginning work, read:" line opens the section, "Before
#    completing work:" closes it.
# ---------------------------------------------------------------------------
repo="$test_dir/9"; mkdir -p "$repo"
printf 'doc\n' > "$repo/PROSE_READ.md"
printf 'doc\n' > "$repo/AFTER.md"
cat > "$repo/AGENTS.md" <<'EOF'
# AGENTS.md

This sample project follows the constitution.

Before beginning work, read:

- `PROSE_READ.md`

Before completing work:

- Update `AFTER.md`.
- `AFTER.md`
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 9: expected exit 0, got $status"
echo "$output" | grep -q "PROSE_READ.md" || fail "case 9: prose-style reading section not parsed"
echo "$output" | grep -q "AFTER.md" && fail "case 9: post-section bullet wrongly counted"
echo "PASS: prose-style reading section parsed"

echo
echo "All measure_instruction_weight tests passed."
