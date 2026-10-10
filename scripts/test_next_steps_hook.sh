#!/usr/bin/env bash
set -euo pipefail

# Tests for scripts/next_steps_hook.sh, the Claude Code SessionStart/Stop hook
# that enforces the Next Steps procedure when a session that made commits ends.

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
hook="$script_dir/next_steps_hook.sh"
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

export TMPDIR="$tmp/state"
mkdir -p "$TMPDIR"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
unset CONSTITUTION_NEXT_STEPS_HOOK

good_steps='#### Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Merge the pull request
   - **Why a human:** merging is the maintainer'"'"'s decision.
   - **Done when:** it is merged.
2. [ ] **AGENT** _(suggestion)_ — Pick up the next TODO item.'

# make_repo <dir> [adopter]: a git repo with one commit, the checker, and a
# well-formed handoff. "adopter" puts the checker under constitution/scripts/.
make_repo() {
  local d=$1 sub=scripts
  [ "${2:-}" = "adopter" ] && sub=constitution/scripts
  mkdir -p "$d/$sub/lib" "$d/docs"
  cp "$repo_root/scripts/check_next_steps.sh" "$d/$sub/"
  cp "$repo_root/scripts/lib/ci_annotations.sh" "$d/$sub/lib/"
  printf '# Agent Handoff\n\n%s\n' "$good_steps" > "$d/docs/AGENT_HANDOFF.md"
  git -C "$d" init -q -b main
  git -C "$d" add -A
  git -C "$d" commit -q -m init
}

# run <dir> <mode> <json> -> sets $status and $err
run() {
  status=0
  err=$(cd "$1" && printf '%s' "$3" | CLAUDE_PROJECT_DIR="$1" bash "$hook" "$2" 2>&1 >/dev/null) || status=$?
}

start_json() { printf '{"session_id":"%s","hook_event_name":"SessionStart","source":"startup"}' "$1"; }
stop_json() {
  # stop_json <session> <stop_hook_active> [last_assistant_message]
  if [ $# -ge 3 ]; then
    printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s,"last_assistant_message":"%s"}' "$1" "$2" "$3"
  else
    printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s}' "$1" "$2"
  fi
}
reply_ok='Done.\n\n## Next Steps\n\n**Human action required:** step 1.\n\n1. [ ] **HUMAN** — Merge it'

echo "Test 1: a session that made no commits is never blocked"
r="$tmp/r1"; make_repo "$r"
run "$r" start "$(start_json s1)"; [ "$status" -eq 0 ] || fail "start exited $status"
[ -f "$TMPDIR/constitution-next-steps/s1.head" ] || fail "start did not record a baseline"
run "$r" stop "$(stop_json s1 false 'Just answered a question.')"
[ "$status" -eq 0 ] || { echo "$err"; fail "no-commit session was blocked"; }
echo "PASS"

echo "Test 2: committing without updating the handoff blocks the stop, once"
r="$tmp/r2"; make_repo "$r"
run "$r" start "$(start_json s2)"
echo change > "$r/feature.txt"; git -C "$r" add -A; git -C "$r" commit -q -m feat
run "$r" stop "$(stop_json s2 false "$reply_ok")"
[ "$status" -eq 2 ] || { echo "$err"; fail "stale handoff should block (exit 2), got $status"; }
grep -q 'did not update docs/AGENT_HANDOFF.md' <<< "$err" || { echo "$err"; fail "reason does not name the stale handoff"; }
grep -q 'Human action required' <<< "$err" || { echo "$err"; fail "reason does not explain the format"; }
run "$r" stop "$(stop_json s2 true "$reply_ok")"
[ "$status" -eq 0 ] || fail "with stop_hook_active the stop must go through, got $status"
echo "PASS"

echo "Test 3: an updated but uncommitted handoff is called out"
echo "- note" >> "$r/docs/AGENT_HANDOFF.md"
run "$r" stop "$(stop_json s2 false "$reply_ok")"
[ "$status" -eq 2 ] || fail "uncommitted handoff should block, got $status"
grep -q 'updated but not committed' <<< "$err" || { echo "$err"; fail "uncommitted handoff not named"; }
echo "PASS"

echo "Test 4: a malformed procedure blocks with the checker's findings"
r="$tmp/r4"; make_repo "$r"
run "$r" start "$(start_json s4)"
printf '# Agent Handoff\n\n## Next Steps\n\n1. [ ] **HUMAN** — Wire the board\n' > "$r/docs/AGENT_HANDOFF.md"
git -C "$r" add -A; git -C "$r" commit -q -m "handoff"
run "$r" stop "$(stop_json s4 false "$reply_ok")"
[ "$status" -eq 2 ] || { echo "$err"; fail "malformed procedure should block, got $status"; }
grep -q 'is malformed' <<< "$err" || { echo "$err"; fail "malformed procedure not reported"; }
grep -q 'does not say why' <<< "$err" || { echo "$err"; fail "checker findings not relayed"; }
echo "PASS"

