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

run_check --bogus "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected unknown option to exit 2, got $status"; exit 1; }

run_check "$test_dir/does-not-exist"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected missing root to exit 2, got $status"; exit 1; }
echo "SUCCESS(5): usage errors report exit 2."

echo "ALL TESTS PASSED"
