# Copilot Instructions

This repository follows Eric's Engineering Constitution.

## Context Files

Use these files as primary context:

- `constitution/CONSTITUTION.md`
- `constitution/AI_WORKFLOW.md`
- `constitution/TESTING.md`
- `constitution/DOCUMENTATION.md`
- `constitution/SECURITY.md`
- `constitution/ARCHITECTURE.md`
- `README.md`
- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history, read on demand
- `CHANGELOG.md` — the `Unreleased` section and the most recent release; older sections are history, read on demand
- `docs/MEMORY.md`

## Development Standards

- Prefer existing project conventions.
- Keep changes focused and maintainable.
- Check `docs/SESSION_PLAN.md` for a previous interrupted session; write your own plan before implementing.
- Add tests for new behavior.
- Add regression tests for bug fixes.
- Update documentation for changed behavior, setup, architecture, or operations.
- Update TODO.md with discovered follow-up work.
- Update CHANGELOG.md for user-facing changes.
- Avoid adding unnecessary dependencies.
- Consider security, observability, and release impact.
- Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md` before completing work.
