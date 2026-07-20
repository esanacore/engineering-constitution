#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/check_compliance.sh
#
# Covers the positive case plus the negative cases the constitution requires of
# governance tooling (TESTING.md, "Governance Tooling Must Be Tested"): a missing
# required file must fail, and the recommended/product tiers must behave
# correctly under their default and strict modes.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_compliance.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

# Build a fully compliant adopter skeleton (required + recommended + product)
# in the current layout, where HELP.md, SECURITY.md, and CONTRIBUTING.md live
# outside the repository root.
make_compliant_repo() {
  dest=$1
  mkdir -p "$dest/docs/adr" "$dest/constitution" "$dest/.github"
  for f in README.md CHANGELOG.md TODO.md AGENTS.md VERSION; do
    echo "placeholder" > "$dest/$f"
  done
  echo "placeholder" > "$dest/docs/HELP.md"
  echo "placeholder" > "$dest/.github/SECURITY.md"
  echo "placeholder" > "$dest/.github/CONTRIBUTING.md"
  for f in SETUP.md COMMAND_REFERENCE.md TROUBLESHOOTING.md ARCHITECTURE.md \
           AGENT_PROMPTS.md AGENT_HANDOFF.md OPERATIONS.md TEST_PLAN.md \
           OTS_SOFTWARE.md SESSION_PLAN.md MEMORY.md ENV_VARS.md \
           PRODUCT_REQUIREMENTS.md REQUIREMENTS_TRACEABILITY.md; do
    echo "placeholder" > "$dest/docs/$f"
  done
  echo "placeholder" > "$dest/docs/adr/0001-record-architecture-decisions.md"
  echo "v1" > "$dest/constitution/VERSION"
}

run_check() {
  set +e
  output=$("$check_script" "$@" 2>&1)
  status=$?
  set -e
}

# ---------------------------------------------------------------------------
# 1. Fully compliant repository -> exit 0.
# ---------------------------------------------------------------------------
repo="$test_dir/full"
make_compliant_repo "$repo"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected exit 0 for compliant repo, got $status"; exit 1; }
echo "$output" | grep -q "Required missing: 0;" || { echo "FAIL(1): expected zero required missing"; exit 1; }
echo "$output" | grep -q "recommended missing: 0;" || { echo "FAIL(1): expected zero recommended missing"; exit 1; }
echo "$output" | grep -q "OK       docs/SESSION_PLAN.md" || { echo "FAIL(1): docs/SESSION_PLAN.md not reported OK"; exit 1; }
echo "$output" | grep -q "OK       docs/MEMORY.md" || { echo "FAIL(1): docs/MEMORY.md not reported OK"; exit 1; }
echo "$output" | grep -q "OK       docs/ENV_VARS.md" || { echo "FAIL(1): docs/ENV_VARS.md not reported OK"; exit 1; }
echo "SUCCESS(1): fully compliant repository passes."

# ---------------------------------------------------------------------------
# 2. Missing a required file -> exit 1 and the file is named.
# ---------------------------------------------------------------------------
repo="$test_dir/missing-required"
make_compliant_repo "$repo"
rm "$repo/.github/SECURITY.md"

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected exit 1 when a required file is missing, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  .github/SECURITY.md (required)" || { echo "FAIL(2): missing .github/SECURITY.md not reported"; exit 1; }
echo "SUCCESS(2): missing required file fails."

# ---------------------------------------------------------------------------
# 2c. Repositories that adopted before v1.38.0 keep HELP.md, SECURITY.md, and
#     CONTRIBUTING.md in the repository root. Both layouts must pass, and the
#     report must name the location that actually exists.
# ---------------------------------------------------------------------------
repo="$test_dir/legacy-layout"
make_compliant_repo "$repo"
mv "$repo/docs/HELP.md" "$repo/HELP.md"
mv "$repo/.github/SECURITY.md" "$repo/SECURITY.md"
mv "$repo/.github/CONTRIBUTING.md" "$repo/CONTRIBUTING.md"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2c): expected exit 0 for pre-1.38.0 root layout, got $status"; exit 1; }
echo "$output" | grep -q "OK       HELP.md" || { echo "FAIL(2c): root HELP.md not accepted"; exit 1; }
echo "$output" | grep -q "OK       SECURITY.md" || { echo "FAIL(2c): root SECURITY.md not accepted"; exit 1; }
echo "$output" | grep -q "OK       CONTRIBUTING.md" || { echo "FAIL(2c): root CONTRIBUTING.md not accepted"; exit 1; }
echo "$output" | grep -q "Required missing: 0;" || { echo "FAIL(2c): legacy layout reported required gaps"; exit 1; }
echo "SUCCESS(2c): pre-1.38.0 root layout is grandfathered."

