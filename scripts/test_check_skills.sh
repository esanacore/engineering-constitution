#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_skills.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_skills.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

make_skill() {
  # make_skill <root> <dir> <name> <description> [body]
  mkdir -p "$1/skills/$2"
  {
    printf -- '---\nname: "%s"\n' "$3"
    [ -n "$4" ] && printf 'description: "%s"\n' "$4"
    printf -- '---\n# %s\n\n%s\n' "$3" "${5:-Do the thing.}"
  } > "$1/skills/$2/SKILL.md"
}

good="$tmp/good"
mkdir -p "$good/scripts"
touch "$good/scripts/check_secrets.sh"
make_skill "$good" alpha alpha "Alpha skill." 'Run `bash constitution/scripts/check_secrets.sh .` first.'
make_skill "$good" beta beta "Beta skill."

echo "Test 1: well-formed skills pass under --strict"
out=$("$checker" --strict "$good")
grep -q 'Checked 2 skill(s); 0 with problems' <<< "$out" || { echo "$out"; fail "expected 2 clean skills"; }
echo "PASS"

echo "Test 2: a name that disagrees with its directory is caught"
bad="$tmp/bad-name"; make_skill "$bad" gamma gama "Typo."
status=0; out=$("$checker" "$bad") || status=$?
[ "$status" -eq 0 ] || fail "warn mode exited $status"
grep -q "front-matter name 'gama' does not match directory 'gamma'" <<< "$out" || { echo "$out"; fail "name mismatch not reported"; }
status=0; "$checker" --strict "$bad" >/dev/null || status=$?
[ "$status" -eq 1 ] || fail "--strict exited $status, expected 1"
echo "PASS"

echo "Test 3: a missing description, a missing SKILL.md, and an unclosed front matter are caught"
bad="$tmp/bad-desc"; make_skill "$bad" delta delta ""
out=$("$checker" "$bad"); grep -q 'front matter has no description' <<< "$out" || { echo "$out"; fail "missing description not reported"; }
bad="$tmp/bad-missing"; mkdir -p "$bad/skills/epsilon"
out=$("$checker" "$bad"); grep -q 'epsilon: no SKILL.md' <<< "$out" || { echo "$out"; fail "missing SKILL.md not reported"; }
bad="$tmp/bad-unclosed"; mkdir -p "$bad/skills/zeta"; printf -- '---\nname: "zeta"\n# zeta\n' > "$bad/skills/zeta/SKILL.md"
out=$("$checker" "$bad"); grep -q 'front-matter block is never closed' <<< "$out" || { echo "$out"; fail "unclosed front matter not reported"; }
echo "PASS"

echo "Test 4: a referenced script that does not exist is caught; an adopter's constitution/scripts/ satisfies it"
bad="$tmp/bad-ref"; make_skill "$bad" eta eta "Eta." 'Run `bash scripts/no_such_checker.sh`.'
status=0; out=$("$checker" --strict "$bad") || status=$?
[ "$status" -eq 1 ] || fail "dangling script reference should fail under --strict, got $status"
grep -q 'references no_such_checker.sh, which does not exist' <<< "$out" || { echo "$out"; fail "dangling reference not reported"; }
hyphen="$tmp/hyphen"; mkdir -p "$hyphen/scripts/lib"; touch "$hyphen/scripts/setup-machine.sh" "$hyphen/scripts/lib/ci_annotations.sh"
make_skill "$hyphen" iota iota "Iota." 'Run `bash scripts/setup-machine.sh`; annotations come from `scripts/lib/ci_annotations.sh`.'
out=$("$checker" --strict "$hyphen") || { echo "$out"; fail "a hyphenated script name or a lib/ script was mangled into a missing reference"; }
adopter="$tmp/adopter"; mkdir -p "$adopter/constitution/scripts"; touch "$adopter/constitution/scripts/check_env_vars.sh"
make_skill "$adopter" theta theta "Theta." 'Run `bash constitution/scripts/check_env_vars.sh .`.'
"$checker" --strict "$adopter" >/dev/null || fail "constitution/scripts/ reference should satisfy the check"
echo "PASS"

echo "Test 5: no skills directory is not a failure; usage errors exit 2"
mkdir -p "$tmp/none"
"$checker" --strict "$tmp/none" | grep -q 'No skills directory' || fail "expected the no-skills note"
status=0; "$checker" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
status=0; "$checker" "$tmp/nope" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing root exited $status, expected 2"
echo "PASS"

echo "ALL TESTS PASSED"
