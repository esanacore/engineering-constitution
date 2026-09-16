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

echo "ALL TESTS PASSED"
