#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_version_alignment.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

make_repo() {
  dest=$1
  mkdir -p "$dest/constitution" "$dest/docs/governance"
  printf '1.25.0\n' > "$dest/constitution/VERSION"
  printf '1.25.0\n' > "$dest/CONSTITUTION_VERSION"
  cat > "$dest/README.md" <<'EOF'
This repository follows Eric's Engineering Constitution version 1.25.0.
EOF
  cat > "$dest/AGENTS.md" <<'EOF'
Pinned to constitution version `1.25.0`.
EOF
  cat > "$dest/docs/governance/ENGINEERING_CONSTITUTION_ALIGNMENT.md" <<'EOF'
Reviewed constitution release: `1.25.0`
EOF
  cat > "$dest/demo.html" <<'EOF'
<span class="badge-text">ERIC'S ENGINEERING CONSTITUTION V1.25.0</span>
EOF
}

run_check() {
  set +e
  output=$("$check_script" "$@" 2>&1)
  status=$?
  set -e
}

repo="$test_dir/aligned"
make_repo "$repo"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected aligned repo to pass, got $status"; exit 1; }
echo "$output" | grep -q "CONSTITUTION_VERSION matches 1.25.0" || { echo "FAIL(1): expected CONSTITUTION_VERSION success"; exit 1; }
echo "SUCCESS(1): aligned repository passes."

repo="$test_dir/mismatch-file"
make_repo "$repo"
printf '1.24.0\n' > "$repo/CONSTITUTION_VERSION"

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected mismatched CONSTITUTION_VERSION to fail, got $status"; exit 1; }
echo "$output" | grep -q "MISMATCH CONSTITUTION_VERSION declares 1.24.0" || { echo "FAIL(2): mismatch not reported"; exit 1; }
echo "SUCCESS(2): mismatched CONSTITUTION_VERSION fails."

repo="$test_dir/mismatch-doc"
make_repo "$repo"
cat > "$repo/docs/governance/ENGINEERING_CONSTITUTION_ALIGNMENT.md" <<'EOF'
Reviewed constitution release: `1.24.0`
EOF

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected stale governance doc reference to fail, got $status"; exit 1; }
echo "$output" | grep -q "docs/governance/ENGINEERING_CONSTITUTION_ALIGNMENT.md:1 mentions 1.24.0" || { echo "FAIL(3): stale doc mismatch not reported"; exit 1; }
echo "SUCCESS(3): stale governance doc reference fails."

repo="$test_dir/missing-version"
make_repo "$repo"
rm "$repo/constitution/VERSION"

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected missing constitution/VERSION to fail, got $status"; exit 1; }
echo "$output" | grep -q "Missing constitution/VERSION" || { echo "FAIL(4): missing constitution/VERSION not reported"; exit 1; }
echo "SUCCESS(4): missing constitution/VERSION fails."

repo="$test_dir/mismatch-demo"
make_repo "$repo"
cat > "$repo/demo.html" <<'EOF'
<span class="badge-text">ERIC'S ENGINEERING CONSTITUTION V1.24.0</span>
EOF

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(6): expected stale demo.html reference to fail, got $status"; exit 1; }
echo "$output" | grep -q "demo.html:1 mentions 1.24.0" || { echo "FAIL(6): stale demo mismatch not reported"; exit 1; }
echo "SUCCESS(6): stale demo.html reference fails."

run_check --bogus "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected unknown option to exit 2, got $status"; exit 1; }

run_check "$test_dir/does-not-exist"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected missing root to exit 2, got $status"; exit 1; }
echo "SUCCESS(5): usage errors report exit 2."

# ---------------------------------------------------------------------------
# docs/AGENT_HANDOFF.md is a log of past sessions (DOCUMENTATION.md: it
# captures "state after work", one entry per session). A version it names is a
# historical fact, not a claim about the current pin, so it is not scanned.
# ---------------------------------------------------------------------------
repo="$test_dir/handoff-history"
make_repo "$repo"
mkdir -p "$repo/docs"
cat > "$repo/docs/AGENT_HANDOFF.md" <<'EOF'
## Last Session — 2026-08-27: Constitution 1.24.0 & keyring integration
- **Scope**: Constitution 1.24.0 alignment.
- **Branch**: `chore/constitution-1.24.0`.
EOF
run_check "$repo"
[ "$status" -eq 0 ] || { echo "$output"; echo "FAIL(7): a historical version in docs/AGENT_HANDOFF.md must not fail, got $status"; exit 1; }
echo "$output" | grep -q "AGENT_HANDOFF" && { echo "$output"; echo "FAIL(7): docs/AGENT_HANDOFF.md must not be scanned"; exit 1; }
echo "SUCCESS(7): docs/AGENT_HANDOFF.md is not scanned."

# ---------------------------------------------------------------------------
# A historical mention inside an otherwise current file opts out per line.
# ---------------------------------------------------------------------------
repo="$test_dir/ignore-marker"
make_repo "$repo"
cat >> "$repo/README.md" <<'EOF'

## History

Adopted the constitution at 1.20.0 in June. <!-- version-alignment:ignore -->
EOF
run_check "$repo"
[ "$status" -eq 0 ] || { echo "$output"; echo "FAIL(8): version-alignment:ignore line must be skipped, got $status"; exit 1; }
echo "$output" | grep -q "1.20.0" && { echo "$output"; echo "FAIL(8): ignored line was still reported"; exit 1; }
echo "SUCCESS(8): a version-alignment:ignore line is skipped."

# Without the marker, that same line must still fail -- the opt-out is explicit,
# not a blanket exemption for anything under a "History" heading.
repo="$test_dir/ignore-marker-absent"
make_repo "$repo"
cat >> "$repo/README.md" <<'EOF'

Adopted the constitution at 1.20.0 in June.
EOF
run_check "$repo"
[ "$status" -eq 1 ] || { echo "$output"; echo "FAIL(8): an unmarked stale mention must still fail, got $status"; exit 1; }
echo "$output" | grep -q "mentions 1.20.0" || { echo "$output"; echo "FAIL(8): unmarked stale mention not reported"; exit 1; }
echo "SUCCESS(8): the opt-out is explicit, not implied."

# ---------------------------------------------------------------------------
# bump_adopters.sh rewrites what this checker scans. If the two lists drift,
# the bump either rewrites something unchecked or misses something checked --
# and the AGENT_HANDOFF case above is exactly what drift would reintroduce.
# ---------------------------------------------------------------------------
checker_set=$(sed -n '/^candidate_files=(/,/^)/p' "$check_script" \
  | sed '1d;$d' | tr -d '[:space:]' | tr ',' ' ')
bump_set=$(grep -oE '^  vr_files="[^"]*"' "$script_dir/bump_adopters.sh" \
  | sed 's/^  vr_files="//; s/"$//' | tr -d '[:space:]')
[ "$checker_set" = "$bump_set" ] || {
  echo "checker: $checker_set"
  echo "bump:    $bump_set"
  echo "FAIL(9): check_version_alignment.sh and bump_adopters.sh scan different files"; exit 1; }
grep -q 'version-alignment:ignore' "$script_dir/bump_adopters.sh" || {
  echo "FAIL(9): bump_adopters.sh does not honour the version-alignment:ignore marker"; exit 1; }
echo "SUCCESS(9): the checker and the bump rewriter scan the same files and share the opt-out."

echo "ALL TESTS PASSED"
