#!/usr/bin/env bash
set -uo pipefail

# Claude Code hook that enforces AI_WORKFLOW.md's "Next Steps Procedure" at the
# moment a session ends, instead of at pull request time (ADR-0005).
#
#   next_steps_hook.sh start   SessionStart: record the session's starting HEAD.
#   next_steps_hook.sh stop    Stop: if this session made commits, require that
#                              docs/AGENT_HANDOFF.md was updated in them, that its
#                              Next Steps procedure passes check_next_steps.sh,
#                              and that the final reply carries a Next Steps
#                              section. Otherwise block the stop once and say why.
#
# Both read the hook's JSON input on standard input. Blocking uses Claude Code's
# Stop-hook contract: exit 2 with the reason on stderr, which Claude reads and
# acts on. The hook blocks at most once per stop: when Claude stops again with
# `stop_hook_active` set, the stop goes through, so it can never loop.
#
# It deliberately does nothing when there is no evidence of a push-worthy
# change: a session that only answered a question, a session whose start was
# not recorded (the hook was installed mid-session), a repository without the
# checker, or CONSTITUTION_NEXT_STEPS_HOOK=off. A guard that fires on every
# stop would be switched off within a day.
#
# Exit status:
#   0  nothing to enforce, or the procedure is in order
#   2  stop blocked (Stop only); the reason is on stderr
#   1  usage error (reported to the user, never blocks)

usage() {
  cat <<'USAGE'
Usage:
  next_steps_hook.sh start|stop

Description:
  Claude Code hook for AI_WORKFLOW.md's "Next Steps Procedure". Register
  `start` as a SessionStart hook and `stop` as a Stop hook (see
  templates/.claude/settings.json). Reads the hook's JSON input on stdin.

  stop blocks the end of a session that made commits when
  docs/AGENT_HANDOFF.md was not updated in them, when its Next Steps
  procedure fails check_next_steps.sh, or when the final reply has no
  "Next Steps" section. It blocks once; the next stop goes through.

Environment:
  CONSTITUTION_NEXT_STEPS_HOOK=off   Disable both modes.
  CLAUDE_PROJECT_DIR                 Repository root (set by Claude Code).
  TMPDIR                             Where session baselines are kept.
USAGE
}

mode=${1:-}
case "$mode" in
  start|stop) ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 1 ;;
esac

input=$(cat 2>/dev/null || true)
[ "${CONSTITUTION_NEXT_STEPS_HOOK:-on}" = "off" ] && exit 0

# A JSON string or boolean field from the flat hook input, without jq.
json_field() {
  printf '%s' "$input" | tr -d '\n' \
    | sed -n -E "s/.*\"$1\"[[:space:]]*:[[:space:]]*(\"([^\"\\\\]|\\\\.)*\"|true|false).*/\\1/p" \
    | sed -E 's/^"//; s/"$//'
}

# Hooks run in Claude Code's current directory, which may be a subdirectory.
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
head=$(git rev-parse -q --verify HEAD 2>/dev/null) || exit 0

session=$(json_field session_id | tr -c 'A-Za-z0-9_-' '_')
[ -n "$session" ] || exit 0
state_dir="${TMPDIR:-/tmp}/constitution-next-steps"
baseline_file="$state_dir/$session.head"   # "<HEAD at start> <epoch seconds>"
done_file="$state_dir/$session.done"       # HEAD at the last stop let through

if [ "$mode" = "start" ]; then
  # Keep the first recorded start: a resumed or compacted session fires
  # SessionStart again, and its commits so far still count.
  mkdir -p "$state_dir" 2>/dev/null || exit 0
  find "$state_dir" -type f -mtime +14 -exec rm -f {} + 2>/dev/null
  [ -f "$baseline_file" ] || printf '%s %s\n' "$head" "$(date +%s)" > "$baseline_file" 2>/dev/null
  exit 0
fi

# --- stop ---
[ -f "$baseline_file" ] || exit 0
read -r base started < "$baseline_file" || true
[ -n "${base:-}" ] && [ -n "${started:-}" ] || exit 0
mark_done() { printf '%s\n' "$head" > "$done_file" 2>/dev/null; }

