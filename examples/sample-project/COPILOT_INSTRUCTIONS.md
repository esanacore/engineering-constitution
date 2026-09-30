# Copilot Instructions

This sample project follows Eric's Engineering Constitution.

Use these files as context:

- `AGENTS.md`
- `README.md`
- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history, read on demand
- `CHANGELOG.md` — the `Unreleased` section and the most recent release; older sections are history, read on demand
- `constitution/CONSTITUTION.md`
- `docs/MEMORY.md` — project memory (learnings, decisions, user preferences)
- `docs/SESSION_PLAN.md` — the current session's plan; check it for a previous interrupted session and write your own before implementing

End every push with a Next Steps procedure (`constitution/AI_WORKFLOW.md`, "Next Steps Procedure"): a numbered checklist of what happens next, each step tagged **HUMAN**, **AGENT**, or **AUTOMATED**, with every step only a person can do (hardware, credentials, approvals) called out and described; put it in the pull request and `docs/AGENT_HANDOFF.md`.

Keep the demo page current — when a change alters user-facing behavior and the repository has a `demo.html`, update it in the same change; a demo still showing the old behavior is an incomplete change (`constitution/DOCUMENTATION.md`, "Demo Page").
