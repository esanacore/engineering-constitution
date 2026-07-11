#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_secrets.sh
#
# Covers the negative cases the constitution requires of governance tooling
# (TESTING.md, "Governance Tooling Must Be Tested"): a real secret-shaped
# filename or content match must always fail, even without --strict; a clean
# repository must pass; a placeholder file (.env.example) must not be
# flagged; an untracked-but-not-ignored file must still be caught; and the
# .gitignore-coverage recommendation must warn by default and fail under
# --strict.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_secrets.sh"

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
# core.excludesFile is neutralized so a developer machine's own global
# gitignore (for example, one that already ignores .env) can never make
# these fixtures non-deterministic.
make_repo() {
  local dest=$1
  mkdir -p "$dest"
  (
    cd "$dest"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config core.excludesFile /dev/null
    echo "# Project" > README.md
    git add -Af
    git commit -q -m "Initial commit"
  )
}

# ---------------------------------------------------------------------------
# 1. A tracked credential-shaped filename (.env) always fails, even without
#    --strict, and the offending path is named in the output.
# ---------------------------------------------------------------------------
repo="$test_dir/1"
make_repo "$repo"
(
  cd "$repo"
  echo "SECRET=x" > .env
  git add -Af
  git commit -q -m "Add .env"
)

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(1): expected exit 1 for a tracked .env, got $status"; exit 1; }
echo "$output" | grep -q "FOUND    .env" || { echo "FAIL(1): .env not named as a hit"; exit 1; }
echo "SUCCESS(1): a tracked .env file always fails, without --strict."

# ---------------------------------------------------------------------------
# 2. A high-confidence content match (AWS access key ID) in a tracked file
#    always fails, even without --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/2"
make_repo "$repo"
(
  cd "$repo"
  # Built from two fragments so this test script's own tracked source never
  # contains the full pattern contiguously -- otherwise check_secrets.sh
  # would flag this very file when the constitution sweeps its own repo.
  echo "aws_key=AKIA""ABCDEFGHIJKLMNOP" > config.txt
  git add -Af
  git commit -q -m "Add config with AWS key"
)

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 for an embedded AWS key, got $status"; exit 1; }
echo "$output" | grep -q "AWS access key ID" || { echo "FAIL(2): AWS access key ID not reported"; exit 1; }
echo "$output" | grep -q "config.txt" || { echo "FAIL(2): offending file not named"; exit 1; }
echo "SUCCESS(2): a tracked AWS access key ID always fails, without --strict."

# ---------------------------------------------------------------------------
# 3. An untracked-but-not-gitignored file with a secret pattern is still
#    caught (not just tracked files) -- this is the "before it's even
#    committed" guarantee.
# ---------------------------------------------------------------------------
repo="$test_dir/3"
make_repo "$repo"
(
  cd "$repo"
  # Fragmented for the same reason as the AWS key above: keep the full PEM
  # header out of this tracked test script's own literal source.
  echo "-----BEGIN RSA PRIVATE ""KEY-----" > leaked.pem
)

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected exit 1 for an untracked leaked .pem, got $status"; exit 1; }
echo "$output" | grep -q "leaked.pem" || { echo "FAIL(3): untracked leaked.pem not named as a filename hit"; exit 1; }
echo "$output" | grep -q "PEM private key block" || { echo "FAIL(3): PEM content pattern not reported for the untracked file"; exit 1; }
echo "SUCCESS(3): an untracked, not-yet-gitignored secret file is still caught."

# ---------------------------------------------------------------------------
# 4. A clean repository with .env.example (a placeholder, not a real .env)
#    passes -- proves the exclusion list actually suppresses false positives
#    rather than flagging everything ending in .env*. (--strict is not used
#    here: that flag governs the separate .gitignore-coverage recommendation,
#    covered by tests 5 and 6, and this fixture has no .gitignore at all.)
# ---------------------------------------------------------------------------
repo="$test_dir/4"
make_repo "$repo"
(
  cd "$repo"
  echo "PLACEHOLDER=changeme" > .env.example
  git add -Af
  git commit -q -m "Add .env.example"
)

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(4): expected exit 0 for .env.example, got $status"; exit 1; }
echo "$output" | grep -q "No credential-shaped filenames found" || { echo "FAIL(4): .env.example was incorrectly flagged"; exit 1; }
echo "SUCCESS(4): .env.example is not flagged as a secret filename."

# ---------------------------------------------------------------------------
# 5. A clean repository whose .gitignore already covers the known secret-file
#    families passes even under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/5"
make_repo "$repo"
(
  cd "$repo"
  cat > .gitignore <<'EOF'
.env
.env.*
*.pem
*.key
*.p12
*.pfx
id_rsa
credentials.json
.netrc
*.tfstate
EOF
  git add -Af
  git commit -q -m "Add .gitignore covering secret-file families"
)

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(5): expected exit 0 when .gitignore covers all families, got $status"; exit 1; }
echo "$output" | grep -q "coverage gaps: 0" || { echo "FAIL(5): expected zero .gitignore coverage gaps"; exit 1; }
echo "SUCCESS(5): full .gitignore coverage passes cleanly, even under --strict."

# ---------------------------------------------------------------------------
# 6. A clean repository with no secrets but no .gitignore coverage either:
#    warns (exit 0) by default, fails (exit 1) under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/6"
make_repo "$repo"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(6): expected exit 0 by default with no .gitignore, got $status"; exit 1; }
echo "$output" | grep -q "WARN     .env / .env.\* (recommended)" || { echo "FAIL(6): expected a WARN for missing .env coverage"; exit 1; }

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(6): expected exit 1 under --strict with no .gitignore coverage, got $status"; exit 1; }
echo "SUCCESS(6): missing .gitignore coverage warns by default, fails under --strict."

# ---------------------------------------------------------------------------
# 7. Usage error (not a Git repository) -> exit 2.
# ---------------------------------------------------------------------------
not_a_repo="$test_dir/not-a-repo"
mkdir -p "$not_a_repo"
run_check "$not_a_repo"
echo "$output"
[ "$status" -eq 2 ] || { echo "FAIL(7): expected exit 2 for a non-Git directory, got $status"; exit 1; }
echo "SUCCESS(7): usage errors report exit 2."

echo
echo "All check_secrets.sh tests passed."
