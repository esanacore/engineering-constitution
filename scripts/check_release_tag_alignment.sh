#!/usr/bin/env bash
set -euo pipefail

# Verify that this repository's release metadata and Git tags agree.
#
# Usage:
#   bash scripts/check_release_tag_alignment.sh [repo-root]
#
# The checker verifies:
#   - `VERSION` exists and is non-empty.
#   - A matching `v<VERSION>` tag exists.
#   - The matching tag points at HEAD.
#   - The matching tag is the latest semantic-version tag in the repository.
#
# Exit status:
#   0  alignment looks correct
#   1  at least one mismatch was found
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_release_tag_alignment.sh [repo-root]

Description:
  Confirm that VERSION, the matching release tag, and HEAD stay aligned in the
  constitution source repository.

Arguments:
  repo-root   Path to the repository root to check. Default: current directory.
USAGE
}

root=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
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
  echo "Repository root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)

if ! git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Not a Git repository: $root" >&2
  exit 2
fi

version_file="$root/VERSION"
if [ ! -f "$version_file" ]; then
  echo "Missing VERSION under: $root" >&2
  exit 1
fi

expected_version=$(tr -d '[:space:]' < "$version_file")
if [ -z "$expected_version" ]; then
  echo "VERSION is empty under: $root" >&2
  exit 1
fi

expected_tag="v$expected_version"
latest_tag=$(git -C "$root" tag --sort=-version:refname | head -n 1 || true)
head_tags=$(git -C "$root" tag --points-at HEAD || true)

echo "Release tag alignment report for: $root"
echo "Expected version: $expected_version"
echo "Expected tag: $expected_tag"
echo "Latest tag: ${latest_tag:-<none>}"
echo

fail=0

if git -C "$root" rev-parse --verify --quiet "refs/tags/$expected_tag" >/dev/null; then
  echo "  OK       Tag $expected_tag exists."
else
  echo "  MISMATCH Tag $expected_tag does not exist."
  fail=1
fi

if printf '%s\n' "$head_tags" | grep -Fxq "$expected_tag"; then
  echo "  OK       HEAD is tagged with $expected_tag."
else
  echo "  MISMATCH HEAD is not tagged with $expected_tag."
  fail=1
fi

if [ -z "$latest_tag" ]; then
  echo "  MISMATCH Repository has no release tags."
  fail=1
elif [ "$latest_tag" = "$expected_tag" ]; then
  echo "  OK       Latest release tag matches VERSION."
else
  echo "  MISMATCH Latest release tag is $latest_tag (expected $expected_tag)."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "  OK       VERSION, HEAD, and the latest release tag are aligned."
exit 0
