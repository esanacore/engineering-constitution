#!/usr/bin/env bash
set -euo pipefail

# Analyze repository history to suggest a retroactive Semantic Version.
#
# This script looks at Git tags, CHANGELOG.md, and commit messages to
# recommend the current project version and any necessary bumps.

usage() {
  cat <<'USAGE'
Usage:
  version_analyzer.sh <project-path>

Description:
  Suggest the next Semantic Version for a repository from the Conventional
  Commit prefixes in its history since the latest tag (see RELEASES.md,
  "Commit Messages"): a `!` after the type or a "BREAKING CHANGE" footer
  suggests MAJOR, `feat:` suggests MINOR, `fix:` suggests PATCH. Prefixes are
  matched at the start of a line, so a commit that merely mentions the word
  "fix" (or "prefix") does not count.
USAGE
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [ "$#" -ne 1 ]; then
  usage >&2
  exit 2
fi

project_path=$1

if [ ! -d "$project_path/.git" ]; then
  echo "Error: $project_path is not a Git repository."
  exit 1
fi

cd "$project_path"

echo "--- Version Analysis Report ---"
echo "Project: $(basename "$project_path")"

# 1. Check for current VERSION file
if [ -f "VERSION" ]; then
  current_version=$(cat VERSION)
  echo "Current VERSION file: $current_version"
else
  echo "Current VERSION file: MISSING"
  current_version="0.0.0"
fi

# 2. Check for latest Git tag
latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "None")
echo "Latest Git tag: $latest_tag"

# 3. Analyze commits since last tag (or start of time)
if [ "$latest_tag" = "None" ]; then
  commit_range="HEAD"
else
  commit_range="$latest_tag..HEAD"
fi

echo "Analyzing commits in range: $commit_range"

# Conventional Commit prefixes, anchored at the start of a line: `type(scope)!:`
# or a BREAKING CHANGE footer for MAJOR; `feat(scope)?:` for MINOR;
# `fix(scope)?:` for PATCH. Unanchored matching counted "prefix cleanup" as a
# fix and any commit containing "!" as breaking.
breaking_changes=$(git log "$commit_range" --extended-regexp --grep='^[A-Za-z]+(\([^)]*\))?!:' --grep='^BREAKING CHANGE:' --oneline | wc -l | tr -d ' ')
features=$(git log "$commit_range" --extended-regexp --grep='^feat(\([^)]*\))?!?:' --oneline | wc -l | tr -d ' ')
fixes=$(git log "$commit_range" --extended-regexp --grep='^fix(\([^)]*\))?!?:' --oneline | wc -l | tr -d ' ')

echo "Potential Breaking Changes (MAJOR): $breaking_changes"
echo "Potential New Features (MINOR): $features"
echo "Potential Bug Fixes (PATCH): $fixes"

# 4. Recommendation Logic
suggested_version="$current_version"

if [ "$breaking_changes" -gt 0 ]; then
  echo "Recommendation: MAJOR bump required due to breaking changes."
elif [ "$features" -gt 0 ]; then
  echo "Recommendation: MINOR bump suggested for new features."
elif [ "$fixes" -gt 0 ]; then
  echo "Recommendation: PATCH bump suggested for fixes."
else
  echo "Recommendation: No version change detected since $latest_tag."
fi

echo "-------------------------------"
echo "To apply a version, run:"
echo "echo 'X.Y.Z' > VERSION && git add VERSION && git commit -m 'chore(release): cut X.Y.Z'"
