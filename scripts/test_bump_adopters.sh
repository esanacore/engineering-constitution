#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/bump_adopters.sh against local bare repositories standing
# in for GitHub remotes. The pull-request step is exercised only in --no-pr
# form here (GAP-001 in docs/TEST_PLAN.md).

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
bump="$script_dir/bump_adopters.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

gitc() { git -c user.name=T -c user.email=t@example.com "$@"; }

# The fixture constitution's two release versions, and the repository root, for
# the version-reference cases below.
ver_a=1.0.0
ver_b=2.0.0
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

# Bare fixtures must advertise the branch we push, or a clone checks out nothing;
# and push negotiation against a bare file:// remote only adds noise.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=push.negotiate GIT_CONFIG_VALUE_0=false

# Fixture constitution: commit A (1.0.0) and commit B (2.0.0).
mkdir -p "$tmp/constitution" && cd "$tmp/constitution" && git init -q
echo 1.0.0 > VERSION && git add VERSION && gitc commit -q -m "chore(release): cut 1.0.0" && sha_a=$(git rev-parse HEAD)
echo 2.0.0 > VERSION && git add VERSION && gitc commit -q -m "chore(release): cut 2.0.0" && sha_b=$(git rev-parse HEAD)
git tag v2.0.0

make_adopter() {
  # make_adopter <name> <pinned-sha|none>
  local name=$1 pin=$2 work="$tmp/work-$1" bare="$tmp/$1.git"
  git init -q --bare -b main "$bare"
  mkdir -p "$work" && cd "$work" && git init -q -b main
  echo "# $name" > README.md && git add README.md
  # Optional third argument: seed adopter-side constitution version references.
  if [ "${3:-}" = "with-refs" ]; then
    mkdir -p docs docs/governance
    printf 'Built against Eric'"'"'s Engineering Constitution v1.0.0.\n' > CLAUDE.md
    printf '# Setup\n\nThis project pins the constitution at 1.0.0.\n' > docs/SETUP.md
    printf 'constitution 1.0.0 alignment notes\n' > docs/governance/alignment.md
    printf '1.0.0\n' > CONSTITUTION_VERSION
    # A version that has nothing to do with the constitution must not move.
    printf 'Requires Python 3.11.7 and pytest 8.0.0.\n' > CONTRIBUTING.md
    git add CLAUDE.md docs/SETUP.md docs/governance/alignment.md CONSTITUTION_VERSION CONTRIBUTING.md
  fi
  if [ "$pin" != "none" ]; then
    printf '[submodule "constitution"]\n\tpath = constitution\n\turl = ../constitution\n' > .gitmodules
    git add .gitmodules
    git update-index --add --cacheinfo "160000,$pin,constitution"
  fi
  gitc commit -q -m "init" && git remote add origin "$bare" && git push -q -u origin main
  cd "$tmp"
}
make_adopter behind "$sha_a"
make_adopter current "$sha_b"
make_adopter plain none
printf '%s\n' "$tmp/behind.git" "" "# comment" "$tmp/current.git" "$tmp/plain.git" > "$tmp/repos.txt"

echo "Test 1: a behind adopter is bumped, a current one and a non-adopter are skipped"
out=$("$bump" --sha v2.0.0 --repos "$tmp/repos.txt" --constitution "$tmp/constitution" --workdir "$tmp/w1" --no-pr)
grep -q 'BUMPED  behind' <<< "$out" || { echo "$out"; fail "behind adopter not bumped"; }
grep -q 'ALREADY_PINNED  current' <<< "$out" || { echo "$out"; fail "current adopter not skipped"; }
grep -q 'NOT_ADOPTER  plain' <<< "$out" || { echo "$out"; fail "non-adopter not skipped"; }
grep -q 'Summary: 1 bumped, 2 skipped, 0 failed' <<< "$out" || { echo "$out"; fail "summary wrong"; }
pinned=$(git -C "$tmp/behind.git" ls-tree constitution/bump-v2.0.0 constitution | awk '{print $3}')
[ "$pinned" = "$sha_b" ] || fail "pushed branch pins $pinned, expected $sha_b"
git -C "$tmp/behind.git" log -1 --format=%s constitution/bump-v2.0.0 | grep -q 'constitution: bump to v2.0.0' || fail "commit message does not name the release"
main_pin=$(git -C "$tmp/behind.git" ls-tree main constitution | awk '{print $3}')
[ "$main_pin" = "$sha_a" ] || fail "main was modified; only the bump branch may change"
echo "PASS"

