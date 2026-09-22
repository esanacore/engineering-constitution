#!/usr/bin/env bash
set -euo pipefail

# Meta-test: every scripts/check_*.sh honors the shared checker contract that
# TESTING.md's "CI Enforcement" section describes in prose. Encoding it here
# means a new checker cannot quietly ship without --help, without exit 2 on a
# bad option, without the executable bit, without CI annotations, or without a
# paired negative-case suite — each of which has slipped through before
# (the 1.42.0 executable-bit regression is the canonical example).
#
# Contract (per checker):
#   1. Committed as 100755 and executable on disk.
#   2. `--help` exits 0 and prints a Usage: block.
#   3. An unknown option exits 2.
#   4. If its usage text documents --strict, `--strict --help` still exits 0.
#   5. Sources scripts/lib/ci_annotations.sh and calls ci_annotate.
#   6. Has a paired scripts/test_<name>.sh.
# Repository-wide:
#   7. Every scripts/*.sh is 100755; every scripts/lib/*.sh is 100644 (sourced,
#      never executed).
#   8. Under GITHUB_ACTIONS=true a failing checker emits ::error:: and a
#      warn-mode finding emits ::warning:: (spot-checked on two checkers).

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
cd "$repo_root"

fail() { echo "FAIL: $*"; exit 1; }

checkers=()
while IFS= read -r c; do checkers+=("$c"); done < <(find scripts -maxdepth 1 -type f -name 'check_*.sh' | sort)
[ "${#checkers[@]}" -ge 13 ] || fail "expected at least 13 checkers, found ${#checkers[@]}"

echo "Test 1: every checker honors --help, exit 2 on a bad option, and --strict where documented"
for c in "${checkers[@]}"; do
  name=$(basename "$c")
  [ -x "$c" ] || fail "$name is not executable on disk"
  mode=$(git ls-files -s "$c" | awk '{print $1}')
  [ "$mode" = "100755" ] || fail "$name is committed as $mode, expected 100755"

  status=0; help_out=$("$c" --help 2>&1) || status=$?
  [ "$status" -eq 0 ] || fail "$name --help exited $status"
  grep -q '^Usage:' <<< "$help_out" || fail "$name --help printed no Usage: block"

  status=0; "$c" --definitely-not-an-option >/dev/null 2>&1 || status=$?
  [ "$status" -eq 2 ] || fail "$name exited $status on an unknown option, expected 2"

  if grep -q -- '--strict' <<< "$help_out"; then
    status=0; "$c" --strict --help >/dev/null 2>&1 || status=$?
    [ "$status" -eq 0 ] || fail "$name documents --strict but '--strict --help' exited $status"
  fi

  grep -q 'lib/ci_annotations.sh' "$c" || fail "$name does not source scripts/lib/ci_annotations.sh"
  grep -q -E '^\s*ci_annotate (error|warning|notice) ' "$c" || fail "$name never calls ci_annotate"

  paired="scripts/test_${name%.sh}.sh"
  [ -f "$paired" ] || fail "$name has no paired negative-case suite at $paired"
done
echo "PASS (${#checkers[@]} checkers)"

echo "Test 2: executable bits across scripts/ and scripts/lib/"
while IFS= read -r line; do
  mode=$(awk '{print $1}' <<< "$line"); path=$(awk '{print $2}' <<< "$line")
  case "$path" in
    scripts/lib/*.sh) [ "$mode" = "100644" ] || fail "$path is $mode; sourced libraries stay 100644" ;;
    scripts/*.sh)     [ "$mode" = "100755" ] || fail "$path is $mode; directly invoked scripts must be 100755" ;;
  esac
done < <(git ls-files -s scripts | awk '{print $1, $4}')
echo "PASS"

echo "Test 3: annotations fire under GitHub Actions and stay silent elsewhere"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/empty"
status=0; out=$(GITHUB_ACTIONS=true scripts/check_compliance.sh "$tmp/empty" 2>&1) || status=$?
[ "$status" -eq 1 ] || fail "check_compliance.sh on an empty repo exited $status, expected 1"
grep -q '^::error::check_compliance.sh: required missing:' <<< "$out" || { echo "$out"; fail "no ::error:: annotation from check_compliance.sh"; }
# GitHub sets GITHUB_ACTIONS=true for real when this suite runs in CI, so the
# "outside Actions" case must clear it explicitly rather than assume it is unset.
out=$(env -u GITHUB_ACTIONS scripts/check_compliance.sh "$tmp/empty" 2>&1 || true)
if grep -q '^::' <<< "$out"; then fail "check_compliance.sh emitted an annotation outside GitHub Actions"; fi

mkdir -p "$tmp/wiki-repo/wiki"
printf '# Home\n\n[[Missing Page]]\n' > "$tmp/wiki-repo/wiki/Home.md"
status=0; out=$(GITHUB_ACTIONS=true scripts/check_wiki_links.sh "$tmp/wiki-repo" 2>&1) || status=$?
[ "$status" -eq 0 ] || fail "check_wiki_links.sh (warn mode) exited $status, expected 0"
grep -q '^::warning::check_wiki_links.sh: 1 dangling link(s)' <<< "$out" || { echo "$out"; fail "no ::warning:: annotation from check_wiki_links.sh in warn mode"; }
status=0; out=$(GITHUB_ACTIONS=true scripts/check_wiki_links.sh --strict "$tmp/wiki-repo" 2>&1) || status=$?
[ "$status" -eq 1 ] || fail "check_wiki_links.sh --strict exited $status, expected 1"
grep -q '^::error::check_wiki_links.sh: 1 dangling link(s)' <<< "$out" || { echo "$out"; fail "no ::error:: annotation from check_wiki_links.sh --strict"; }
echo "PASS"

echo "ALL TESTS PASSED"
