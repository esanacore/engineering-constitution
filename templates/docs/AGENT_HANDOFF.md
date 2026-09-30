# Agent Handoff

This document helps transition work between different AI agent sessions or different agents.

**Before starting your session**, check `docs/SESSION_PLAN.md` for the previous agent's planned work and resumption notes, and `docs/MEMORY.md` to load durable codebase learnings and user preferences. The session plan captures *intent before work*; this handoff captures *state after work*.

## How to Handoff

When you are finishing a task or session, record the state here or in a dedicated `HANDOFF.md` file:

1. **Current Status**: What was achieved?
2. **Next Steps**: The Next Steps procedure from the end of your last push (see the constitution's `AI_WORKFLOW.md`, "Next Steps Procedure"): a numbered checklist in the order things should happen, every step tagged `HUMAN`, `AGENT`, or `AUTOMATED`, and every step only a person can do — hardware, credentials, UI-only settings, approvals — called out up front and described well enough to follow cold.
3. **Known Blockers**: What issues were encountered?
4. **Context Hints**: Are there specific files or discussions the next agent should read?

Replace the entry below at the end of every push; only the latest handoff is
kept. `constitution/scripts/check_next_steps.sh` checks the procedure's
format.

## Handoff Template

### Session: [Date/Time]
- **Accomplishments**: <!-- List here -->
- **Verification Run**: <!-- Tests run and results -->
- **Known Blockers**: <!-- List here, or "none" -->
- **Context Hints**: <!-- Files or decisions the next agent should read -->

#### Next Steps

<!-- Replace the example steps below with the real procedure; the example
is well-formed, so the checker cannot tell it from a real one. Keep the
"Human action required" line naming every HUMAN step (write "none" when no
step is HUMAN), and always leave at least one step, marked _(suggestion)_ if
it is optional. -->

**Human action required:** step 1.

1. [ ] **HUMAN** — Review and merge the pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the pull request shows as merged and CI on the default branch is green.
2. [ ] **AUTOMATED** — CI runs on the merge commit; watch for a red run.
3. [ ] **AGENT** _(suggestion)_ — Pick up the highest-priority open item in `TODO.md`.
