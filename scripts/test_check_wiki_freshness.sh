#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_wiki_freshness.sh
#
# Covers the cases the constitution requires of governance tooling (TESTING.md,
# "Governance Tooling Must Be Tested") and, above all, the property that gives
# this checker a reason to exist separate from check_doc_freshness.sh: only
# ADDING or REMOVING source files trips it, while modifying files does not.
# A checker that fired on every change would just be a noisier doc-freshness.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_wiki_freshness.sh"

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

# Build a small git repo with an initial commit that already has a wiki page
# and one source file.
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
    mkdir -p wiki
    echo "# Home" > wiki/Home.md
    echo "console.log('start')" > app.js
    git add -A
    git commit -q -m "Initial commit"
  )
}

# ---------------------------------------------------------------------------
# 1. A source file ADDED, wiki untouched -> warn, exit 0; --strict -> exit 1,
#    message names the added file.
# ---------------------------------------------------------------------------
repo="$test_dir/1"
make_repo "$repo"
(
  cd "$repo"
  echo "export const x = 1" > feature.js
  git add -A
  git commit -q -m "Add feature.js"
)

run_check --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 by default, got $status"; exit 1; }
echo "$output" | grep -q "feature.js" || { echo "FAIL(1): feature.js not named as the offending addition"; exit 1; }

run_check --strict --base HEAD~1 --head HEAD "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(1): expected exit 1 under --strict, got $status"; exit 1; }
echo "SUCCESS(1): adding a source file with no wiki update warns by default, fails under --strict."

# ---------------------------------------------------------------------------
# 2. A source file ADDED and the wiki also updated in the same diff -> exit 0
#    even under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/2"
make_repo "$repo"
(
  cd "$repo"
  echo "export const x = 1" > feature.js
  echo "# Home (updated)" > wiki/Home.md
  git add -A
  git commit -q -m "Add feature.js and update the wiki"
)

run_check --strict --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2): expected exit 0 when the wiki was also touched, got $status"; exit 1; }
echo "SUCCESS(2): adding a source file alongside a wiki update passes even under --strict."

# ---------------------------------------------------------------------------
# 3. An existing source file only MODIFIED (no add/remove), wiki untouched ->
#    exit 0 even under --strict. This is the defining difference from
#    check_doc_freshness.sh: modifications do not trip this checker.
# ---------------------------------------------------------------------------
repo="$test_dir/3"
make_repo "$repo"
(
  cd "$repo"
  echo "console.log('changed')" > app.js
  git add -A
  git commit -q -m "Modify app.js in place"
)

run_check --strict --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected exit 0 for modify-only change, got $status"; exit 1; }
echo "$output" | grep -q "No files added or removed" || { echo "FAIL(3): modify-only change should report no structural change"; exit 1; }
echo "SUCCESS(3): modifying an existing file does not trip the checker, even under --strict."

# ---------------------------------------------------------------------------
# 4. A source file DELETED, wiki untouched -> warn/strict-fail. Proves
#    deletions count as structural change, not just additions.
# ---------------------------------------------------------------------------
repo="$test_dir/4"
make_repo "$repo"
(
  cd "$repo"
  git rm -q app.js
  git commit -q -m "Remove app.js"
)

run_check --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(4): expected exit 0 by default, got $status"; exit 1; }
echo "$output" | grep -q "app.js" || { echo "FAIL(4): deleted app.js not named"; exit 1; }
run_check --strict --base HEAD~1 --head HEAD "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 under --strict for a deletion, got $status"; exit 1; }
echo "SUCCESS(4): removing a source file trips the checker like an addition does."

# ---------------------------------------------------------------------------
# 5. Only ignore-listed files added (a test file and a docs/ file), wiki
#    untouched -> exit 0 even under --strict. Proves the ignore list actually
#    suppresses false positives.
# ---------------------------------------------------------------------------
repo="$test_dir/5"
make_repo "$repo"
(
  cd "$repo"
  mkdir -p docs
  echo "notes" > docs/NOTES.md
  echo "test body" > test_feature.js
  echo '{"lockfileVersion": 3}' > package-lock.json
  git add -A
  git commit -q -m "Add only ignore-listed files"
)

run_check --strict --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(5): expected exit 0 for ignore-listed-only additions, got $status"; exit 1; }
echo "$output" | grep -q "No files added or removed" || { echo "FAIL(5): ignore list should suppress test/docs/lockfile additions"; exit 1; }
echo "SUCCESS(5): added test files, docs/, and lockfiles are ignored, even under --strict."

# ---------------------------------------------------------------------------
# 6. Custom --wiki-dir is honored: a page added under the custom dir counts as
#    "wiki touched", so an added source file does not trip the check.
# ---------------------------------------------------------------------------
repo="$test_dir/6"
make_repo "$repo"
(
  cd "$repo"
  mkdir -p documentation/wiki
  echo "# Home" > documentation/wiki/Home.md
  echo "export const y = 2" > feature.js
  git add -A
  git commit -q -m "Add feature.js and a page under a custom wiki dir"
)

run_check --strict --wiki-dir documentation/wiki --base HEAD~1 --head HEAD "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(6): expected exit 0 when the custom wiki dir was touched, got $status"; exit 1; }
echo "SUCCESS(6): --wiki-dir is honored when deciding whether the wiki was touched."

# ---------------------------------------------------------------------------
# 7. Usage error (missing --base/--head) -> exit 2.
# ---------------------------------------------------------------------------
run_check "$test_dir/1"
echo "$output"
[ "$status" -eq 2 ] || { echo "FAIL(7): expected exit 2 when --base/--head are missing, got $status"; exit 1; }
echo "SUCCESS(7): usage errors report exit 2."

echo
echo "All check_wiki_freshness.sh tests passed."
