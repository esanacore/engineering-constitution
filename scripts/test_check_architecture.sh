#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_architecture.sh
#
# This is governance tooling, so the negative cases matter more than the
# positive one (TESTING.md, "Governance Tooling Must Be Tested"): a checker that
# silently passes a real violation is worse than no checker, and a checker that
# fails a build on a legal dependency will be disabled by the first team it
# annoys. Both directions are covered here, plus the deliberate design decision
# that structural signals never affect exit status.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_architecture.sh"

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

# A three-layer project with the standard inward-pointing declaration.
make_layered_repo() {
  local dest=$1
  mkdir -p "$dest/docs" \
           "$dest/src/domain" "$dest/src/application" "$dest/src/infrastructure"

  cat > "$dest/docs/ARCHITECTURE.md" <<'EOF'
# Architecture

## Layer Boundaries

| Layer          | Path               | May Depend On       |
| -------------- | ------------------ | ------------------- |
| domain         | src/domain         | --                  |
| application    | src/application    | domain              |
| infrastructure | src/infrastructure | domain, application |
EOF

  # Legal: inner layer depends on nothing outward.
  cat > "$dest/src/domain/user.py" <<'EOF'
from dataclasses import dataclass


@dataclass
class User:
    name: str
EOF

  # Legal: application may depend on domain.
  cat > "$dest/src/application/create_user.py" <<'EOF'
from src.domain.user import User


def create_user(name):
    return User(name=name)
EOF

  # Legal: infrastructure may depend on both.
  cat > "$dest/src/infrastructure/repo.py" <<'EOF'
from src.domain.user import User
from src.application.create_user import create_user
EOF
}

# ---------------------------------------------------------------------------
# 1. Clean layering -> exit 0, no violations reported.
# ---------------------------------------------------------------------------
repo="$test_dir/clean"
make_layered_repo "$repo"

run_check "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 for clean layering, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "Layer violations: 0;" || { echo "FAIL(1): expected zero violations"; echo "$output"; exit 1; }
echo "$output" | grep -q "all dependencies point inward" || { echo "FAIL(1): expected inward-pointing confirmation"; echo "$output"; exit 1; }
echo "SUCCESS(1): clean layering passes."

# ---------------------------------------------------------------------------
# 2. Inner layer importing an outer layer -> reported, warn by default.
# ---------------------------------------------------------------------------
repo="$test_dir/violation"
make_layered_repo "$repo"
cat > "$repo/src/domain/order.py" <<'EOF'
from src.infrastructure.repo import save
EOF

run_check "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(2): expected exit 0 without --strict, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "VIOLATION src/domain/order.py" || { echo "FAIL(2): violation not reported"; echo "$output"; exit 1; }
echo "$output" | grep -q "'domain' imports 'infrastructure'" || { echo "FAIL(2): violation not attributed correctly"; echo "$output"; exit 1; }
echo "$output" | grep -q "pass --strict to enforce" || { echo "FAIL(2): missing warn-by-default notice"; echo "$output"; exit 1; }
echo "SUCCESS(2): outward dependency is reported and warns by default."

# ---------------------------------------------------------------------------
# 3. The same violation under --strict -> exit 1.
# ---------------------------------------------------------------------------
run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected exit 1 under --strict, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "FAIL: dependencies point outward (--strict)." || { echo "FAIL(3): missing strict failure line"; echo "$output"; exit 1; }
echo "SUCCESS(3): --strict fails on an outward dependency."

# ---------------------------------------------------------------------------
# 4. Relative imports are resolved before matching, so a JS/TS violation that
#    never spells the layer path literally is still caught.
# ---------------------------------------------------------------------------
repo="$test_dir/relative"
make_layered_repo "$repo"
cat > "$repo/src/domain/cart.ts" <<'EOF'
import { save } from '../infrastructure/repo';
EOF

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 for relative-import violation, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "VIOLATION src/domain/cart.ts" || { echo "FAIL(4): relative import violation not caught"; echo "$output"; exit 1; }
echo "SUCCESS(4): relative imports are resolved before matching."

# ---------------------------------------------------------------------------
# 5. A legal outward-to-inward import must NOT be flagged. A checker with false
#    positives gets switched off.
# ---------------------------------------------------------------------------
repo="$test_dir/legal"
make_layered_repo "$repo"
cat > "$repo/src/infrastructure/extra.ts" <<'EOF'
import { User } from '../domain/user';
EOF

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(5): legal inward dependency was flagged, got $status"; echo "$output"; exit 1; }
echo "SUCCESS(5): legal inward dependencies are not flagged."

# ---------------------------------------------------------------------------
# 6. Layer names are matched by path component, never substring: a layer named
#    `db` must not be matched by an import of `dbutils`.
# ---------------------------------------------------------------------------
repo="$test_dir/substring"
mkdir -p "$repo/docs" "$repo/src/db" "$repo/src/core" "$repo/src/dbutils"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
# Architecture

