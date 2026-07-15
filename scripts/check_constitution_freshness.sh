#!/usr/bin/env bash
set -euo pipefail

# Check whether a single repository's `constitution/` submodule is pinned to
# the latest tagged release of Eric's Engineering Constitution.
#
# This is the single-repository counterpart to `audit_adopters.sh` (which
# scans a fleet of repositories). It exists so an adopting repository can wire
# it into something that runs the instant a session starts — most commonly a
# Claude Code SessionStart hook (see `templates/.claude/settings.json`, which
# `scripts/bootstrap.sh` installs) — so an agent knows, before doing anything
# else, whether it must update the constitution first. See INTEGRATION.md
# "Keeping Adopters On the Latest Version Automatically."
#
# Unlike `audit_adopters.sh` (where `--fetch` is opt-in because it multiplies
# across every scanned repository), this script fetches by default: a single
# repository's fetch is cheap, and a session-start freshness check that only
# ever compares against stale local tags would defeat the point.

usage() {
  cat <<'USAGE'
Usage:
  check_constitution_freshness.sh [--no-fetch] [<repository-path>]

Description:
  Report whether <repository-path>'s (default: current directory)
  `constitution/` submodule is pinned to the latest `v*` release tag.

Options:
  --no-fetch   Skip `git fetch --tags` and compare against whatever tags are
               already known locally. Use for offline runs or tests.

Exit status:
  0  Current, ahead, or diverged from tag history.
  1  Behind the latest release.
  2  Unknown (no repository, no constitution/ submodule, or no release tags
     found even after fetching).
USAGE
}

fetch=true
repo="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --no-fetch)
      fetch=false
      shift
      ;;
    --fetch)
      # Accepted for symmetry with audit_adopters.sh; fetching is already the
      # default here.
      fetch=true
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      repo=$1
      shift
      ;;
  esac
done

sub="$repo/constitution"

if [ ! -e "$sub/.git" ]; then
  echo "No constitution/ submodule found at $sub; nothing to check."
  exit 2
fi

pinned_version=$(tr -d '[:space:]' < "$sub/VERSION" 2>/dev/null || echo "unknown")

if [ "$fetch" = "true" ]; then
  git -C "$sub" fetch --tags --force --quiet origin 2>/dev/null || true
fi

latest_tag=$(git -C "$sub" tag -l 'v*' --sort=-v:refname 2>/dev/null | head -n 1)

if [ -z "$latest_tag" ]; then
  echo "Eric's Engineering Constitution: UNKNOWN (pinned v$pinned_version) -- no release tags found locally$( [ "$fetch" = "true" ] && echo "." || echo "; re-run without --no-fetch." )"
  exit 2
fi

pinned=$(git -C "$sub" rev-parse HEAD 2>/dev/null || echo "")
latest=$(git -C "$sub" rev-list -n 1 "$latest_tag" 2>/dev/null || echo "")
latest_version=$(git -C "$sub" show "$latest_tag:VERSION" 2>/dev/null | tr -d '[:space:]' || echo "$latest_tag")

if [ "$pinned" = "$latest" ]; then
  echo "Eric's Engineering Constitution: CURRENT (v$pinned_version)."
  exit 0
elif git -C "$sub" merge-base --is-ancestor "$pinned" "$latest" 2>/dev/null; then
  cat <<EOF
Eric's Engineering Constitution: BEHIND -- pinned v$pinned_version, latest v$latest_version.

Before other work this session, update the submodule and follow the migration
checklist in constitution/INTEGRATION.md ("Migrating Existing Repositories to
New Framework Versions"):

  git submodule update --remote constitution
  cat constitution/CHANGELOG.md   # review what changed
  git add constitution
  git commit -m "Update Eric's engineering constitution to \$(cat constitution/VERSION)"
EOF
  exit 1
else
  echo "Eric's Engineering Constitution: AHEAD/DIVERGED (pinned v$pinned_version, latest tag v$latest_version)."
  exit 0
fi
