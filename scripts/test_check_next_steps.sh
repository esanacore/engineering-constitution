#!/usr/bin/env bash
set -euo pipefail

# Negative-case tests for scripts/check_next_steps.sh.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
checker="$script_dir/check_next_steps.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

# make_handoff <dir> <markdown>: writes <dir>/docs/AGENT_HANDOFF.md.
make_handoff() {
  mkdir -p "$1/docs"
  printf '%s\n' "$2" > "$1/docs/AGENT_HANDOFF.md"
}

# expect_finding <dir> <fixed string> <description>: warn mode reports it and
# exits 0; --strict exits 1.
expect_finding() {
  local status=0 out
  out=$("$checker" "$1") || status=$?
  [ "$status" -eq 0 ] || { echo "$out"; fail "$3: warn mode exited $status"; }
  grep -qF -- "$2" <<< "$out" || { echo "$out"; fail "$3: expected '$2'"; }
  status=0; "$checker" --strict "$1" >/dev/null || status=$?
  [ "$status" -eq 1 ] || fail "$3: --strict exited $status, expected 1"
}

good='# Agent Handoff

## Latest Handoff

### Session: 2026-09-30

- **Accomplishments**: shipped the thing.

#### Next Steps

**Human action required:** steps 1 and 3 (before Friday, 10am).

1. [ ] **HUMAN** — Connect the test board to the CI runner
   - **Why a human:** needs physical access to the lab bench.
   - **You need:** the board and a USB-C data cable.
   - **Procedure:**
     1. Plug the board into the runner.
     2. Note the device name.
   - **Done when:** the hardware job goes green.
2. [ ] **AGENT** — Enable the hardware smoke tests _(blocked by step 1)_
3. [x] **HUMAN** — Merge the pull request
   - **Why a human:** merges are the maintainer'"'"'s decision.
   - **Done when:** the pull request shows as merged.
4. [ ] **AUTOMATED** — The release workflow publishes on merge; watch for red.
5. [ ] **AGENT** _(suggestion)_ — Add a retry to the serial handshake.

## Older Notes

1. Numbered lists after the section are not steps.'

echo "Test 1: a well-formed procedure passes under --strict, and the counts are reported"
make_handoff "$tmp/good" "$good"
out=$("$checker" --strict "$tmp/good") || { echo "$out"; fail "well-formed procedure failed --strict"; }
grep -q 'OK       5 step(s), 2 waiting on a person' <<< "$out" || { echo "$out"; fail "expected 5 steps, 2 human"; }
echo "PASS"

echo "Test 2: the procedure documented in AI_WORKFLOW.md passes its own checker"
awk '/^```markdown/{f=1;next} /^```$/{f=0} f' "$repo_root/AI_WORKFLOW.md" > "$tmp/documented.md"
grep -q '^## Next Steps' "$tmp/documented.md" || fail "could not extract the documented example from AI_WORKFLOW.md"
"$checker" --strict --file "$tmp/documented.md" "$tmp" >/dev/null || fail "AI_WORKFLOW.md's example fails check_next_steps.sh"
echo "PASS"

echo "Test 3: a missing section, and a section with no steps, are caught"
make_handoff "$tmp/no-section" '# Agent Handoff

- **Pending Work**: tag the release.'
expect_finding "$tmp/no-section" 'section: no "Next Steps" heading' "no section"
make_handoff "$tmp/empty" '# Handoff

## Next Steps

Nothing to do.

## Later'
expect_finding "$tmp/empty" 'empty: the Next Steps section has no numbered steps' "empty section"
echo "PASS"

echo "Test 4: a step without a checkbox or an actor tag, and out-of-order numbering, are caught"
make_handoff "$tmp/malformed" '## Next Steps

1. **AGENT** — no checkbox
2. [ ] Do something, but who?
4. [ ] **AGENT** — numbered 4 but third'
expect_finding "$tmp/malformed" 'checkbox: step 1 has no checkbox' "missing checkbox"
expect_finding "$tmp/malformed" 'actor: step 2 does not start with **HUMAN**, **AGENT**, or **AUTOMATED**' "missing actor"
expect_finding "$tmp/malformed" 'order: step 3 is numbered 4' "numbering"
make_handoff "$tmp/lowercase" '## Next Steps

