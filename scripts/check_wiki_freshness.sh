#!/usr/bin/env bash
set -euo pipefail

# Flag a pull request that ADDS or REMOVES source files -- a structural change
# to what the repository contains -- without touching the wiki that catalogues
# them (constitution DOCUMENTATION.md "Wiki", AI_WORKFLOW.md, ADR-0001).
#
# This is deliberately a HIGHER bar than scripts/check_doc_freshness.sh, not a
# duplicate of it. doc-freshness asks "did any source change update
# README.md/CHANGELOG.md?"; this asks the narrower, wiki-shaped question "did
# the set of things this repository contains change -- a file appeared or
# disappeared -- without the wiki being updated?". Modifying existing files
# never trips this checker; only additions and deletions do, because a wiki is
# a high-altitude catalogue of capabilities, not a per-line mirror of the code.
#
# It is still a blunt tripwire: adding or removing a non-capability file (a new
# fixture, a renamed helper) will sometimes trip it. That is an acceptable
# false-positive rate at warn-level; see --strict for when a repository is
# ready to enforce it. Test files are excluded from the trigger, since a test
# added beside the code it covers is not new surface area for the wiki.
#
# This is governance tooling: a silent bug here would let capability-worthy
# additions through unflagged (see constitution TESTING.md, "Governance Tooling
# Must Be Tested").
#
# Exit status:
#   0  no structural source change, or the wiki was touched, or (default mode)
#      structural source changed but the wiki was not
#   1  structural source changed and the wiki was not touched, under --strict
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_wiki_freshness.sh [--strict] [--wiki-dir <dir>] --base <ref> --head <ref> [project-root]

Description:
  Diff <base>...<head> and flag the pull request when it ADDS or REMOVES a file
  outside the ignore list but never touches anything under the wiki directory
  (default: wiki/). Files that are only modified never trip this check -- that
  is what makes it a distinct, higher bar than check_doc_freshness.sh. Default
  mode warns and exits 0; --strict makes it a failure. This is a blunt
  heuristic (see the header comment) -- expect occasional false positives when
  a non-capability file is added or removed.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Options:
  --base <ref>       Base ref of the comparison (required).
  --head <ref>       Head ref of the comparison (required).
  --wiki-dir <dir>   Directory holding wiki pages, relative to the root.
                     Default: wiki
  --strict           Fail (exit 1) instead of warning when the wiki was not touched.
  -h, --help         Show this help.

Ignore list (an added/removed file here never counts as "structural source"):
  the wiki directory itself, docs/**, .github/**, dotfiles, common lockfiles,
  and test files (test_*, *_test.*, *.test.*, *_spec.*, *.spec.*, and files
  under tests/, spec/, or __tests__/).
USAGE
}

strict=false
base=""
head=""
root=""
wiki_dir="wiki"

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
    --wiki-dir)
      [ "$#" -ge 2 ] || { echo "--wiki-dir requires a value" >&2; usage >&2; exit 2; }
      wiki_dir=${2%/}
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

if [ -z "$wiki_dir" ]; then
  echo "--wiki-dir must not be empty." >&2
  exit 2
fi

if [ ! -d "$root" ]; then
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)

# Is this path exempt from counting as "structural source" on its own? The
# wiki directory is passed in, so it is checked first with a variable prefix;
# the rest mirror check_doc_freshness.sh's ignore list plus test files.
is_ignored() {
  local path=$1
  case "$path" in
    "$wiki_dir"/*) return 0 ;;
    docs/*) return 0 ;;
    .github/*) return 0 ;;
    .*) return 0 ;;
    package-lock.json|yarn.lock|Cargo.lock|go.sum|poetry.lock|Gemfile.lock) return 0 ;;
    # Test files: added beside the code they cover, not new wiki surface area.
    test_*|*/test_*) return 0 ;;
    *_test.*|*.test.*|*_spec.*|*.spec.*) return 0 ;;
    tests/*|*/tests/*|spec/*|*/spec/*|__tests__/*|*/__tests__/*) return 0 ;;
  esac
  return 1
}

# Any change under the wiki directory (added, modified, or deleted) counts as
# "the wiki was touched".
wiki_touched=false
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    "$wiki_dir"/*) wiki_touched=true ;;
  esac
done < <(git -C "$root" diff --name-only "$base...$head" 2>&1)

# Only additions and deletions are candidates for a "structural" change.
structural_changed=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if ! is_ignored "$f"; then
    structural_changed+=("$f")
  fi
done < <(git -C "$root" diff --diff-filter=AD --name-only "$base...$head" 2>&1)

echo "Wiki freshness report for: $root ($base...$head)"
echo "Wiki directory: $wiki_dir/"
echo

if [ "${#structural_changed[@]}" -eq 0 ]; then
  echo "  OK  No files added or removed outside the ignore list in this diff."
  exit 0
fi

if [ "$wiki_touched" = "true" ]; then
  echo "  OK  Files were added/removed, and the wiki was also updated."
  exit 0
fi

echo "  WARN  Files were added or removed but nothing under $wiki_dir/ was updated:"
for f in "${structural_changed[@]}"; do
  echo "    - $f"
done
echo
if [ "$strict" = "true" ]; then
  echo "Failing because --strict was passed."
  exit 1
fi
echo "Not failing (pass --strict to enforce this). This is a blunt heuristic -- confirm whether the added/removed surface belongs in the wiki before enabling --strict."
exit 0
