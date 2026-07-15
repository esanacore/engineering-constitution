#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_ots_inventory.sh
#
# These cover the positive case plus the negative cases the constitution
# requires of governance tooling (TESTING.md, "Governance Tooling Must Be
# Tested"), including the substring-collision case where an inventory row for
# `dunder-proto` must not satisfy a check for the dependency `proto`, and the
# scope guarantees (devDependencies and indirect go.mod requires are excluded).

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_ots_inventory.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

# Helper: start an inventory file with the standard header.
start_inventory() {
  dest_root=$1
  mkdir -p "$dest_root/docs"
  {
    echo "# OTS Software Inventory"
    echo
    echo "## Managed Dependencies"
    echo
    echo "| Component ID | Name | Version | Supplier / Maintainer | Purpose | Risk | Verification | Anomaly Review | Update Policy | Status |"
    echo "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
  } > "$dest_root/docs/OTS_SOFTWARE.md"
}

inventory_row() {
  dest_root=$1
  id=$2
  name=$3
  echo "| $id | $name | 1.0.0 | upstream | purpose | Low | integration tests | tracker — 2026-07-15 | pinned | Active |" >> "$dest_root/docs/OTS_SOFTWARE.md"
}

run_check() {
  set +e
  output=$("$check_script" "$@" 2>&1)
  status=$?
  set -e
}

# ---------------------------------------------------------------------------
# 1. Happy path: every declared dependency across two manifests is documented,
#    including a case difference (Django vs django) -> exit 0.
# ---------------------------------------------------------------------------
repo="$test_dir/happy"
mkdir -p "$repo"
cat > "$repo/package.json" <<'EOF'
{
  "name": "demo",
  "dependencies": {
    "express": "^4.19.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "eslint": "^9.0.0"
  }
}
EOF
cat > "$repo/requirements.txt" <<'EOF'
# runtime deps
Django==5.0.6
requests>=2.32,<3
-r requirements-dev.txt
git+https://github.com/example/private-pkg.git
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 "express"
inventory_row "$repo" OTS-002 "zod"
inventory_row "$repo" OTS-003 "django"
inventory_row "$repo" OTS-004 '`requests`'

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 when all documented, got $status"; exit 1; }
echo "$output" | grep -q "OK       express" || { echo "FAIL(1): express not reported OK"; exit 1; }
echo "$output" | grep -q "OK       Django" || { echo "FAIL(1): case-insensitive match for Django failed"; exit 1; }
echo "$output" | grep -q "OK       requests" || { echo "FAIL(1): backticked inventory name not matched"; exit 1; }
echo "$output" | grep -q "MISSING" && { echo "FAIL(1): unexpected MISSING in happy path"; exit 1; }
echo "$output" | grep -q "eslint" && { echo "FAIL(1): devDependencies must not be checked"; exit 1; }
echo "SUCCESS(1): all-documented case passes, devDependencies excluded."

# ---------------------------------------------------------------------------
# 2. Undocumented dependency -> warn (exit 0) by default, fail under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/undocumented"
mkdir -p "$repo"
cat > "$repo/package.json" <<'EOF'
{
  "dependencies": {
    "express": "^4.19.0",
    "left-pad": "^1.3.0"
  }
}
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 "express"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2): expected exit 0 (warn) by default, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  left-pad" || { echo "FAIL(2): left-pad gap not reported"; exit 1; }
echo "$output" | grep -q "WARN" || { echo "FAIL(2): warning banner not shown"; exit 1; }

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 under --strict, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  left-pad" || { echo "FAIL(2): left-pad gap not reported under --strict"; exit 1; }
echo "SUCCESS(2): undocumented dependency warns by default and fails under --strict."

# ---------------------------------------------------------------------------
# 3. Dependencies declared but no inventory file -> warn default, fail --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/no-inventory"
mkdir -p "$repo"
cat > "$repo/Gemfile" <<'EOF'
source "https://rubygems.org"
gem "rails", "~> 7.1"
gem 'puma'
EOF

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected exit 0 (warn) with no inventory, got $status"; exit 1; }
echo "$output" | grep -q "no OTS software inventory" || { echo "FAIL(3): missing-inventory message not shown"; exit 1; }

run_check --strict "$repo"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected exit 1 under --strict with no inventory, got $status"; exit 1; }
echo "SUCCESS(3): missing inventory warns by default and fails under --strict."

# ---------------------------------------------------------------------------
# 4. Placeholder Name cells never count as documentation.
# ---------------------------------------------------------------------------
repo="$test_dir/placeholder"
mkdir -p "$repo"
cat > "$repo/package.json" <<'EOF'
{
  "dependencies": {
    "express": "^4.19.0"
  }
}
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 '`<name exactly as declared in the manifest>`'

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 — placeholder row must not document express, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  express" || { echo "FAIL(4): express not reported MISSING against placeholder row"; exit 1; }
echo "SUCCESS(4): placeholder rows do not count as documentation."