1. [ ] **human** — lowercase tag is not a tag'
expect_finding "$tmp/lowercase" 'actor: step 1 does not start with' "lowercase actor tag"
echo "PASS"

echo "Test 5: a HUMAN step must say why a person is needed and when it is done"
make_handoff "$tmp/vague-human" '## Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Set up the hardware'
expect_finding "$tmp/vague-human" 'human: step 1 is HUMAN but does not say why' "missing why"
expect_finding "$tmp/vague-human" 'human: step 1 is HUMAN but does not say when it is done' "missing done-when"
echo "PASS"

echo "Test 6: the Human action required line must exist and name exactly the HUMAN steps"
human_step='   - **Why a human:** physical access.
   - **Done when:** the light is green.'
make_handoff "$tmp/no-summary" "## Next Steps

1. [ ] **HUMAN** — Plug it in
$human_step"
expect_finding "$tmp/no-summary" 'summary: no "**Human action required:** steps ..." line' "missing summary line"
make_handoff "$tmp/unnamed" "## Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Plug it in
$human_step
2. [ ] **HUMAN** — Approve the order
$human_step"
expect_finding "$tmp/unnamed" 'summary: step 2 is HUMAN but the "Human action required" line does not name it' "HUMAN step not named"
make_handoff "$tmp/overnamed" "## Next Steps

**Human action required:** steps 1 and 2.

1. [ ] **HUMAN** — Plug it in
$human_step
2. [ ] **AGENT** — Run the tests"
expect_finding "$tmp/overnamed" 'summary: "Human action required" names step 2, which is not a HUMAN step' "non-HUMAN step named"
make_handoff "$tmp/none-needed" '## Next Steps

**Human action required:** none.

1. [ ] **AGENT** _(suggestion)_ — Extend the parser.'
"$checker" --strict "$tmp/none-needed" >/dev/null || fail "\"Human action required: none.\" with no HUMAN steps should pass"
echo "PASS"

echo "Test 7: HTML comments and fenced examples are ignored; the section ends at the next same-level heading"
make_handoff "$tmp/fenced" '# Handoff

```markdown
## Next Steps

1. [ ] **AGENT** — an example, not the real procedure
```

<!--
## Next Steps
1. [ ] **AGENT** — commented out
-->'
expect_finding "$tmp/fenced" 'section: no "Next Steps" heading' "fenced and commented sections must not count"
make_handoff "$tmp/scoped" '## Next Steps

1. [ ] **AGENT** — the only step

## Appendix

2. Not a step: another section.'
out=$("$checker" --strict "$tmp/scoped") || { echo "$out"; fail "a numbered list under a later heading was read as a step"; }
grep -q '1 step(s)' <<< "$out" || { echo "$out"; fail "expected exactly one step"; }
echo "PASS"

echo "Test 8: --file reads a named file or standard input (a pull request body)"
printf '## Summary\n\nDid it.\n\n## Next Steps\n\n1. [ ] **AUTOMATED** — CI runs on push; watch for red.\n' > "$tmp/pr-body.md"
"$checker" --strict --file "$tmp/pr-body.md" "$tmp" >/dev/null || fail "--file with an absolute path failed"
out=$(printf '## Next Steps\n\n1. [ ] **AGENT** — from stdin\n' | "$checker" --strict --file - "$tmp") || { echo "$out"; fail "--file - failed"; }
grep -q 'standard input' <<< "$out" || { echo "$out"; fail "stdin not labeled"; }
status=0; printf '# No steps here\n' | "$checker" --strict --file - "$tmp" >/dev/null || status=$?
[ "$status" -eq 1 ] || fail "a PR body with no Next Steps should fail --strict via stdin, got $status"
echo "PASS"