# ---------------------------------------------------------------------------
# 2d. Vendor instruction files are opt-in per tool, so a repository without
#     CLAUDE.md must not be warned about it.
# ---------------------------------------------------------------------------
repo="$test_dir/no-vendor-files"
make_compliant_repo "$repo"

run_check --strict "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(2d): expected exit 0 without vendor files under --strict, got $status"; exit 1; }
if echo "$output" | grep -q "CLAUDE.md"; then
  echo "FAIL(2d): CLAUDE.md should not be checked"
  exit 1
fi
echo "SUCCESS(2d): vendor instruction files are not required."

# ---------------------------------------------------------------------------
# 2b. Missing the constitution submodule directory -> exit 1.
# ---------------------------------------------------------------------------
repo="$test_dir/missing-submodule"
make_compliant_repo "$repo"
rm -rf "$repo/constitution"

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2b): expected exit 1 when constitution/ is missing, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  constitution (required)" || { echo "FAIL(2b): missing constitution/ not reported"; exit 1; }
echo "SUCCESS(2b): missing constitution submodule directory fails."

# ---------------------------------------------------------------------------
# 3. Missing only a recommended file -> exit 0 by default, with a warning.
# ---------------------------------------------------------------------------
repo="$test_dir/missing-recommended"
make_compliant_repo "$repo"
rm "$repo/docs/OPERATIONS.md"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(3): expected exit 0 when only a recommended file is missing, got $status"; exit 1; }
echo "$output" | grep -q "WARN     docs/OPERATIONS.md (recommended)" || { echo "FAIL(3): recommended warning not shown"; exit 1; }
echo "SUCCESS(3): missing recommended file warns but passes by default."

# ---------------------------------------------------------------------------
# 4. --strict turns a missing recommended file into a failure -> exit 1.
# ---------------------------------------------------------------------------
run_check --strict "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected exit 1 under --strict with a recommended gap, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  docs/OPERATIONS.md (recommended, --strict)" || { echo "FAIL(4): strict recommended failure not shown"; exit 1; }
echo "SUCCESS(4): --strict fails on a recommended gap."

# ---------------------------------------------------------------------------
# 5. Product-facing files: warn by default, fail under --product.
# ---------------------------------------------------------------------------
repo="$test_dir/missing-product"
make_compliant_repo "$repo"
rm "$repo/docs/REQUIREMENTS_TRACEABILITY.md"

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(5): expected exit 0 when a product file is missing by default, got $status"; exit 1; }
echo "$output" | grep -q "WARN     docs/REQUIREMENTS_TRACEABILITY.md (product-facing)" || { echo "FAIL(5): product warning not shown"; exit 1; }

run_check --product "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(5): expected exit 1 under --product with a product gap, got $status"; exit 1; }
echo "$output" | grep -q "MISSING  docs/REQUIREMENTS_TRACEABILITY.md (product, --product)" || { echo "FAIL(5): product failure not shown"; exit 1; }
echo "SUCCESS(5): product-facing files warn by default and fail under --product."

# ---------------------------------------------------------------------------
# 6. Unknown option / missing root -> usage error exit 2.
# ---------------------------------------------------------------------------
run_check --bogus "$repo"
[ "$status" -eq 2 ] || { echo "FAIL(6): expected exit 2 on unknown option, got $status"; exit 1; }

run_check "$test_dir/does-not-exist"
[ "$status" -eq 2 ] || { echo "FAIL(6): expected exit 2 on missing root, got $status"; exit 1; }
echo "SUCCESS(6): usage errors report exit 2."

echo "ALL TESTS PASSED"
