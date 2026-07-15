#!/usr/bin/env bash
set -euo pipefail

# Verify that adopter-facing constitution version references stay aligned with
# the actual pinned constitution version.
#
# Adopters run it through the `constitution/` submodule, for example:
#
#   bash constitution/scripts/check_version_alignment.sh
#
# The checker verifies:
#   - `constitution/VERSION` exists.
#   - `CONSTITUTION_VERSION` (when present) matches `constitution/VERSION`.
#   - Common governance files do not contain a different semantic version on the
#     same line as "constitution".
#
# Exit status:
#   0  alignment looks correct
#   1  at least one mismatch was found
#   2  usage or input error

usage() {
  cat <<'USAGE'
Usage:
  check_version_alignment.sh [project-root]

Description:
  Confirm that an adopting repository's constitution version references match
  the actual `constitution/VERSION` value.

Arguments:
  project-root   Path to the repository root to check. Default: current directory.

Checks:
  - `constitution/VERSION` must exist.
  - `CONSTITUTION_VERSION` (if present) must equal `constitution/VERSION`.
  - Common governance files must not mention a different semantic version on a
    line that also references the constitution.

Scanned files when present:
  README.md, AGENTS.md, CLAUDE.md, CONTRIBUTING.md, SYSTEM_PROMPT.md,
  docs/SETUP.md, docs/INDEX.md, docs/AGENT_HANDOFF.md, docs/AGENT_PROMPTS.md,
  demo.html, docs/governance/*.md.
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
  echo "Project root not found or not a directory: $root" >&2
  exit 2
fi

root=$(CDPATH= cd -- "$root" && pwd)
constitution_version_file="$root/constitution/VERSION"

if [ ! -f "$constitution_version_file" ]; then
  echo "Missing constitution/VERSION under: $root" >&2
  exit 1
fi

expected_version=$(tr -d '[:space:]' < "$constitution_version_file")
if [ -z "$expected_version" ]; then
  echo "constitution/VERSION is empty under: $root" >&2
  exit 1
fi

echo "Version alignment report for: $root"
echo "Expected constitution version: $expected_version"
echo

fail=0

if [ -f "$root/CONSTITUTION_VERSION" ]; then
  declared_version=$(tr -d '[:space:]' < "$root/CONSTITUTION_VERSION")
  if [ "$declared_version" = "$expected_version" ]; then
    echo "  OK       CONSTITUTION_VERSION matches $expected_version"
  else
    echo "  MISMATCH CONSTITUTION_VERSION declares $declared_version (expected $expected_version)"
    fail=1
  fi
fi

candidate_files=(
  README.md
  AGENTS.md
  CLAUDE.md
  CONTRIBUTING.md
  SYSTEM_PROMPT.md
  docs/SETUP.md
  docs/INDEX.md
  docs/AGENT_HANDOFF.md
  docs/AGENT_PROMPTS.md
  demo.html
)

for file in "$root"/docs/governance/*.md; do
  if [ -f "$file" ]; then
    candidate_files+=("${file#$root/}")
  fi
done

for relative_path in "${candidate_files[@]}"; do
  full_path="$root/$relative_path"
  [ -f "$full_path" ] || continue

  while IFS= read -r match; do
    [ -n "$match" ] || continue
    line_number=${match%%:*}
    line_text=${match#*:}
    version_found=$(printf '%s\n' "$line_text" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
    [ -n "$version_found" ] || continue

    if [ "$version_found" != "$expected_version" ]; then
      echo "  MISMATCH $relative_path:$line_number mentions $version_found -> $line_text"
      fail=1
    fi
  done < <(
    grep -nEi '.*constitution.*([0-9]+\.[0-9]+\.[0-9]+).*|.*([0-9]+\.[0-9]+\.[0-9]+).*constitution.*' "$full_path" || true
  )
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "  OK       No stale constitution version references found in scanned governance files."
exit 0
