#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
CHECK_SCRIPT="$SCRIPT_DIR/check_compliance.sh"
TMPDIR=$(mktemp -d)
STRICT_OUT="$TMPDIR/strict.out"
PRODUCT_OUT="$TMPDIR/product.out"
trap 'rm -rf "$TMPDIR"' EXIT

make_repo() {
  local root=$1

  mkdir -p "$root/docs/adr" "$root/constitution"
  touch \
    "$root/README.md" \
    "$root/HELP.md" \
    "$root/CHANGELOG.md" \
    "$root/TODO.md" \
    "$root/SECURITY.md" \
    "$root/AGENTS.md" \
    "$root/CLAUDE.md" \
    "$root/VERSION" \
    "$root/docs/SETUP.md" \
    "$root/docs/COMMAND_REFERENCE.md" \
    "$root/docs/TROUBLESHOOTING.md" \
    "$root/docs/ARCHITECTURE.md" \
    "$root/docs/AGENT_PROMPTS.md" \
    "$root/docs/AGENT_HANDOFF.md" \
    "$root/docs/OPERATIONS.md" \
    "$root/docs/TEST_PLAN.md" \
    "$root/docs/OTS_SOFTWARE.md"
}

assert_contains() {
  local haystack=$1
  local needle=$2

  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: expected output to contain: $needle" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

repo="$TMPDIR/recommended-placeholder"
make_repo "$repo"
cat > "$repo/docs/SETUP.md" <<'EOF'
# Setup

<!-- Add install steps here -->
EOF

output=$("$CHECK_SCRIPT" "$repo")
assert_contains "$output" "WARN     docs/SETUP.md (recommended placeholder)"

if "$CHECK_SCRIPT" --strict "$repo" >"$STRICT_OUT" 2>&1; then
  echo "FAIL: --strict should fail on recommended placeholder content" >&2
  exit 1
fi
strict_output=$(cat "$STRICT_OUT")
assert_contains "$strict_output" "MISSING  docs/SETUP.md (recommended placeholder, --strict)"

product_repo="$TMPDIR/product-placeholder"
make_repo "$product_repo"
cat > "$product_repo/docs/PRODUCT_REQUIREMENTS.md" <<'EOF'
# Product Requirements

Briefly describe the product, target users, and current release goal.
EOF
cat > "$product_repo/docs/REQUIREMENTS_TRACEABILITY.md" <<'EOF'
# Requirements Traceability

| Requirement | Description |
| --- | --- |
| FR-001 | <requirement description> |
EOF

product_output=$("$CHECK_SCRIPT" "$product_repo")
assert_contains "$product_output" "WARN     docs/PRODUCT_REQUIREMENTS.md (product placeholder)"
assert_contains "$product_output" "WARN     docs/REQUIREMENTS_TRACEABILITY.md (product placeholder)"

if "$CHECK_SCRIPT" --product "$product_repo" >"$PRODUCT_OUT" 2>&1; then
  echo "FAIL: --product should fail on product placeholder content" >&2
  exit 1
fi
product_strict_output=$(cat "$PRODUCT_OUT")
assert_contains "$product_strict_output" "MISSING  docs/PRODUCT_REQUIREMENTS.md (product placeholder, --product)"
assert_contains "$product_strict_output" "MISSING  docs/REQUIREMENTS_TRACEABILITY.md (product placeholder, --product)"

# docs/SESSION_PLAN.md is deliberately placeholder-shaped between sessions
# (it's cleared/overwritten at the start of each one), unlike every other
# recommended file where placeholder content means "never customized" -- so
# it must be exempt from this check even when full of <!-- --> comments.
session_plan_repo="$TMPDIR/session-plan-placeholder"
make_repo "$session_plan_repo"
cat > "$session_plan_repo/docs/SESSION_PLAN.md" <<'EOF'
# Session Plan

## Goal

<!-- What does this session aim to accomplish? Be specific. -->
EOF

session_plan_output=$("$CHECK_SCRIPT" "$session_plan_repo")
assert_contains "$session_plan_output" "OK       docs/SESSION_PLAN.md"
if [[ "$session_plan_output" == *"docs/SESSION_PLAN.md (recommended placeholder)"* ]]; then
  echo "FAIL: docs/SESSION_PLAN.md should not be flagged as a placeholder" >&2
  exit 1
fi

if ! "$CHECK_SCRIPT" --strict "$session_plan_repo" >/dev/null 2>&1; then
  echo "FAIL: --strict should not fail on docs/SESSION_PLAN.md placeholder content" >&2
  exit 1
fi

echo "PASS: placeholder documentation is flagged correctly"
