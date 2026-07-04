#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_doc_freshness.sh
#
# Covers the negative cases the constitution requires of governance tooling
# (TESTING.md, "Governance Tooling Must Be Tested"): a diff that changes
# source but never touches README.md/CHANGELOG.md must be flagged, and the
# ignore list must actually suppress false positives rather than flag
# everything indiscriminately.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_doc_freshness.sh"

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

# Build a small git repo with an initial commit, return its path via echo.
make_repo() {
  local dest=$1
  mkdir -p "$dest"
  (
    cd "$dest"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "# Project" > README.md
    echo "# Changelog" > CHANGELOG.md
    mkdir -p docs
    echo "notes" > docs/NOTES.md
    git add -A
    git commit -q -m "Initial commit"
  )
}

# ---------------------------------------------------------------------------
# 1. Source file changed, README/CHANGELOG untouched -> warn, exit 0;
#    --strict -> exit 1, message names the changed file.
# ---------------------------------------------------------------------------
repo="$test_dir/1"
make_repo "$repo"
(
  cd "$repo"
  echo "console.log('hi')" > app.js
  git add -A
  git commit -q -m "Add app.js"
)

run_check --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 by default, got $status"; exit 1; }
echo "$output" | grep -q "app.js" || { echo "FAIL(1): app.js not named as the offending change"; exit 1; }

run_check --strict --base HEAD~1 --head HEAD "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(1): expected exit 1 under --strict, got $status"; exit 1; }
echo "SUCCESS(1): source change with no doc update warns by default, fails under --strict."

# ---------------------------------------------------------------------------
# 2. Source file changed, README.md also touched in the same diff -> exit 0
#    even under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/2"
make_repo "$repo"
(
  cd "$repo"
  echo "console.log('hi')" > app.js
  echo "# Project (updated)" > README.md
  git add -A
  git commit -q -m "Add app.js and update README"
)

run_check --strict --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2): expected exit 0 when README was also touched, got $status"; exit 1; }
echo "SUCCESS(2): source change alongside a README update passes even under --strict."

# ---------------------------------------------------------------------------
# 3. Only ignore-listed paths changed (lockfile, docs/) -> exit 0 even under
#    --strict. Proves the ignore list actually suppresses false positives.
# ---------------------------------------------------------------------------
repo="$test_dir/3"
make_repo "$repo"
(
  cd "$repo"
  echo '{"lockfileVersion": 2}' > package-lock.json
  echo "more notes" > docs/NOTES.md
  git add -A
  git commit -q -m "Update lockfile and docs notes only"
)

run_check --strict --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected exit 0 for ignore-listed-only changes, got $status"; exit 1; }
echo "$output" | grep -q "No doc-worthy source changes" || { echo "FAIL(3): expected the ignore list to suppress everything"; exit 1; }
echo "SUCCESS(3): lockfile and docs/-only changes are ignored, even under --strict."

# ---------------------------------------------------------------------------
# 4. Usage error (missing --base/--head) -> exit 2.
# ---------------------------------------------------------------------------
run_check "$test_dir/1"
echo "$output"
[ "$status" -eq 2 ] || { echo "FAIL(4): expected exit 2 when --base/--head are missing, got $status"; exit 1; }
echo "SUCCESS(4): usage errors report exit 2."

echo
echo "All check_doc_freshness.sh tests passed."
