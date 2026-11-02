# Agent Handoff

Session-to-session handoff for work on the framework itself. The session plan
(`docs/SESSION_PLAN.md`) captures intent before work; this file captures state
after work. Durable learnings go to `docs/MEMORY.md` on the maintainer's
approval, not here.

## How to Handoff

At the end of every push, replace the entry below (only the latest handoff is
kept; history lives in `CHANGELOG.md` and the commit log):

1. **Current Status**: what was achieved.
2. **Next Steps**: the Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps
   Procedure") — the same one that ends the summary and the pull request
   description. `scripts/check_next_steps.sh --strict .` runs in CI.
3. **Known Blockers**: what was encountered.
4. **Context Hints**: files or decisions the next agent should read.

## Latest Handoff

### Session: 2026-11-02 (Optional guided product discovery)

Implemented a tool-neutral discovery skill, facilitator guide, interview/review/
pilot templates, optional bootstrap installation, synthetic disagreement and
revision walkthrough, and a structural checker with negative regressions.
PRODUCT_REQUIREMENTS.md stays canonical; human product approval, engineering
readiness, test verification and outcomes remain independent. ProductSpec
exchange is a pinned manual mapping guide, not an automatic converter.

Independent review caught Windows/Linux digest differences and retired-ID
handling. The digest normalizes CR at line ends; retired requirements remain
declared as tombstones for evidence reassessment. Desktop/mobile rendered
inspection passed. Skill, README and demo strict checks passed. The bootstrap
rerun passed on Windows. The declared full suite passed under Ubuntu WSL:
33 suites, zero failures. Discovery regressions passed all 32 cases; the checker
contract suite and secrets sweep passed. No third-party runtime dependency added.

GPT-6 Astra implementation hit a usage limit after planning; implementation and
independent review continued with the available coding model. No release
has occurred. Discovery changes are being prepared on their own review
branch; earlier unfinished stability changes remain uncommitted and preserved.
VERSION remains unchanged pending merge/release review. The original session
plan remains because the earlier stability work is unfinished.

## Next Steps

**Human action required:** steps 1 and 2.

1. [ ] **HUMAN** — Review and merge the discovery pull request.
   - **Why a human:** merge approval belongs to the maintainer.
   - **Done when:** the reviewed pull request is merged with required CI checks green.
2. [ ] **HUMAN** — Choose an authorized pilot participant, real bounded request,
   and product decision owner for the November 9 discussion.
   - **Why a human:** participation, business priorities and data-sharing consent
     require the people who own them.
   - **Done when:** the participant and owner agree on a request and permitted
     material; no customer data is published without permission.
3. [ ] **AGENT** — Facilitate the pilot using docs/PRODUCT_DISCOVERY.md and record
   baseline comparison, total effort and all outcomes _(blocked by step 2)_.