echo "Test 5: a reply without Next Steps blocks; a good handoff and reply pass"
r="$tmp/r5"; make_repo "$r" adopter
run "$r" start "$(start_json s5)"
printf '# Agent Handoff\n\nUpdated.\n\n%s\n' "$good_steps" > "$r/docs/AGENT_HANDOFF.md"
git -C "$r" add -A; git -C "$r" commit -q -m "work + handoff"
run "$r" stop "$(stop_json s5 false 'All done, pushed.')"
[ "$status" -eq 2 ] || { echo "$err"; fail "reply without Next Steps should block, got $status"; }
grep -q 'final reply has no "Next Steps" section' <<< "$err" || { echo "$err"; fail "reply finding not named"; }
run "$r" stop "$(stop_json s5 false "$reply_ok")"
[ "$status" -eq 0 ] || { echo "$err"; fail "good handoff + reply (adopter layout) should pass, got $status"; }
run "$r" stop "$(stop_json s5 false)"
[ "$status" -eq 0 ] || { echo "$err"; fail "a Claude Code without last_assistant_message should skip the reply check, got $status"; }
echo "PASS"

echo "Test 6: no baseline, no checker, opt-out, not a repo, and a resumed session"
r="$tmp/r6"; make_repo "$r"
echo x > "$r/x"; git -C "$r" add -A; git -C "$r" commit -q -m x
run "$r" stop "$(stop_json never-started false 'no')"
[ "$status" -eq 0 ] || fail "a session with no recorded start must not be blocked, got $status"
r="$tmp/r6b"; make_repo "$r"; rm -rf "$r/scripts"; git -C "$r" add -A; git -C "$r" commit -q -m "no checker"
run "$r" start "$(start_json s6)"; echo y > "$r/y"; git -C "$r" add -A; git -C "$r" commit -q -m y
run "$r" stop "$(stop_json s6 false 'no')"
[ "$status" -eq 0 ] || fail "a repository without the checker must not be blocked, got $status"
r="$tmp/r6c"; make_repo "$r"
run "$r" start "$(start_json s6c)"; echo z > "$r/z"; git -C "$r" add -A; git -C "$r" commit -q -m z
status=0; (cd "$r" && printf '%s' "$(stop_json s6c false no)" | CONSTITUTION_NEXT_STEPS_HOOK=off CLAUDE_PROJECT_DIR="$r" bash "$hook" stop 2>/dev/null) || status=$?
[ "$status" -eq 0 ] || fail "CONSTITUTION_NEXT_STEPS_HOOK=off must disable the hook, got $status"
mkdir -p "$tmp/plain"
run "$tmp/plain" stop "$(stop_json s6d false no)"
[ "$status" -eq 0 ] || fail "outside a git repository the hook must do nothing, got $status"
# A resume fires SessionStart again; the original baseline must survive.
run "$r" start "$(start_json s6c)"
run "$r" stop "$(stop_json s6c false no)"
[ "$status" -eq 2 ] || fail "a resumed session lost its baseline (commits before the resume no longer count), got $status"
echo "PASS"

echo "Test 7: the shipped settings register both hooks; usage errors never block"
tpl="$repo_root/templates/.claude/settings.json"
grep -q '"SessionStart"' "$tpl" && grep -q '"Stop"' "$tpl" || fail "templates/.claude/settings.json does not register SessionStart and Stop"
grep -q 'constitution/scripts/next_steps_hook.sh start' "$tpl" || fail "template SessionStart does not run next_steps_hook.sh start"
grep -q 'constitution/scripts/next_steps_hook.sh stop' "$tpl" || fail "template Stop does not run next_steps_hook.sh stop"
grep -q 'scripts/next_steps_hook.sh stop' "$repo_root/.claude/settings.json" || fail "this repository's .claude/settings.json does not dogfood the Stop hook"
status=0; bash "$hook" bogus </dev/null >/dev/null 2>&1 || status=$?
[ "$status" -eq 1 ] || fail "an unknown mode should exit 1 (a non-blocking error), got $status"
bash "$hook" --help | grep -q '^Usage:' || fail "--help prints no Usage: block"
echo "PASS"

echo "ALL TESTS PASSED"