echo "Test 9: regressions from the critique pass"
# A numbered sub-procedure indented under a step (3 spaces is a valid nested
# list in CommonMark) belongs to that step, not the top level.
make_handoff "$tmp/nested" '## Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Wire the board
   1. Plug it in.
   2. Power it on.
   - **Why a human:** physical access.
   - **Done when:** the LED is green.
2. [ ] **AGENT** — Enable the tests'
out=$("$checker" --strict "$tmp/nested") || { echo "$out"; fail "a nested numbered procedure was read as top-level steps"; }
grep -q '2 step(s)' <<< "$out" || { echo "$out"; fail "expected 2 steps with a nested procedure"; }
# Heading variants people actually write, especially in pull request bodies.
for heading in '## Next Steps:' '## 👉 Next steps' '**Next Steps**' '**Next Steps:**' ' ## Next Steps' $'Next Steps\n----------'; do
  printf '%s\n\n1. [ ] **AGENT** — the step\n' "$heading" > "$tmp/heading.md"
  "$checker" --strict --file "$tmp/heading.md" "$tmp" >/dev/null || fail "heading variant not recognized: $heading"
done
printf '## Next Steps Later\n\n1. [ ] **AGENT** — the step\n' > "$tmp/heading.md"
status=0; "$checker" --strict --file "$tmp/heading.md" "$tmp" >/dev/null || status=$?
[ "$status" -eq 1 ] || fail "a heading that only starts with 'Next Steps' should not count"
# The call-out line after the list is still found; ranges and notes parse.
make_handoff "$tmp/after" "## Next Steps

1. [ ] **HUMAN** — Plug it in
$human_step
2. [ ] **HUMAN** — Approve it
$human_step
3. [ ] **HUMAN** — Ship it
$human_step

**Human action required:** steps 1–3 (today). The rest is automatic after 4pm."
"$checker" --strict "$tmp/after" >/dev/null || { "$checker" "$tmp/after"; fail "a call-out after the list, with a range, should pass"; }
make_handoff "$tmp/range-to" "## Next Steps

**Human action required:** steps 1 to 2.

1. [ ] **HUMAN** — Plug it in
$human_step
2. [ ] **HUMAN** — Approve it
$human_step"
"$checker" --strict "$tmp/range-to" >/dev/null || fail "\"steps 1 to 2\" should name steps 1 and 2"
# A longer fence is not closed by a shorter one inside it.
make_handoff "$tmp/fence-mixed" '## Next Steps

1. [ ] **AGENT** — first

````markdown
```
## Not a heading
```
````

2. [ ] **AGENT** — second'
out=$("$checker" --strict "$tmp/fence-mixed") || { echo "$out"; fail "a nested fence ended the section early"; }
grep -q '2 step(s)' <<< "$out" || { echo "$out"; fail "expected 2 steps around a nested fence"; }
echo "PASS"

echo "Test 10: this repository's and the template's handoffs pass; absent default is not a failure; usage errors exit 2"
"$checker" --strict "$repo_root" >/dev/null || fail "docs/AGENT_HANDOFF.md does not carry a well-formed Next Steps procedure"
mkdir -p "$tmp/template/docs"; cp "$repo_root/templates/docs/AGENT_HANDOFF.md" "$tmp/template/docs/AGENT_HANDOFF.md"
"$checker" --strict "$tmp/template" >/dev/null || fail "templates/docs/AGENT_HANDOFF.md fails its own checker"
mkdir -p "$tmp/none"
out=$("$checker" --strict "$tmp/none") || fail "no handoff file should exit 0"
grep -q 'nothing to verify' <<< "$out" || { echo "$out"; fail "expected the nothing-to-verify note"; }
status=0; "$checker" --strict --file missing.md "$tmp/none" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "an explicit missing --file exited $status, expected 2"
status=0; "$checker" --bogus >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "unknown option exited $status, expected 2"
status=0; "$checker" "$tmp/nope" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "missing root exited $status, expected 2"
echo "PASS"

echo "ALL TESTS PASSED"