# Once blocked, the next stop goes through: never a loop.
if [ "$(json_field stop_hook_active)" = "true" ]; then mark_done; exit 0; fi

# This session's commits: reachable from HEAD but not from the start, made
# after the session started, by this clone's git identity. A branch switch or
# a pull moves HEAD over other people's (or older) commits; those do not count.
me=$(git config user.email 2>/dev/null || true)
session_commits() { # session_commits <from>
  git cat-file -e "$1^{commit}" 2>/dev/null || return 0
  git log --format='%H %ct %ce' "$1..HEAD" 2>/dev/null \
    | awk -v t="$started" -v me="$me" '$2 >= t && (me == "" || $3 == me) { print $1 }'
}
all=$(session_commits "$base")
[ -n "$all" ] || exit 0

# Only a turn that added commits since the last stop let through is checked,
# so a question answered after a compliant push is not held.
if [ -f "$done_file" ]; then
  last=$(head -n 1 "$done_file")
  [ "$last" = "$head" ] && exit 0
  [ -n "$(session_commits "$last")" ] || { mark_done; exit 0; }
fi

checker=""
for c in constitution/scripts/check_next_steps.sh scripts/check_next_steps.sh; do
  [ -f "$c" ] && { checker=$c; break; }
done
[ -n "$checker" ] || exit 0

handoff=docs/AGENT_HANDOFF.md
problems=()

if [ ! -f "$handoff" ]; then
  problems+=("$handoff does not exist; it carries the durable copy of the procedure.")
else
  touched=false
  for c in $all; do
    if [ -n "$(git diff-tree --root --no-commit-id --name-only -r "$c" -- "$handoff" 2>/dev/null)" ]; then
      touched=true; break
    fi
  done
  if [ "$touched" = "false" ]; then
    if git diff --quiet HEAD -- "$handoff" 2>/dev/null; then
      problems+=("This session committed changes but did not update $handoff, so its Next Steps describe an older state.")
    else
      problems+=("$handoff is updated but not committed; commit and push it with the work it describes.")
    fi
  fi
  report=$(bash "$checker" --strict . 2>&1) || problems+=("$handoff's Next Steps procedure is malformed:
$(printf '%s\n' "$report" | grep 'PROBLEM' | sed 's/^ *PROBLEM */  - /')")
fi

# The final reply must end with the same procedure. Claude Code passes it as
# last_assistant_message (a JSON string, decoded here); an older version that
# does not, or a null message, skips this rather than guessing.
reply=$(json_field last_assistant_message)
if [ -n "$reply" ]; then
  reply=$(printf '%s\n' "$reply" | awk '{
    gsub(/\\\\/, "\001"); gsub(/\\n/, "\n"); gsub(/\\t/, "\t"); gsub(/\\r/, "")
    gsub(/\\"/, "\""); gsub(/\001/, "\\"); print }')
  report=$(printf '%s\n' "$reply" | bash "$checker" --strict --file - . 2>&1) \
    || problems+=("Your final reply does not end with a well-formed Next Steps procedure:
$(printf '%s\n' "$report" | grep 'PROBLEM' | sed 's/^ *PROBLEM */  - /')")
fi

if [ "${#problems[@]}" -eq 0 ]; then mark_done; exit 0; fi

{
  echo "Next Steps procedure needed before this session ends (AI_WORKFLOW.md, \"Next Steps Procedure\"; ADR-0005)."
  echo "This session made commits since $(git rev-parse --short "$base"), so it must hand over what happens next:"
  for p in "${problems[@]}"; do echo "- $p"; done
  echo "Write the procedure: a \"Next Steps\" heading, a numbered checklist, every step tagged **HUMAN**, **AGENT**, or **AUTOMATED**, a \"**Human action required:**\" line naming every HUMAN step, and Why a human / Done when on each. Put it in $handoff (commit and push) and at the end of your reply. Check it with: bash $checker --strict ."
} >&2
exit 2