## Layer Boundaries

| Layer | Path      | May Depend On |
| ----- | --------- | ------------- |
| core  | src/core  | --            |
| db    | src/db    | core          |
EOF
cat > "$repo/src/core/thing.py" <<'EOF'
from src.dbutils.helpers import format_row
EOF

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(6): 'dbutils' was matched against layer 'db', got $status"; echo "$output"; exit 1; }
echo "SUCCESS(6): layer matching is component-exact, not substring."

# ---------------------------------------------------------------------------
# 7. Structural signals are advisory and must NEVER change exit status, even
#    under --strict. ARCHITECTURE.md's SRP guardrail explicitly warns against
#    splitting a module merely because it is long.
# ---------------------------------------------------------------------------
repo="$test_dir/signals"
make_layered_repo "$repo"
{
  echo "from src.domain.user import User"
  i=0
  while [ "$i" -lt 700 ]; do
    echo "# padding line $i"
    i=$((i + 1))
  done
} > "$repo/src/application/huge.py"

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(7): a structural signal changed exit status, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "SIGNAL   src/application/huge.py" || { echo "FAIL(7): oversized file not reported"; echo "$output"; exit 1; }
echo "$output" | grep -q "advisory; never fail the build" || { echo "FAIL(7): advisory framing missing"; echo "$output"; exit 1; }
echo "SUCCESS(7): structural signals never affect exit status."

# ---------------------------------------------------------------------------
# 8. Thresholds are configurable, and a crowded directory is reported.
# ---------------------------------------------------------------------------
repo="$test_dir/crowded"
mkdir -p "$repo/src/widgets"
i=0
while [ "$i" -lt 6 ]; do
  echo "x = $i" > "$repo/src/widgets/w$i.py"
  i=$((i + 1))
done

run_check --max-dir-files 3 "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(8): expected exit 0, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "src/widgets/ holds 6 source files (over 3)" || { echo "FAIL(8): crowded directory not reported"; echo "$output"; exit 1; }
echo "SUCCESS(8): thresholds are configurable and crowding is reported."

# ---------------------------------------------------------------------------
# 9. Layer enforcement is opt-in: a project with no table is not failed.
# ---------------------------------------------------------------------------
repo="$test_dir/no-table"
mkdir -p "$repo/src"
echo "x = 1" > "$repo/src/a.py"

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(9): a project without a layer table was failed, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "layer enforcement is opt-in" || { echo "FAIL(9): opt-in notice missing"; echo "$output"; exit 1; }
echo "SUCCESS(9): layer enforcement is opt-in."

# ---------------------------------------------------------------------------
# 10. A declared layer whose path does not exist is surfaced, not ignored --
#     otherwise a typo silently disables enforcement for that layer.
# ---------------------------------------------------------------------------
repo="$test_dir/bad-path"
mkdir -p "$repo/docs" "$repo/src/core"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
# Architecture

## Layer Boundaries

| Layer | Path        | May Depend On |
| ----- | ----------- | ------------- |
| core  | src/core    | --            |
| web   | src/webbb   | core          |
EOF
echo "x = 1" > "$repo/src/core/a.py"

run_check "$repo"
echo "$output" | grep -q "layer 'web' declares path 'src/webbb', which does not exist" || { echo "FAIL(10): typo'd layer path not surfaced"; echo "$output"; exit 1; }
echo "SUCCESS(10): a layer path that does not exist is surfaced."

# ---------------------------------------------------------------------------
# 11. Vendored code is not scanned: a violation inside node_modules must not be
#     attributed to the project.
# ---------------------------------------------------------------------------
repo="$test_dir/vendored"
make_layered_repo "$repo"
mkdir -p "$repo/node_modules/pkg/src/domain"
cat > "$repo/node_modules/pkg/src/domain/bad.py" <<'EOF'
from src.infrastructure.repo import save
EOF

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(11): vendored code was scanned, got $status"; echo "$output"; exit 1; }
echo "SUCCESS(11): vendored directories are excluded."

# ---------------------------------------------------------------------------
# 12. Usage errors report exit 2.
# ---------------------------------------------------------------------------
run_check --bogus "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(12): expected exit 2 on unknown option, got $status"; exit 1; }

run_check "$test_dir/does-not-exist"
[ "$status" -eq 2 ] || { echo "FAIL(12): expected exit 2 on missing root, got $status"; exit 1; }

run_check --max-file-lines 0 "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(12): expected exit 2 on a non-positive threshold, got $status"; exit 1; }

run_check --max-dir-files abc "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(12): expected exit 2 on a non-numeric threshold, got $status"; exit 1; }
echo "SUCCESS(12): usage errors report exit 2."

echo "ALL TESTS PASSED"
