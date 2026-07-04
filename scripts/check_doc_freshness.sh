#!/usr/bin/env bash
set -euo pipefail

# Flag a pull request that changes source files but never touches README.md
# or CHANGELOG.md, so documentation drift is caught in CI instead of relying
# on an agent remembering to update docs (constitution AI_WORKFLOW.md,
# DOCUMENTATION.md).
#
# This is governance tooling: a silent bug here would let doc-worthy changes
# through unflagged (see constitution TESTING.md, "Governance Tooling Must Be
# Tested"). It is intentionally a BLUNT tripwire, not smart change detection:
# pure refactors, test-only changes, and dependency bumps will also trip it.
# That is an acceptable false-positive rate at warn-level; see --strict below
# for when a repository is ready to enforce it.
#
# Exit status:
#   0  no doc-worthy source changed, or docs were touched, or (default mode)
#      doc-worthy source changed but docs were not
#   1  doc-worthy source changed and docs were not touched, under --strict
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_doc_freshness.sh [--strict] --base <ref> --head <ref> [project-root]

Description:
  Diff <base>...<head> and flag the pull request when it changes a file
  outside the documentation/lockfile ignore list but never touches README.md
  or CHANGELOG.md. Default mode warns and exits 0; --strict makes it a
  failure. This is a blunt heuristic (see the header comment) — expect
  occasional false positives on pure refactors or test-only changes.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --base <ref>  Base ref of the comparison (required).
  --head <ref>  Head ref of the comparison (required).
  --strict      Fail (exit 1) instead of warning when docs were not touched.
  -h, --help    Show this help.

Ignore list (never counts as "doc-worthy source" on its own):
  README.md, CHANGELOG.md, other root *.md, docs/**, .github/**, dotfiles,
  and common lockfiles (package-lock.json, yarn.lock, Cargo.lock, go.sum,
  poetry.lock, Gemfile.lock).
USAGE
}

strict=false
base=""
head=""
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
    --base)
      [ "$#" -ge 2 ] || { echo "--base requires a value" >&2; usage >&2; exit 2; }
      base=$2
      shift 2
      ;;
    --head)
      [ "$#" -ge 2 ] || { echo "--head requires a value" >&2; usage >&2; exit 2; }
      head=$2
      shift 2
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

if [ -z "$base" ] || [ -z "$head" ]; then
  echo "Both --base and --head are required." >&2
  usage >&2
  exit 2
fi

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)

is_ignored() {
  local path=$1
  # Order matters: case matches top-to-bottom, and a bare `*.md` pattern
  # matches slashes too (case globs aren't path-aware) — so directory-scoped
  # patterns must be checked before the generic root-*.md catch-all below,
  # or `docs/foo.md` would incorrectly stop at `*.md` first.
  case "$path" in
    README.md|CHANGELOG.md) return 0 ;;
    docs/*) return 0 ;;
    .github/*) return 0 ;;
    .*) return 0 ;;
    package-lock.json|yarn.lock|Cargo.lock|go.sum|poetry.lock|Gemfile.lock) return 0 ;;
    *.md) [ "${path#*/}" = "$path" ] && return 0 ;; # any remaining root-level *.md
  esac
  return 1
}

changed_files=()
while IFS= read -r f; do
  [ -n "$f" ] && changed_files+=("$f")
done < <(git -C "$root" diff --name-only "$base...$head" 2>&1)

docs_touched=false
source_changed=()
for f in "${changed_files[@]}"; do
  case "$f" in
    README.md|CHANGELOG.md) docs_touched=true ;;
  esac
  if ! is_ignored "$f"; then
    source_changed+=("$f")
  fi
done

echo "Doc freshness report for: $root ($base...$head)"
echo

if [ "${#source_changed[@]}" -eq 0 ]; then
  echo "  OK  No doc-worthy source changes in this diff."
  exit 0
fi

if [ "$docs_touched" = "true" ]; then
  echo "  OK  Source changed, and README.md/CHANGELOG.md were also touched."
  exit 0
fi

echo "  WARN  Source changed but neither README.md nor CHANGELOG.md was touched:"
for f in "${source_changed[@]}"; do
  echo "    - $f"
done
echo
if [ "$strict" = "true" ]; then
  echo "Failing because --strict was passed."
  exit 1
fi
echo "Not failing (pass --strict to enforce this). This is a blunt heuristic — verify the omission is a real gap before enabling --strict."
exit 0
