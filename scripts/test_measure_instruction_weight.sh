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
echo "$output" | grep -q 'tok  HEAVY' || fail "case 5: HEAVY flag absent for 40KB file"
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

# ---------------------------------------------------------------------------
# 10. A scoped TODO bullet ("open items") measures only open items and their
#     continuation lines; completed items are dropped; both totals appear.
# ---------------------------------------------------------------------------
repo="$test_dir/10"; mkdir -p "$repo"
pad=$(head -c 2000 /dev/zero | tr '\0' 'x')
cat > "$repo/TODO.md" <<EOF
# TODO

## Features

- [ ] open one
  continuation of open one
  - [ ] open sub-item
  - [x] done sub-item $pad
- [x] done one $pad
  continuation of done one $pad
- [~] in progress
EOF
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history, read on demand
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 10: expected exit 0, got $status"
row=$(echo "$output" | grep 'TODO.md \[open items\]') || fail "case 10: no scoped TODO row"
scoped=$(echo "$row" | sed -E 's/.*~ *([0-9]+) tok .*\(of ~([0-9]+) tok whole file\).*/\1/')
whole=$(echo "$row" | sed -E 's/.*~ *([0-9]+) tok .*\(of ~([0-9]+) tok whole file\).*/\2/')
[ "$scoped" -lt 60 ] || fail "case 10: scoped figure $scoped tok should exclude the 6000 bytes of completed items"
[ "$whole" -gt 1500 ] || fail "case 10: whole-file figure $whole tok is implausible"
echo "$output" | grep -q 'TOTAL (as instructed)' || fail "case 10: no as-instructed total"
echo "$output" | grep -q 'TOTAL (whole files)' || fail "case 10: no whole-files total"
echo "PASS: open-items scope measured as instructed"

# ---------------------------------------------------------------------------
# 11. A scoped CHANGELOG bullet measures Unreleased + the latest release only:
#     a huge older section no longer makes the file HEAVY.
# ---------------------------------------------------------------------------
repo="$test_dir/11"; mkdir -p "$repo"
{
  printf '# Changelog\n\n## Unreleased\n\n- pending\n\n## 1.2.0 - 2026-01-02\n\n- latest\n\n## 1.1.0 - 2026-01-01\n\n'
  head -c 40000 /dev/zero | tr '\0' 'y'; printf '\n'
} > "$repo/CHANGELOG.md"
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `CHANGELOG.md` — the `Unreleased` section and the most recent release; older sections are history, read on demand
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 11: expected exit 0, got $status"
echo "$output" | grep -q 'CHANGELOG.md \[Unreleased + latest release\]' || fail "case 11: no scoped CHANGELOG row"
echo "$output" | grep -q 'tok  HEAVY' && fail "case 11: the instructed read is tiny; HEAVY must judge the scoped figure"
scoped=$(echo "$output" | grep 'CHANGELOG.md \[' | sed -E 's/.*~ *([0-9]+) tok .*\(of ~([0-9]+) tok whole file\).*/\1/')
[ "$scoped" -lt 40 ] || fail "case 11: scoped figure $scoped tok includes the old section"
echo "PASS: Unreleased + latest release scope measured as instructed"

# ---------------------------------------------------------------------------
# 12. Without an Unreleased section, "latest release" is the first section;
#     an unrecognized qualifier measures the whole file (no scoped row).
# ---------------------------------------------------------------------------
repo="$test_dir/12"; mkdir -p "$repo"
{
  printf '# Changelog\n\n## 1.2.0 - 2026-01-02\n\n- latest\n\n## 1.1.0 - 2026-01-01\n\n'
  head -c 40000 /dev/zero | tr '\0' 'y'; printf '\n'
} > "$repo/CHANGELOG.md"
printf 'doc\n' > "$repo/OTHER.md"
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `CHANGELOG.md` — the `Unreleased` section and the most recent release
- `OTHER.md` — skim the bits that matter
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 12: expected exit 0, got $status"
echo "$output" | grep -q 'tok  HEAVY' && fail "case 12: without Unreleased the first section alone is the instructed read"
echo "$output" | grep -q 'OTHER.md \[' && fail "case 12: an unrecognized qualifier must not produce a scoped row"
echo "$output" | grep -qE '^  OTHER.md +[0-9]+ B' || fail "case 12: OTHER.md not measured whole"
echo "PASS: no-Unreleased fallback and unrecognized qualifiers"

