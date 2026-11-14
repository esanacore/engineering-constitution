# CLAUDE.md

This repository follows Eric's Engineering Constitution.

## Required Reading

Before making changes, read:

- `CONSTITUTION.md`
- `AI_WORKFLOW.md`
- `TESTING.md`
- `DOCUMENTATION.md`
- `SECURITY.md`
- `CODE_STYLE.md`
- `README.md`
- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history, read on demand
- `CHANGELOG.md` — the `Unreleased` section and the most recent release; older sections are history, read on demand
- `docs/MEMORY.md`
- `docs/sessions/README.md` — the session-log index, newest rows; search the log for the task's topic and read matching summaries on demand

## Completion Checklist

Before completing work:

- Confirm the requested change is implemented.
- Add or update relevant tests.
- Evaluate coverage against targets and record any gaps.
- Update requirements traceability for product-facing repositories.
- Update the OTS software inventory when third-party dependencies changed.
- Update documentation when needed.
- Update TODO.md with discovered or completed work.
- Update CHANGELOG.md for user-facing changes.
- Consider security impact.
- Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md`.
- Identify useful follow-up work.
- Clear or archive `docs/SESSION_PLAN.md`.
- End every push with a Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps Procedure"): a numbered checklist of what happens next, each step tagged **HUMAN**, **AGENT**, or **AUTOMATED**, with every step only a person can do (hardware, credentials, approvals) called out and described; put it in the pull request and `docs/AGENT_HANDOFF.md`.
- Keep the demo page current — when a change alters user-facing behavior and the repository has a `demo.html`, update it in the same change; a demo still showing the old behavior is an incomplete change (`DOCUMENTATION.md`, "Demo Page").
- Consult and extend the session log — before planning, read the newest rows of `docs/sessions/README.md` and search `docs/sessions/` for earlier sessions on the same topic (`bash scripts/find_sessions.sh <keyword>`), reading the ones that match; before completing non-trivial work, add this session's summary there (request, context, decisions, discoveries, outcome — a summary, never a transcript, and never a secret) and list it in the index (`AI_WORKFLOW.md`, "Session Summaries").
- Summarize changes and verification.