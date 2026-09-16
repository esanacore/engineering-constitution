#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/version_analyzer.sh: the suggestion must come from
# Conventional Commit prefixes at the start of a line, not from the words
# "feat"/"fix"/"!" appearing anywhere in a message.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
analyzer="$script_dir/version_analyzer.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

repo="$tmp/repo"
mkdir -p "$repo" && cd "$repo"
git init -q && git config user.email t@example.com && git config user.name T
echo 1.2.3 > VERSION && git add VERSION && git commit -q -m "chore(release): cut 1.2.3" && git tag v1.2.3

commit() { echo "$RANDOM" >> f && git add f && git commit -q -m "$1"; }

echo "Test 1: no conventional commits since the tag -> no change"
commit "prefix cleanup in the parser"            # contains "fix" but is not a fix
commit "update docs, feature list unchanged!"     # contains "feat" and "!" but is neither
out=$("$analyzer" "$repo")
grep -q 'Potential Breaking Changes (MAJOR): 0' <<< "$out" || { echo "$out"; fail "an exclamation mark in prose counted as breaking"; }
grep -q 'Potential New Features (MINOR): 0' <<< "$out" || { echo "$out"; fail "'feature' in prose counted as feat:"; }
grep -q 'Potential Bug Fixes (PATCH): 0' <<< "$out" || { echo "$out"; fail "'prefix' counted as fix:"; }
grep -q 'No version change detected' <<< "$out" || { echo "$out"; fail "expected no-change recommendation"; }
echo "PASS"

echo "Test 2: fix: suggests PATCH; feat(scope): suggests MINOR"
commit "fix: handle empty input"
out=$("$analyzer" "$repo"); grep -q 'PATCH bump suggested' <<< "$out" || { echo "$out"; fail "fix: not recognized"; }
commit "feat(parser): support comments"
out=$("$analyzer" "$repo"); grep -q 'MINOR bump suggested' <<< "$out" || { echo "$out"; fail "feat(scope): not recognized"; }
grep -q 'Potential Bug Fixes (PATCH): 1' <<< "$out" || { echo "$out"; fail "fix count wrong"; }
echo "PASS"

echo "Test 3: feat!: and a BREAKING CHANGE footer suggest MAJOR"
commit "feat!: drop the v1 endpoint"
out=$("$analyzer" "$repo"); grep -q 'MAJOR bump required' <<< "$out" || { echo "$out"; fail "feat!: not recognized as breaking"; }
git commit -q --allow-empty -m "refactor: new storage layout" -m "BREAKING CHANGE: the on-disk format changed"
out=$("$analyzer" "$repo"); grep -q 'Potential Breaking Changes (MAJOR): 2' <<< "$out" || { echo "$out"; fail "BREAKING CHANGE footer not counted"; }
echo "PASS"

echo "Test 4: --help exits 0; usage errors exit 2"
"$analyzer" --help | grep -q '^Usage:' || fail "--help printed no usage"
status=0; "$analyzer" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing argument exited $status, expected 2"
echo "PASS"

echo "ALL TESTS PASSED"
