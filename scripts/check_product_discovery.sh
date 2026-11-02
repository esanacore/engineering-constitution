#!/usr/bin/env bash
set -euo pipefail

# Structural and freshness checks only; this cannot certify a product or a person.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -f "$script_dir/lib/ci_annotations.sh" ]; then
  # shellcheck source=lib/ci_annotations.sh
  . "$script_dir/lib/ci_annotations.sh"
else
  ci_annotate() { :; }
fi

usage() {
  cat <<'USAGE'
Usage:
  check_product_discovery.sh [--strict] [project-root]

Check the optional discovery review package against the current product
requirements revision and line-ending-normalized Git blob hash. It checks the review's declared
records, unknowns and changed-requirement evidence for structural consistency.
It cannot verify identities, evidence, product quality or test outcomes.
A project with neither discovery review nor requirements is skipped. A missing
review is also skipped unless --strict is used; an incomplete package is a
finding. Findings warn by default and fail with --strict.

Options:
  --strict    Fail on findings and on an absent review package.
  -h, --help  Show this help.

Exit status: 0 for valid, warning or skipped; 1 for strict findings;
2 for usage or input errors.
USAGE
}
strict=false
root=''
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --strict) strict=true; shift ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) if [ -n "$root" ]; then echo "Unexpected extra argument: $1" >&2; exit 2; fi; root=$1; shift ;;
  esac
done
if [ "$#" -gt 0 ]; then
  if [ -n "$root" ] || [ "$#" -ne 1 ]; then echo 'Unexpected extra argument' >&2; exit 2; fi
  root=$1
fi
root=${root:-.}
if [ ! -d "$root" ]; then echo "Project root not found: $root" >&2; exit 2; fi
root=$(CDPATH= cd -- "$root" && pwd)
review="$root/docs/discovery/REVIEW.md"
requirements="$root/docs/PRODUCT_REQUIREMENTS.md"
echo 'Product discovery check: structural consistency and freshness only; identities, evidence, product quality, and test outcomes require human review.'
findings=''
if [ ! -f "$review" ]; then
  if [ "$strict" = false ]; then echo 'No optional discovery review; skipped.'; exit 0; fi
  findings='No optional discovery review at docs/discovery/REVIEW.md.'
elif [ ! -f "$requirements" ]; then
  findings='Discovery review exists but docs/PRODUCT_REQUIREMENTS.md is missing.'
else
  if ! command -v git >/dev/null 2>&1; then echo 'Git is required to compute the requirements blob hash.' >&2; exit 2; fi
  if ! digest=$(sed $'s/\r$//' "$requirements" | git -C "$root" hash-object --stdin); then
    echo 'Cannot compute the requirements blob hash.' >&2; exit 2
  fi
  if [ ! -f "$script_dir/lib/product_discovery.awk" ]; then echo 'Missing lib/product_discovery.awk.' >&2; exit 2; fi
  findings=$(awk -v digest="$digest" -f "$script_dir/lib/product_discovery.awk" "$requirements" "$review") || exit 2
fi
if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  if [ "$strict" = true ]; then
    ci_annotate error "check_product_discovery.sh: discovery review has structural or freshness findings"
    exit 1
  fi
  ci_annotate warning "check_product_discovery.sh: discovery review has structural or freshness findings"
  echo 'Warnings only; use --strict to enforce.'
else
  echo 'No structural or freshness findings.'
fi