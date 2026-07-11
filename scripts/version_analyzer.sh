#!/usr/bin/env bash
set -euo pipefail

# Analyze repository history to suggest a retroactive Semantic Version.
#
# This script looks at Git tags, CHANGELOG.md, and commit messages to
# recommend the current project version and any necessary bumps.

usage() {
  echo "Usage: version_analyzer.sh <project-path>"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
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

breaking_changes=$(git log "$commit_range" --grep="BREAKING CHANGE" --grep="!" --oneline | wc -l)
features=$(git log "$commit_range" --grep="feat" --oneline | wc -l)
fixes=$(git log "$commit_range" --grep="fix" --oneline | wc -l)

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
echo "echo 'X.Y.Z' > VERSION && git add VERSION && git commit -m 'chore: bump version to X.Y.Z'"