echo "Test 2: re-running is idempotent (existing branch is skipped)"
out=$("$bump" --sha "$sha_b" --repos "$tmp/repos.txt" --constitution "$tmp/constitution" --workdir "$tmp/w2" --no-pr)
grep -q 'BRANCH_EXISTS  behind' <<< "$out" || { echo "$out"; fail "existing bump branch not detected"; }
grep -q 'Summary: 0 bumped, 3 skipped, 0 failed' <<< "$out" || { echo "$out"; fail "second-run summary wrong"; }
echo "PASS"

echo "Test 3: --dry-run creates nothing on the remote"
make_adopter dry "$sha_a"
printf '%s\n' "$tmp/dry.git" > "$tmp/repos-dry.txt"
out=$("$bump" --sha "$sha_b" --repos "$tmp/repos-dry.txt" --constitution "$tmp/constitution" --workdir "$tmp/w3" --dry-run --no-pr)
grep -q 'BUMPED  dry: commit created' <<< "$out" || { echo "$out"; fail "dry run did not report the would-be bump"; }
[ -z "$(git -C "$tmp/dry.git" branch --list 'constitution/*')" ] || fail "dry run pushed a branch"
echo "PASS"

echo "Test 4: a failing push is reported and fails the run without stopping the others"
make_adopter readonly "$sha_a"
git -C "$tmp/readonly.git" config receive.denyCurrentBranch ignore
printf '#!/bin/sh\necho "rejected by test hook" >&2\nexit 1\n' > "$tmp/readonly.git/hooks/pre-receive" && chmod +x "$tmp/readonly.git/hooks/pre-receive"
make_adopter behind2 "$sha_a"
printf '%s\n' "$tmp/readonly.git" "$tmp/behind2.git" > "$tmp/repos-fail.txt"
status=0; out=$("$bump" --sha "$sha_b" --repos "$tmp/repos-fail.txt" --constitution "$tmp/constitution" --workdir "$tmp/w4" --no-pr) || status=$?
[ "$status" -eq 1 ] || { echo "$out"; fail "expected exit 1 on a push failure, got $status"; }
grep -q 'FAILED  readonly: push failed' <<< "$out" || { echo "$out"; fail "push failure not reported"; }
grep -q 'BUMPED  behind2' <<< "$out" || { echo "$out"; fail "a later repository was not processed after a failure"; }
echo "PASS"

echo "Test 5: usage errors and an unknown commit exit 2"
status=0; "$bump" --sha nope --repos "$tmp/repos.txt" --constitution "$tmp/constitution" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown commit exited $status, expected 2"
status=0; "$bump" --repos "$tmp/repos.txt" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing --sha exited $status, expected 2"
status=0; "$bump" --sha "$sha_b" --repos "$tmp/missing.txt" --constitution "$tmp/constitution" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing repos file exited $status, expected 2"
status=0; "$bump" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
"$bump" --help | grep -q '^Usage:' || fail "--help printed no usage"
echo "PASS"

echo "Test 6: adopter-side version references move with the pin"
make_adopter refs "$sha_a" with-refs
printf '%s\n' "$tmp/refs.git" > "$tmp/repos-refs.txt"
out=$("$bump" --sha "$sha_b" --repos "$tmp/repos-refs.txt" --constitution "$tmp/constitution" --workdir "$tmp/w6" --no-pr)
grep -q 'BUMPED  refs:' <<< "$out" || { echo "$out"; fail "refs adopter was not bumped"; }
grep -q 'version reference(s)' <<< "$out" || { echo "$out"; fail "run output did not report rewritten references"; }

