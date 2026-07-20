#!/usr/bin/env bash
set -euo pipefail

# Verify that a repository carries the governance files Eric's Engineering
# Constitution expects of an adopting project.
#
# This is governance tooling: a silent bug here removes the guarantee it appears
# to provide (see constitution TESTING.md, "Governance Tooling Must Be Tested").
# Adopters run it through the `constitution/` submodule, for example:
#
#   bash constitution/scripts/check_compliance.sh
#
# Three tiers are checked:
#   - Required: the constitution mandates these for every repository
#     (DOCUMENTATION.md "Required Files") plus the adoption markers the bootstrap
#     script always installs. A missing required entry fails the check.
#   - Recommended: DOCUMENTATION.md "Strongly Encouraged" files. Missing entries
#     are reported as warnings and pass by default; --strict makes them fail.
#   - Product-facing: required only for product-facing repositories; reported as
#     warnings by default and as failures under --product (optionally --strict).
#
# Exit status:
#   0  all required entries present (and, under --strict, all recommended too)
#   1  at least one required entry missing (or a recommended/product gap in
#      the corresponding strict mode)
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_compliance.sh [--strict] [--product] [project-root]

Description:
  Confirm that an adopting repository carries the governance files Eric's
  Engineering Constitution expects.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --strict    Treat missing recommended files as failures, not warnings.
  --product   Treat the product-facing files (docs/PRODUCT_REQUIREMENTS.md and
              docs/REQUIREMENTS_TRACEABILITY.md) as required.
  -h, --help  Show this help.

Tiers:
  Required      README.md, docs/HELP.md, CHANGELOG.md, TODO.md,
                .github/SECURITY.md, AGENTS.md, VERSION,
                constitution/ (submodule).
  Recommended   .github/CONTRIBUTING.md, docs/SETUP.md, docs/COMMAND_REFERENCE.md,
                docs/TROUBLESHOOTING.md, docs/ARCHITECTURE.md, docs/adr/,
                docs/AGENT_PROMPTS.md, docs/AGENT_HANDOFF.md, docs/OPERATIONS.md,
                docs/TEST_PLAN.md, docs/OTS_SOFTWARE.md, docs/SESSION_PLAN.md,
                docs/MEMORY.md, docs/ENV_VARS.md.
  Product       docs/PRODUCT_REQUIREMENTS.md, docs/REQUIREMENTS_TRACEABILITY.md.

Relocated files:
  HELP.md, SECURITY.md, CONTRIBUTING.md, and SYSTEM_PROMPT.md moved out of the
  repository root in v1.38.0. The original root locations are still accepted, so
  repositories that adopted earlier keep passing without changes.

Vendor instruction files:
  CLAUDE.md, .cursorrules, .goosehints and friends are opt-in per tool via
  `bootstrap.sh --agents`, so they are not checked. AGENTS.md is the
  cross-vendor file every adopting repository must carry.
USAGE
}

strict=false
product=false
root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --strict)
      strict=true
      shift
      ;;
    --product)
      product=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [ -n "$root" ]; then
        echo "Unexpected extra argument: $1" >&2
        exit 2
      fi
      root=$1
      shift
      ;;
  esac
done

root=${root:-.}

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)

# Files the constitution mandates for every adopting repository: the
# DOCUMENTATION.md "Required Files" plus the adoption markers the bootstrap
# script always installs.
required=(
  README.md
  docs/HELP.md
  CHANGELOG.md
  TODO.md
  .github/SECURITY.md
  AGENTS.md
  VERSION
  constitution
)

# Files the constitution relocated in v1.38.0 to keep an adopting repository's
# root file listing short. Repositories that adopted earlier keep the original
# root location, so both are accepted and whichever exists is reported.
relocated_alternate() {
  case "$1" in
    docs/HELP.md)             echo "HELP.md" ;;
    .github/SECURITY.md)      echo "SECURITY.md" ;;
    .github/CONTRIBUTING.md)  echo "CONTRIBUTING.md" ;;
    docs/SYSTEM_PROMPT.md)    echo "SYSTEM_PROMPT.md" ;;
    *)                        echo "" ;;
  esac
}

# Echo the path that actually exists for an entry, preferring the current layout
# and falling back to the pre-1.38.0 root location. Returns non-zero when
# neither exists, echoing the current-layout path so messages name the target.
resolve_entry() {
  local entry=$1 alt

  if [ -e "$root/$entry" ]; then
    printf '%s' "$entry"
    return 0
  fi

  alt=$(relocated_alternate "$entry")

  if [ -n "$alt" ] && [ -e "$root/$alt" ]; then
    printf '%s' "$alt"
    return 0
  fi

  printf '%s' "$entry"
  return 1
}

