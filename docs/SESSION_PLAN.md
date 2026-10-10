# Session Plan

## Goals

Close the TODO "Consider a Claude Code `Stop` hook ... that runs
`check_next_steps.sh`": catch a missing or stale Next Steps procedure at the
moment a Claude Code session ends, not at pull request time.

## Approach

- `scripts/next_steps_hook.sh start|stop`. `start` (SessionStart) records the
  session's starting HEAD; `stop` (Stop) does nothing unless this session
  made commits, then blocks the stop once (exit 2, reason on stderr) when
  `docs/AGENT_HANDOFF.md` was not updated in those commits, its procedure
  fails `check_next_steps.sh`, or the final reply has no Next Steps section.
  `stop_hook_active` lets the second stop through, so it can never loop.
  Opt-out: `CONSTITUTION_NEXT_STEPS_HOOK=off`.
- Ship both hooks in `templates/.claude/settings.json`; dogfood with a root
  `.claude/settings.json` (hooks only).
- Paired `scripts/test_next_steps_hook.sh`; INTEGRATION.md, README, TESTING,
  wiki, CHANGELOG, TODO.

## Risks

- Hook input format (fields, exit codes) — verified against the docs.
- False blocks in sessions that never pushed: only sessions that committed
  are checked; unknown/absent baseline means no check.
- Transcript format is internal: the reply check is skipped when the format
  is not recognized.

## Resumption Notes

- Started 2026-10-10 on a fresh branch from `main` at v1.53.0. Implementation, docs, and the 1.54.0 bump are committed; awaiting the critique pass.