# ---------------------------------------------------------------------------
# 13. Dogfood: this repository's own reading order has both scoped rows.
# ---------------------------------------------------------------------------
run "$script_dir/.."
[ "$status" -eq 0 ] || fail "case 13: the repository's own reading order failed to measure"
echo "$output" | grep -q 'TODO.md \[open items\]' || fail "case 13: TODO.md is not measured as open items"
echo "$output" | grep -q 'CHANGELOG.md \[Unreleased + latest release\]' || fail "case 13: CHANGELOG.md is not measured as Unreleased + latest"
echo "PASS: repository reading order measured as instructed"

# ---------------------------------------------------------------------------
# 14. Regressions from the critique pass: loose qualifiers must not scope;
#     a `## ` inside a fence is not a section; Unreleased need not be first;
#     an open child under a completed parent does not re-open the parent's
#     notes; a fence inside an open item is kept whole; prose after a
#     completed item is kept; a duplicate listing keeps its scope either way.
# ---------------------------------------------------------------------------
repo="$test_dir/14"; mkdir -p "$repo"
printf 'ab\n' > "$repo/FOO.md"
printf 'cd\n' > "$repo/NOTES.md"
pad=$(head -c 2000 /dev/zero | tr '\0' 'x')
{
  printf '# Changelog\n\n## 1.2.0 - 2026-01-02\n\n- latest\n\n## Unreleased\n\n- pending\n\n```md\n## 9.9.9 not a section\n```\n\n## 1.1.0 - 2026-01-01\n\n'
  printf '%s\n' "$pad"
} > "$repo/CHANGELOG.md"
cat > "$repo/TODO.md" <<EOF
# TODO

Preamble prose stays.

- [x] done parent $pad
  - [ ] open child
  continuation of the done parent $pad
- [ ] open item
  \`\`\`bash
  - [x] looks like a checkbox but is code
  echo kept
  \`\`\`
- [x] done again $pad

Prose after a completed item stays.
EOF
cat > "$repo/CLAUDE.md" <<'EOF'
## Required Reading

- `FOO.md` — open items you own
- `NOTES.md` — the unreleased ideas and the latest release notes
- `CHANGELOG.md` — the `Unreleased` section and the most recent release
- `TODO.md`
- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history
EOF
run "$repo"
[ "$status" -eq 0 ] || fail "case 14: expected exit 0, got $status"
echo "$output" | grep -q 'FOO.md \[' && fail "case 14: 'open items you own' must not scope"
echo "$output" | grep -q 'NOTES.md \[' && fail "case 14: 'unreleased ideas ... latest release notes' must not scope"
echo "$output" | grep -qE '^  FOO.md +3 B' || fail "case 14: FOO.md not measured whole"
row=$(echo "$output" | grep 'CHANGELOG.md \[Unreleased + latest release\]') || fail "case 14: no scoped CHANGELOG row"
scoped=$(echo "$row" | sed -E 's/.*~ *([0-9]+) tok .*\(of ~([0-9]+) tok whole file\).*/\1/')
[ "$scoped" -lt 60 ] || fail "case 14: CHANGELOG scoped figure $scoped tok includes the old section (fence or ordering misread)"
[ "$scoped" -gt 20 ] || fail "case 14: CHANGELOG scoped figure $scoped tok dropped Unreleased or the latest release"
row=$(echo "$output" | grep 'TODO.md \[open items\]') || fail "case 14: no scoped TODO row (the scope on the second listing must win)"
count=$(echo "$output" | grep -c 'TODO.md' || true)
[ "$count" -eq 1 ] || fail "case 14: TODO.md reported $count times, expected 1"
scoped=$(echo "$row" | sed -E 's/.*~ *([0-9]+) tok .*\(of ~([0-9]+) tok whole file\).*/\1/')
[ "$scoped" -lt 80 ] || fail "case 14: TODO scoped figure $scoped tok leaks a completed parent's continuation"
[ "$scoped" -gt 30 ] || fail "case 14: TODO scoped figure $scoped tok dropped the preamble, the fenced code, or the trailing prose"
echo "PASS: critique-pass regressions"

echo
echo "All measure_instruction_weight tests passed."
