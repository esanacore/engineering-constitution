# Copilot Instructions

This repository follows Eric's Engineering Constitution.

## Context Files

Use these files as primary context:

- `CONSTITUTION.md`
- `AI_WORKFLOW.md`
- `TESTING.md`
- `DOCUMENTATION.md`
- `SECURITY.md`
- `ARCHITECTURE.md`
- `README.md`
- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history, read on demand
- `CHANGELOG.md` — the `Unreleased` section and the most recent release; older sections are history, read on demand
- `docs/MEMORY.md`

## Development Standards

- Prefer existing project conventions.
- Keep changes focused and maintainable.
- Add tests for new behavior.
- Add regression tests for bug fixes.
- Update documentation for changed behavior, setup, architecture, or operations.
- Check `docs/SESSION_PLAN.md` for a previous interrupted session; write your own plan before implementing.
- End every push with a Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps Procedure"): a numbered checklist of what happens next, each step tagged **HUMAN**, **AGENT**, or **AUTOMATED**, with every step only a person can do (hardware, credentials, approvals) called out and described; put it in the pull request and `docs/AGENT_HANDOFF.md`.
- Keep the demo page current — when a change alters user-facing behavior and the repository has a `demo.html`, update it in the same change; a demo still showing the old behavior is an incomplete change (`DOCUMENTATION.md`, "Demo Page").
- Update TODO.md with discovered follow-up work.
- Update CHANGELOG.md for user-facing changes.
- Avoid adding unnecessary dependencies.
- Consider security, observability, and release impact.
- Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md` before completing work.
