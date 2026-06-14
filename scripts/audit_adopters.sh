#!/usr/bin/env bash
set -euo pipefail

# Audit which repositories are behind the latest Eric's Engineering Constitution
# release. Scans the immediate subdirectories of each given parent directory,
# and for every Git repository that adopts the constitution as a `constitution/`
# submodule, reports the pinned version and whether it is current, behind, or
# ahead of the latest release tag the submodule points at.
#
# Exit status is non-zero when at least one repository is behind, so this script
# can also gate a centralized CI job, not just print a report.

usage() {
  cat <<'USAGE'
Usage:
  audit_adopters.sh [--fetch] <parent-directory> [<parent-directory> ...]

Description:
  Report the constitution version status of every adopting repository found one
  level below each parent directory.

Options:
  --fetch   Run `git fetch --tags` inside each submodule before comparing so the
            latest release tag is known. Requires network access.

Exit status:
  0  All discovered repositories are current (or ahead).
  1  At least one repository is behind the latest release.
  2  Usage error.
USAGE
}

fetch=false
if [ "${1:-}" = "--fetch" ]; then
  fetch=true
  shift
fi

if [ "$#" -lt 1 ]; then
  usage
  exit 2
fi

behind_count=0
checked_count=0

report_repo() {
  repo=$1
  sub="$repo/constitution"

  # Only consider repositories that actually adopt the constitution.
  if [ ! -e "$sub/.git" ]; then
    return
  fi

  checked_count=$((checked_count + 1))
  name=$(basename "$repo")

  pinned_version=$(tr -d '[:space:]' < "$sub/VERSION" 2>/dev/null || echo "unknown")

  if [ "$fetch" = "true" ]; then
    git -C "$sub" fetch --tags --force --quiet origin 2>/dev/null || true
  fi

  latest_tag=$(git -C "$sub" tag -l 'v*' --sort=-v:refname 2>/dev/null | head -n 1)

  if [ -z "$latest_tag" ]; then
    printf '%-30s pinned %-10s status UNKNOWN (no release tags%s)\n' \
      "$name" "$pinned_version" "$( [ "$fetch" = "true" ] && echo "" || echo "; try --fetch" )"
    return
  fi

  pinned=$(git -C "$sub" rev-parse HEAD 2>/dev/null || echo "")
  latest=$(git -C "$sub" rev-list -n 1 "$latest_tag" 2>/dev/null || echo "")
  latest_version=$(git -C "$sub" show "$latest_tag:VERSION" 2>/dev/null | tr -d '[:space:]' || echo "$latest_tag")

  if [ "$pinned" = "$latest" ]; then
    printf '%-30s pinned %-10s status CURRENT (%s)\n' "$name" "$pinned_version" "$latest_version"
  elif git -C "$sub" merge-base --is-ancestor "$pinned" "$latest" 2>/dev/null; then
    printf '%-30s pinned %-10s status BEHIND  -> latest %s\n' "$name" "$pinned_version" "$latest_version"
    behind_count=$((behind_count + 1))
  else
    printf '%-30s pinned %-10s status AHEAD/DIVERGED (latest tag %s)\n' "$name" "$pinned_version" "$latest_version"
  fi
}

for parent in "$@"; do
  if [ ! -d "$parent" ]; then
    echo "Skipping non-directory: $parent" >&2
    continue
  fi
  for entry in "$parent"/*; do
    [ -d "$entry" ] || continue
    [ -d "$entry/.git" ] || [ -f "$entry/.git" ] || continue
    report_repo "$entry"
  done
done

echo "---"
echo "Checked $checked_count adopting repositor$( [ "$checked_count" -eq 1 ] && echo "y" || echo "ies" ); $behind_count behind."

if [ "$behind_count" -gt 0 ]; then
  exit 1
fi
exit 0
