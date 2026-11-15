# Agent Handoff

Session-to-session handoff for work on the framework itself. The session plan
(`docs/SESSION_PLAN.md`) captures intent before work; this file captures state
after work. Durable learnings go to `docs/MEMORY.md` on the maintainer's
approval, not here. The lasting record of each session — what was asked,
decided, and learned — is its summary in `docs/sessions/`.

## How to Handoff

At the end of every push, replace the entry below (only the latest handoff is
kept; history lives in `docs/sessions/`, `CHANGELOG.md`, and the commit log):

1. **Current Status**: what was achieved.
2. **Next Steps**: the Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps
   Procedure") — the same one that ends the summary and the pull request
   description. `scripts/check_next_steps.sh --strict .` runs in CI.
3. **Known Blockers**: what was encountered.
4. **Context Hints**: files or decisions the next agent should read.

## Latest Handoff

### Session: 2026-11-14 (Consulting pitch deck reframed)

`pitch-deck.html` now leads with Eric as an **AI-native forward-deployed
engineer and harness expert** starting consulting work. The constitution is
framed as proof of craft and the system installed on engagement (not the
sole product being sold). Engagement slide covers diagnostic sprint,
embedded FDE weeks, and retainer. Linked from README / demo / wiki.
Summary: `docs/sessions/2026-11-14-pitch-deck.md`.

Committed and pushed to `origin/release/v1.55.0`
(`eb5b2b3` — pitch deck + consulting positioning; includes prior 1.55.0
release prep on the branch). Consulting positioning is in `docs/MEMORY.md`.

**Known blockers:** contact method on the CTA still TBD. Local upstream
tracking may need `git branch -u origin/release/v1.55.0` after the remote
branch was recreated.

**Context hints:** open `pitch-deck.html` — slides 1, 4, 10, 12 carry the
consulting voice; 5–9 are the inspectable system evidence.

## Next Steps

**Human action required:** steps 1, 2, and 3.

1. [ ] **HUMAN** — Review and merge PR #112 when CI is green:
   https://github.com/esanacore/engineering-constitution/pull/112
   - **Why a human:** merge to main is the maintainer's decision.
   - **Done when:** the PR is merged.
2. [ ] **HUMAN** — Walk the deck; confirm voice / add a consulting contact on
   the CTA if desired (email, calendar, LinkedIn).
   - **Why a human:** personal brand and public contact details are the author's.
   - **Done when:** approve as-is, or list edits / a contact string.
3. [ ] **HUMAN** — Tag `v1.55.0` and publish the GitHub Release after merge
   (see `docs/sessions/2026-11-14-release-1-55-0.md`).
   - **Why a human:** tags and Releases are the maintainer's.
   - **Done when:** `v1.55.0` is Latest on the merge commit.
4. [ ] **AGENT** — After Pages publishes from `main`, confirm
   `https://esanacore.github.io/engineering-constitution/pitch-deck.html` loads
   _(blocked by step 1)_
5. [ ] **AGENT** — Fleet bump after the tag _(blocked by step 3)_