git clone -q "$tmp/refs.git" "$tmp/refs-check" && cd "$tmp/refs-check"
git checkout -q "constitution/bump-v$ver_b"
grep -q "Engineering Constitution v$ver_b" CLAUDE.md || { cat CLAUDE.md; fail "CLAUDE.md reference was not rewritten"; }
grep -q "constitution at $ver_b" docs/SETUP.md || { cat docs/SETUP.md; fail "docs/SETUP.md reference was not rewritten"; }
grep -q "constitution $ver_b" docs/governance/alignment.md || fail "docs/governance/*.md reference was not rewritten"
[ "$(cat CONSTITUTION_VERSION)" = "$ver_b" ] || fail "CONSTITUTION_VERSION was not rewritten"
grep -q '1.0.0' CLAUDE.md && fail "a stale 1.0.0 reference survived in CLAUDE.md"
# An unrelated version on a line that never mentions the constitution stays put.
grep -q 'Python 3.11.7' CONTRIBUTING.md || { cat CONTRIBUTING.md; fail "an unrelated version was rewritten"; }
grep -q 'pytest 8.0.0' CONTRIBUTING.md || fail "an unrelated version was rewritten"
# The rewrite rides in the same commit as the gitlink, not a second one.
[ "$(git rev-list --count "origin/main..HEAD")" = "1" ] || fail "expected exactly one bump commit"
git show --stat --oneline HEAD | grep -q 'CLAUDE.md' || fail "CLAUDE.md is not part of the bump commit"
git log -1 --format=%B | grep -q 'CLAUDE.md:1 1.0.0 -> '"$ver_b" || { git log -1 --format=%B; fail "commit body does not record the rewrite"; }
cd "$tmp"
echo "PASS"

echo "Test 7: an adopter with no version references is committed unchanged"
make_adopter norefs "$sha_a"
printf '%s\n' "$tmp/norefs.git" > "$tmp/repos-norefs.txt"
out=$("$bump" --sha "$sha_b" --repos "$tmp/repos-norefs.txt" --constitution "$tmp/constitution" --workdir "$tmp/w7" --no-pr)
grep -q 'version reference(s)' <<< "$out" && { echo "$out"; fail "reported rewrites for a repository that has none"; }
git clone -q "$tmp/norefs.git" "$tmp/norefs-check" && cd "$tmp/norefs-check"
git checkout -q "constitution/bump-v$ver_b"
[ "$(git show --stat --format= HEAD | grep -c .)" -le 2 ] || { git show --stat HEAD; fail "bump touched files beyond the gitlink"; }
cd "$tmp"
echo "PASS"

echo "Test 8: the rewrite satisfies check_version_alignment.sh"
checker="$repo_root/scripts/check_version_alignment.sh"
make_adopter aligned "$sha_a" with-refs
printf '%s\n' "$tmp/aligned.git" > "$tmp/repos-aligned.txt"
"$bump" --sha "$sha_b" --repos "$tmp/repos-aligned.txt" --constitution "$tmp/constitution" --workdir "$tmp/w8" --no-pr >/dev/null
git clone -q "$tmp/aligned.git" "$tmp/aligned-check" && cd "$tmp/aligned-check"
git checkout -q "constitution/bump-v$ver_b"
mkdir -p constitution && printf '%s\n' "$ver_b" > constitution/VERSION
status=0; "$checker" . >/dev/null 2>&1 || status=$?
[ "$status" -eq 0 ] || { "$checker" .; fail "check_version_alignment.sh still fails after the bump (exit $status)"; }
cd "$tmp"
echo "PASS"

echo "ALL TESTS PASSED"
