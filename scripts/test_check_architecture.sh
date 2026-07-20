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
# 13. A cycle in the declared layer graph is a violation on its own. Each edge
#     is individually legal per its allow-list, so the per-import check cannot
#     see this -- only a graph pass can.
# ---------------------------------------------------------------------------
repo="$test_dir/cycle-two"
mkdir -p "$repo/docs" "$repo/src/domain" "$repo/src/infra"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer  | Path       | May Depend On |
| ------ | ---------- | ------------- |
| domain | src/domain | infra         |
| infra  | src/infra  | domain        |
EOF
echo "x = 1" > "$repo/src/domain/a.py"
echo "y = 2" > "$repo/src/infra/b.py"

run_check "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(13): expected exit 0 without --strict, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "CYCLE     domain -> infra -> domain" || { echo "FAIL(13): two-layer cycle not reported"; echo "$output"; exit 1; }
echo "$output" | grep -q "declared cycles: 1;" || { echo "FAIL(13): cycle not counted"; echo "$output"; exit 1; }

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(13): expected exit 1 under --strict for a cycle, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "FAIL: the declared layer graph is cyclic (--strict)." || { echo "FAIL(13): strict cycle failure line missing"; echo "$output"; exit 1; }
echo "SUCCESS(13): a two-layer cycle is detected and fails under --strict."

# ---------------------------------------------------------------------------
# 14. Cycles longer than two hops are found, and a cycle reachable from several
#     entry points is reported once rather than once per path into it.
# ---------------------------------------------------------------------------
repo="$test_dir/cycle-three"
mkdir -p "$repo/docs" "$repo/src/a" "$repo/src/b" "$repo/src/c" "$repo/src/entry"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer | Path      | May Depend On |
| ----- | --------- | ------------- |
| entry | src/entry | a, b          |
| a     | src/a     | b             |
| b     | src/b     | c             |
| c     | src/c     | a             |
EOF
for d in a b c entry; do echo "x = 1" > "$repo/src/$d/m.py"; done

run_check "$repo"
echo "$output" | grep -q "CYCLE     a -> b -> c -> a" || { echo "FAIL(14): three-layer cycle not reported"; echo "$output"; exit 1; }
echo "$output" | grep -q "declared cycles: 1;" || { echo "FAIL(14): cycle reachable from two entry points was not deduped"; echo "$output"; exit 1; }
echo "SUCCESS(14): multi-hop cycles are found and deduped."

# ---------------------------------------------------------------------------
# 15. An acyclic graph must not be reported as cyclic. A diamond (two layers
#     sharing a dependency) is the shape most likely to be mistaken for a cycle.
# ---------------------------------------------------------------------------
repo="$test_dir/diamond"
mkdir -p "$repo/docs" "$repo/src/base" "$repo/src/left" "$repo/src/right" "$repo/src/top"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer | Path      | May Depend On |
| ----- | --------- | ------------- |
| base  | src/base  | --            |
| left  | src/left  | base          |
| right | src/right | base          |
| top   | src/top   | left, right   |
EOF
for d in base left right top; do echo "x = 1" > "$repo/src/$d/m.py"; done

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(15): a diamond was reported as cyclic, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "declared cycles: 0;" || { echo "FAIL(15): false cycle on an acyclic graph"; echo "$output"; exit 1; }
echo "$output" | grep -q "graph is acyclic" || { echo "FAIL(15): acyclic confirmation missing"; echo "$output"; exit 1; }
echo "SUCCESS(15): an acyclic diamond is not reported as a cycle."

# ---------------------------------------------------------------------------
# 16. A layer may always depend on itself; a self-reference is not a cycle.
# ---------------------------------------------------------------------------
repo="$test_dir/self-loop"
mkdir -p "$repo/docs" "$repo/src/core"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer | Path     | May Depend On |
| ----- | -------- | ------------- |
| core  | src/core | core          |
EOF
echo "x = 1" > "$repo/src/core/m.py"

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(16): a self-reference was treated as a cycle, got $status"; echo "$output"; exit 1; }
echo "SUCCESS(16): a self-reference is not a cycle."