# ---------------------------------------------------------------------------
# 5. Substring collision: dependency `proto` with only a `dunder-proto` row
#    must still be MISSING (exact cell matching, never substring).
# ---------------------------------------------------------------------------
repo="$test_dir/substring"
mkdir -p "$repo"
cat > "$repo/package.json" <<'EOF'
{
  "dependencies": {
    "proto": "^1.0.0"
  }
}
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 "dunder-proto"

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(5): expected exit 1 — dunder-proto must not satisfy proto, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  proto" || { echo "FAIL(5): proto not reported MISSING (substring collision)"; exit 1; }
echo "$output" | grep -q "OK       proto" && { echo "FAIL(5): proto wrongly satisfied by dunder-proto"; exit 1; }
echo "SUCCESS(5): inventory row dunder-proto does not satisfy dependency proto."

# ---------------------------------------------------------------------------
# 6. go.mod: direct requires checked, "// indirect" excluded.
# ---------------------------------------------------------------------------
repo="$test_dir/gomod"
mkdir -p "$repo"
cat > "$repo/go.mod" <<'EOF'
module example.com/demo

go 1.22

require (
	github.com/gin-gonic/gin v1.10.0
	golang.org/x/sys v0.20.0 // indirect
)

require github.com/spf13/cobra v1.8.0
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 "github.com/gin-gonic/gin"

run_check "$repo"
echo "$output"
echo "$output" | grep -q "OK       github.com/gin-gonic/gin" || { echo "FAIL(6): gin not detected from require block"; exit 1; }
echo "$output" | grep -q "MISSING  github.com/spf13/cobra" || { echo "FAIL(6): single-line require not detected"; exit 1; }
echo "$output" | grep -q "golang.org/x/sys" && { echo "FAIL(6): indirect require must be excluded"; exit 1; }
echo "SUCCESS(6): go.mod direct requires checked, indirect excluded."

# ---------------------------------------------------------------------------
# 7. Cargo.toml: [dependencies] and [dependencies.<name>] checked,
#    [dev-dependencies] excluded. pyproject.toml PEP 621 array parsed.
# ---------------------------------------------------------------------------
repo="$test_dir/cargo-py"
mkdir -p "$repo"
cat > "$repo/Cargo.toml" <<'EOF'
[package]
name = "demo"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = "1.38"

[dependencies.reqwest]
version = "0.12"

[dev-dependencies]
criterion = "0.5"
EOF
cat > "$repo/pyproject.toml" <<'EOF'
[project]
name = "demo"
dependencies = [
    "fastapi>=0.111",
    "pydantic[email]>=2.7",
]
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 "serde"
inventory_row "$repo" OTS-002 "tokio"
inventory_row "$repo" OTS-003 "reqwest"
inventory_row "$repo" OTS-004 "fastapi"
inventory_row "$repo" OTS-005 "pydantic"

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(7): expected exit 0 with all documented, got $status"; exit 1; }
echo "$output" | grep -q "OK       reqwest" || { echo "FAIL(7): [dependencies.reqwest] table not detected"; exit 1; }
echo "$output" | grep -q "OK       pydantic" || { echo "FAIL(7): extras marker [email] not stripped from pydantic"; exit 1; }
echo "$output" | grep -q "criterion" && { echo "FAIL(7): dev-dependencies must be excluded"; exit 1; }
echo "SUCCESS(7): Cargo.toml and pyproject.toml parse with correct scope."

# ---------------------------------------------------------------------------
# 8. Inventory rows beyond the manifests (system-level OTS) are informational
#    and never fail, even under --strict.
# ---------------------------------------------------------------------------
repo="$test_dir/system-level"
mkdir -p "$repo"
cat > "$repo/package.json" <<'EOF'
{
  "dependencies": {
    "pg": "^8.11.0"
  }
}
EOF
start_inventory "$repo"
inventory_row "$repo" OTS-001 "pg"
inventory_row "$repo" OTS-101 "PostgreSQL"

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(8): expected exit 0 — extra inventory rows must never fail, got $status"; exit 1; }
echo "$output" | grep -q "PostgreSQL" || { echo "FAIL(8): system-level row not reported informationally"; exit 1; }
echo "SUCCESS(8): system-level inventory rows are informational only."

# ---------------------------------------------------------------------------
# 9. No manifests at all -> vacuous pass, even under --strict, even with no
#    inventory file.
# ---------------------------------------------------------------------------
repo="$test_dir/empty"
mkdir -p "$repo"

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(9): expected exit 0 with no manifests, got $status"; exit 1; }
echo "$output" | grep -q "nothing to verify" || { echo "FAIL(9): vacuous-pass message not shown"; exit 1; }
echo "SUCCESS(9): no-manifests case passes vacuously."

# ---------------------------------------------------------------------------
# 10. Usage errors -> exit 2.
# ---------------------------------------------------------------------------
run_check --bogus "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(10): expected exit 2 on unknown option, got $status"; exit 1; }

run_check "$test_dir/does-not-exist"
[ "$status" -eq 2 ] || { echo "FAIL(10): expected exit 2 on missing root, got $status"; exit 1; }
echo "SUCCESS(10): usage errors report exit 2."

echo "ALL TESTS PASSED"
