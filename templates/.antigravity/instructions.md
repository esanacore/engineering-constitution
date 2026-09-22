# Antigravity Instructions

This repository follows [Eric's Engineering Constitution](constitution/CONSTITUTION.md).

## Agent Workflow

As an autonomous agent in this workspace, you MUST:
1. Initialize by reading `constitution/CONSTITUTION.md` and `constitution/AI_WORKFLOW.md`.
2. Adhere to the project-specific rules in `AGENTS.md`.
3. Check `docs/SESSION_PLAN.md` for a previous interrupted session, then write your own plan there before implementing; clear or archive it when the session completes.
4. Read `docs/MEMORY.md` to load project context and user preferences. Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md` before completing work.
5. Maintain the `TODO.md` and `CHANGELOG.md` as living documents.
6. Follow the architectural standards in `docs/adr/`.

## Command Execution

Refer to `docs/COMMAND_REFERENCE.md` for the exact commands required for building, testing, and linting. Always run tests before considering a task complete.