# ---------------------------------------------------------------------------
# 17. A "May Depend On" name matching no declared layer is surfaced. A typo
#     there is silent by construction: it permits nothing, so the layer
#     enforces more than its author wrote.
# ---------------------------------------------------------------------------
repo="$test_dir/unknown-dep"
mkdir -p "$repo/docs" "$repo/src/app" "$repo/src/domain"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer  | Path       | May Depend On |
| ------ | ---------- | ------------- |
| domain | src/domain | --            |
| app    | src/app    | doamin        |
EOF
echo "x = 1" > "$repo/src/domain/m.py"
echo "from src.domain.m import x" > "$repo/src/app/m.py"

run_check "$repo"
echo "$output" | grep -q "layer 'app' may depend on 'doamin', which is not a declared layer" || { echo "FAIL(17): unknown dependency name not surfaced"; echo "$output"; exit 1; }
# The typo means the real dependency is not permitted, so the import is a violation.
echo "$output" | grep -q "VIOLATION src/app/m.py" || { echo "FAIL(17): typo'd allow-list did not make the import a violation"; echo "$output"; exit 1; }
echo "SUCCESS(17): an unknown dependency name is surfaced and still enforced strictly."

# ---------------------------------------------------------------------------
# 18. Regression: two layers sharing a directory name must not swallow a real
#     violation. Attribution used to test full-path and directory-name matches
#     per layer in turn, so an earlier layer's directory name beat a later
#     layer's exact path -- and when the wrong answer was the importing layer
#     itself, the import was dropped as a self-import and the violation
#     vanished. This exact fixture reported "all dependencies point inward"
#     and exited 0 before the two-pass fix.
# ---------------------------------------------------------------------------
repo="$test_dir/shared-basename"
mkdir -p "$repo/docs" "$repo/src/a/core" "$repo/src/b/core"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer | Path       | May Depend On |
| ----- | ---------- | ------------- |
| acore | src/a/core | --            |
| bcore | src/b/core | acore         |
EOF
echo 'from src.b.core.thing import x' > "$repo/src/a/core/m.py"

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(18): shared-basename violation was swallowed, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "VIOLATION src/a/core/m.py" || { echo "FAIL(18): violation not reported"; echo "$output"; exit 1; }
echo "$output" | grep -q "'acore' imports 'bcore'" || { echo "FAIL(18): violation misattributed"; echo "$output"; exit 1; }
echo "$output" | grep -q "share the directory name 'core'" || { echo "FAIL(18): shared directory name not surfaced"; echo "$output"; exit 1; }
echo "SUCCESS(18): a shared layer directory name no longer swallows a violation."

# ---------------------------------------------------------------------------
# 19. Go: internal imports carry the go.mod module prefix, which must be
#     stripped before the path can be compared to a layer.
# ---------------------------------------------------------------------------
repo="$test_dir/go-module"
mkdir -p "$repo/docs" "$repo/domain" "$repo/infra"
echo 'module github.com/esanacore/app' > "$repo/go.mod"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer  | Path   | May Depend On |
| ------ | ------ | ------------- |
| domain | domain | --            |
| infra  | infra  | domain        |
EOF
echo 'import "github.com/esanacore/app/infra/db"' > "$repo/domain/x.go"

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(19): go module-prefixed violation not caught, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "go.mod module prefix: github.com/esanacore/app" || { echo "FAIL(19): module prefix not reported"; echo "$output"; exit 1; }
echo "$output" | grep -q "'domain' imports 'infra'" || { echo "FAIL(19): go violation misattributed"; echo "$output"; exit 1; }