# DOCUMENTATION.md "Strongly Encouraged" files.
# Vendor instruction files (CLAUDE.md, .cursorrules, .goosehints, ...) are
# deliberately absent: they are opt-in per tool via `bootstrap.sh --agents`, so
# their absence carries no signal. AGENTS.md above is the cross-vendor file every
# adopting repository must have.
recommended=(
  .github/CONTRIBUTING.md
  docs/SETUP.md
  docs/COMMAND_REFERENCE.md
  docs/TROUBLESHOOTING.md
  docs/ARCHITECTURE.md
  docs/adr
  docs/AGENT_PROMPTS.md
  docs/AGENT_HANDOFF.md
  docs/OPERATIONS.md
  docs/TEST_PLAN.md
  docs/OTS_SOFTWARE.md
  docs/SESSION_PLAN.md
  docs/MEMORY.md
  docs/ENV_VARS.md
)

# docs/SESSION_PLAN.md, docs/MEMORY.md, and docs/ENV_VARS.md are deliberately
# placeholder-shaped (or empty/pre-populated with templates) when not in active 
# use or newly created -- unlike other recommended files, their placeholder 
# content does not indicate neglect, so they are exempted from the placeholder check.
recommended_skip_placeholder_check() {
  [ "$1" = "docs/SESSION_PLAN.md" ] || [ "$1" = "docs/MEMORY.md" ] || [ "$1" = "docs/ENV_VARS.md" ]
}

# Required only for product-facing repositories.
product_files=(
  docs/PRODUCT_REQUIREMENTS.md
  docs/REQUIREMENTS_TRACEABILITY.md
)

contains_placeholder_content() {
  local file=$1

  grep -Eq \
    '(<add here>|<command>|<YYYY-MM-DD>|<untested behavior>|<requirement description>|describe the observable condition|Briefly describe the product, target users, and current release goal|# e.g., make doctor|<!--)' \
    "$file"
}

required_missing=0
recommended_missing=0
product_missing=0

echo "Compliance report for: $root"
echo

echo "Required:"
for f in "${required[@]}"; do
  if found=$(resolve_entry "$f"); then
    echo "  OK       $found"
  else
    echo "  MISSING  $f (required)"
    required_missing=$((required_missing + 1))
  fi
done

echo
echo "Recommended:"
for f in "${recommended[@]}"; do
  if found=$(resolve_entry "$f"); then
    if [ -f "$root/$found" ] && ! recommended_skip_placeholder_check "$f" && contains_placeholder_content "$root/$found"; then
      if [ "$strict" = "true" ]; then
        echo "  MISSING  $found (recommended placeholder, --strict)"
      else
        echo "  WARN     $found (recommended placeholder)"
      fi
      recommended_missing=$((recommended_missing + 1))
    else
      echo "  OK       $found"
    fi
  else
    if [ "$strict" = "true" ]; then
      echo "  MISSING  $f (recommended, --strict)"
    else
      echo "  WARN     $f (recommended)"
    fi
    recommended_missing=$((recommended_missing + 1))
  fi
done

echo
if [ "$product" = "true" ]; then
  echo "Product-facing (required by --product):"
else
  echo "Product-facing (recommended for product-facing repositories):"
fi
for f in "${product_files[@]}"; do
  if [ -e "$root/$f" ]; then
    if [ -f "$root/$f" ] && contains_placeholder_content "$root/$f"; then
      if [ "$product" = "true" ]; then
        echo "  MISSING  $f (product placeholder, --product)"
      else
        echo "  WARN     $f (product placeholder)"
      fi
      product_missing=$((product_missing + 1))
    else
      echo "  OK       $f"
    fi
  else
    if [ "$product" = "true" ]; then
      echo "  MISSING  $f (product, --product)"
    else
      echo "  WARN     $f (product-facing)"
    fi
    product_missing=$((product_missing + 1))
  fi
done

echo
echo "Required missing: $required_missing; recommended missing: $recommended_missing; product missing: $product_missing."

fail=0
[ "$required_missing" -gt 0 ] && fail=1
[ "$strict" = "true" ] && [ "$recommended_missing" -gt 0 ] && fail=1
[ "$product" = "true" ] && [ "$product_missing" -gt 0 ] && fail=1

if [ "$fail" -ne 0 ]; then
  exit 1
fi
exit 0
