# Copilot Instructions

This repository follows [Eric's Engineering Constitution](constitution/CONSTITUTION.md).

## Before Making Changes

Read:

- `constitution/CONSTITUTION.md` — universal engineering principles
- `constitution/AI_WORKFLOW.md` — required workflow steps
- `README.md` — project purpose and setup
- `TODO.md` — current roadmap and known issues (open items only; completed entries are history)
- `CHANGELOG.md` — recent changes (`Unreleased` + the most recent release only)
- `docs/MEMORY.md` — read to load project context, codebase memory, and user preferences

## Development Standards

- Follow existing project conventions.
- Keep changes focused and maintainable.
- Check `docs/SESSION_PLAN.md` for a previous interrupted session; write your own plan before implementing.
- End every push with a Next Steps procedure (`constitution/AI_WORKFLOW.md`, "Next Steps Procedure"): a numbered checklist of what happens next, each step tagged **HUMAN**, **AGENT**, or **AUTOMATED**, with every step only a person can do (hardware, credentials, approvals) called out and described; put it in the pull request and `docs/AGENT_HANDOFF.md`.
- Add tests for new behavior and regression tests for bug fixes.
- Update documentation when behavior, setup, architecture, or operations change.
- Update `TODO.md` with discovered follow-up work.
- Update `CHANGELOG.md` for user-facing changes.
- Avoid adding unnecessary dependencies.
- Consider security, observability, and release impact.
- Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md` before completing work.

## Project-Specific Rules

<!-- Add project-specific rules here. These take precedence over the constitution. -->
<!-- Examples:
- This project uses Python 3.12+. Always use type hints.
- Run `make test` to verify changes.
- All API changes require a corresponding OpenAPI spec update.
-->
