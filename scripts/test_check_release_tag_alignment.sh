#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
check_script="$script_dir/check_release_tag_alignment.sh"

test_dir=$(mktemp -d)
echo "Running tests in: $test_dir"

cleanup() {
  rm -rf "$test_dir"
}
trap cleanup EXIT

make_repo() {
  dest=$1
  mkdir -p "$dest"
  git -C "$dest" init -q
  git -C "$dest" config user.name "Codex Test"
  git -C "$dest" config user.email "codex-test@example.com"
}

commit_version() {
  dest=$1
  version=$2
  printf '%s\n' "$version" > "$dest/VERSION"
  printf '# Changelog\n' > "$dest/CHANGELOG.md"
  git -C "$dest" add VERSION CHANGELOG.md
  git -C "$dest" commit -q -m "Set version $version"
}

run_check() {
  set +e
  output=$("$check_script" "$@" 2>&1)
  status=$?
  set -e
}

repo="$test_dir/aligned"
make_repo "$repo"
commit_version "$repo" "1.25.0"
git -C "$repo" tag -a v1.25.0 -m "Release 1.25.0" >/dev/null

run_check "$repo"
echo "$output"
[ "$status" -eq 0 ] || { echo "FAIL(1): expected aligned repo to pass, got $status"; exit 1; }
echo "$output" | grep -q "VERSION, HEAD, and the latest release tag are aligned" || { echo "FAIL(1): expected aligned success summary"; exit 1; }
echo "SUCCESS(1): aligned repository passes."

repo="$test_dir/missing-tag"
make_repo "$repo"
commit_version "$repo" "1.25.0"

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(2): expected missing tag to fail, got $status"; exit 1; }
echo "$output" | grep -q "Tag v1.25.0 does not exist" || { echo "FAIL(2): missing tag not reported"; exit 1; }
echo "SUCCESS(2): missing tag fails."

repo="$test_dir/tag-on-older-commit"
make_repo "$repo"
commit_version "$repo" "1.25.0"
git -C "$repo" tag -a v1.25.0 -m "Release 1.25.0" >/dev/null
printf 'post-release note\n' > "$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -q -m "Post-release change"

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(3): expected tag-off-HEAD to fail, got $status"; exit 1; }
echo "$output" | grep -q "HEAD is not tagged with v1.25.0" || { echo "FAIL(3): HEAD/tag mismatch not reported"; exit 1; }
echo "SUCCESS(3): tag on older commit fails."

repo="$test_dir/latest-tag-mismatch"
make_repo "$repo"
commit_version "$repo" "1.25.0"
git -C "$repo" tag -a v1.25.0 -m "Release 1.25.0" >/dev/null
printf '1.24.0\n' > "$repo/VERSION"
git -C "$repo" add VERSION
git -C "$repo" commit -q -m "Backdate version"
git -C "$repo" tag -a v1.24.0 -m "Release 1.24.0" >/dev/null

run_check "$repo"
echo "$output"
[ "$status" -eq 1 ] || { echo "FAIL(4): expected latest-tag mismatch to fail, got $status"; exit 1; }
echo "$output" | grep -q "Latest release tag is v1.25.0 (expected v1.24.0)" || { echo "FAIL(4): latest tag mismatch not reported"; exit 1; }
echo "SUCCESS(4): latest tag mismatch fails."

run_check --bogus "$test_dir/aligned"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected unknown option to exit 2, got $status"; exit 1; }

run_check "$test_dir/does-not-exist"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected missing root to exit 2, got $status"; exit 1; }

non_repo="$test_dir/not-a-repo"
mkdir -p "$non_repo"
run_check "$non_repo"
[ "$status" -eq 2 ] || { echo "FAIL(5): expected non-repo to exit 2, got $status"; exit 1; }
echo "SUCCESS(5): usage errors report exit 2."

echo "ALL TESTS PASSED"