# A third-party import sharing the module's shape must not be attributed.
repo="$test_dir/go-thirdparty"
mkdir -p "$repo/docs" "$repo/domain" "$repo/infra"
echo 'module github.com/esanacore/app' > "$repo/go.mod"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer  | Path   | May Depend On |
| ------ | ------ | ------------- |
| domain | domain | --            |
| infra  | infra  | domain        |
EOF
echo 'import "github.com/other/lib/telemetry"' > "$repo/domain/x.go"

run_check --strict "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(19): a third-party import was treated as a layer, got $status"; echo "$output"; exit 1; }
echo "SUCCESS(19): go.mod module prefixes are resolved, third-party imports are not."

# ---------------------------------------------------------------------------
# 20. TypeScript: tsconfig.json path aliases must be rewritten before matching.
#     The file is parsed as JSONC, since comments are conventional there.
# ---------------------------------------------------------------------------
repo="$test_dir/ts-alias"
mkdir -p "$repo/docs" "$repo/src/domain" "$repo/src/infra"
cat > "$repo/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "baseUrl": ".",
    // aliases used across the app
    "paths": {
      "@infra/*": ["src/infra/*"],
      "@domain/*": ["src/domain/*"]
    }
  }
}
EOF
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer  | Path       | May Depend On |
| ------ | ---------- | ------------- |
| domain | src/domain | --            |
| infra  | src/infra  | domain        |
EOF
echo "import { db } from '@infra/db';" > "$repo/src/domain/x.ts"

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(20): aliased violation not caught, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "tsconfig path aliases: 2 declared" || { echo "FAIL(20): aliases not parsed past the JSONC comment"; echo "$output"; exit 1; }
echo "$output" | grep -q "'domain' imports 'infra' via \"@infra/db\"" || { echo "FAIL(20): alias not resolved"; echo "$output"; exit 1; }
echo "SUCCESS(20): tsconfig path aliases are resolved."

# ---------------------------------------------------------------------------
# 21. Python src-layout: packages are addressed from src/, not the repo root,
#     so a bare `infra.db` must resolve to src/infra/db.
# ---------------------------------------------------------------------------
repo="$test_dir/py-src-layout"
mkdir -p "$repo/docs" "$repo/src/domain" "$repo/src/infra"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF'
## Layer Boundaries

| Layer  | Path       | May Depend On |
| ------ | ---------- | ------------- |
| domain | src/domain | --            |
| infra  | src/infra  | domain        |
EOF
echo 'from infra.db import session' > "$repo/src/domain/x.py"

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(21): src-layout violation not caught, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "'domain' imports 'infra'" || { echo "FAIL(21): bare package path not resolved through src/"; echo "$output"; exit 1; }
echo "SUCCESS(21): a src-layout package path resolves to its layer."

# ---------------------------------------------------------------------------
# 23. Every library check_architecture.sh sources must exist AND be tracked by
#     Git. A working tree passes happily while a clone gets a checker that dies
#     on its first line -- the failure mode that nearly shipped in 1.39.1, when
#     a bare `lib/` in a personal global gitignore silently excluded
#     scripts/lib/ from `git add -A`.
# ---------------------------------------------------------------------------
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
sourced=$(sed -n 's/^for lib in \(.*\); do$/\1/p' "$repo_root/scripts/check_architecture.sh" | head -n 1)
[ -n "$sourced" ] || { echo "FAIL(23): could not find the library source loop in check_architecture.sh"; exit 1; }

for lib in $sourced; do
  [ -f "$repo_root/scripts/lib/$lib" ] || { echo "FAIL(23): check_architecture.sh sources '$lib', which does not exist"; exit 1; }

  if ! git -C "$repo_root" ls-files --error-unmatch "scripts/lib/$lib" >/dev/null 2>&1; then
    echo "FAIL(23): scripts/lib/$lib exists but is NOT tracked by Git."
    echo "          A fresh clone would get a checker that sources a missing file."
    echo "          Check: git check-ignore -v scripts/lib/$lib"
    exit 1
  fi
done
echo "SUCCESS(23): all sourced libraries exist and are tracked."

# ---------------------------------------------------------------------------
# 24. A missing library must fail loudly as a usage error rather than producing
#     a half-finished report that looks like a clean result.
# ---------------------------------------------------------------------------
staged="$test_dir/staged-constitution"
mkdir -p "$staged/scripts"
cp "$repo_root/scripts/check_architecture.sh" "$staged/scripts/"
cp -r "$repo_root/scripts/lib" "$staged/scripts/"
rm "$staged/scripts/lib/architecture_layers.sh"

repo="$test_dir/lib-missing"
mkdir -p "$repo/src"
echo "x = 1" > "$repo/src/a.py"

set +e
output=$("$staged/scripts/check_architecture.sh" "$repo" 2>&1)
status=$?
set -e

[ "$status" -eq 2 ] || { echo "FAIL(24): expected exit 2 for a missing library, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "Missing required library" || { echo "FAIL(24): missing-library error not reported"; echo "$output"; exit 1; }
if echo "$output" | grep -q "Layer violations:"; then
  echo "FAIL(24): produced a summary despite a missing library"
  exit 1
fi
echo "SUCCESS(24): a missing library fails loudly before reporting anything."

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


# ---------------------------------------------------------------------------
# 22. A tsconfig.json without `baseUrl` must not abort the checker.
#
#     `set -euo pipefail` plus an unguarded `grep` that matches nothing exits
#     1 mid-assignment, which killed the run after only the header had been
#     printed: no violations listed, no error, exit 1. Next.js ships `paths`
#     with no `baseUrl`, so this fired on a default Next project and looked
#     like a failing architecture gate rather than a broken checker.
#
#     The second case covers the same failure in the alias scan: a tsconfig
#     declaring no array-valued option at all.
# ---------------------------------------------------------------------------
repo="$test_dir/tsconfig-no-baseurl"
mkdir -p "$repo/docs" "$repo/src/domain" "$repo/src/infra"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF2'
## Layer Boundaries

| Layer  | Path       | May Depend On |
| ------ | ---------- | ------------- |
| domain | src/domain | --            |
| infra  | src/infra  | domain        |
EOF2
# paths but no baseUrl -- the shape Next.js generates.
printf '{\n  "compilerOptions": {\n    "paths": { "@/*": ["./*"] }\n  }\n}\n' > "$repo/tsconfig.json"
echo 'export const ok = 1;' > "$repo/src/domain/x.ts"

run_check "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(22): clean repo with no baseUrl should pass, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "Layer violations: 0" || { echo "FAIL(22): checker aborted before reporting"; echo "$output"; exit 1; }

# The same repo with a real violation must still be caught -- proving the
# guard did not simply swallow the run.
echo "import { thing } from '../infra/db';" > "$repo/src/domain/x.ts"
echo 'export const thing = 1;' > "$repo/src/infra/db.ts"
run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(22): violation missed when baseUrl absent, got $status"; echo "$output"; exit 1; }
echo "$output" | grep -q "'domain' imports 'infra'" || { echo "FAIL(22): violation not reported"; echo "$output"; exit 1; }

# A tsconfig with no array-valued option at all must not abort the alias scan.
repo="$test_dir/tsconfig-no-arrays"
mkdir -p "$repo/docs" "$repo/src/domain"
cat > "$repo/docs/ARCHITECTURE.md" <<'EOF2'
## Layer Boundaries

| Layer  | Path       | May Depend On |
| ------ | ---------- | ------------- |
| domain | src/domain | --            |
EOF2
printf '{\n  "compilerOptions": { "strict": true }\n}\n' > "$repo/tsconfig.json"
echo 'export const ok = 1;' > "$repo/src/domain/x.ts"
run_check "$repo"
[ "$status" -eq 0 ] || { echo "FAIL(22): tsconfig with no arrays should pass, got $status"; echo "$output"; exit 1; }
echo "SUCCESS(22): a tsconfig without baseUrl does not abort the checker."

echo "ALL TESTS PASSED"
