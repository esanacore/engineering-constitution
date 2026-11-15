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

Still on `release/v1.55.0` with uncommitted work; 1.55.0 release prep from
earlier remains relevant.

**Known blockers:** none for copy. Contact method on the CTA still TBD.
Consulting positioning preference recorded in `docs/MEMORY.md` (approved).

**Context hints:** open `pitch-deck.html` — slides 1, 4, 10, 12 carry the
consulting voice; 5–9 are the inspectable system evidence. Read
`docs/MEMORY.md` consulting positioning before editing sales copy.

## Next Steps

**Human action required:** steps 1, 2, 3, and 4.

1. [ ] **HUMAN** — Walk the reframed deck; confirm FDE / consulting voice
   matches how you want to introduce yourself to leads.
   - **Why a human:** personal brand and sales voice are the author's.
   - **Done when:** approve as-is or list copy edits (name line, bio facts,
     engagement shapes, pricing language).
2. [ ] **HUMAN** — Provide a consulting contact for the CTA if desired
   (email, calendar, LinkedIn) — or keep the demo/GitHub CTAs only.
   - **Why a human:** public contact details are personal.
   - **Done when:** a contact string is given for an agent edit, or you
     explicitly keep the current CTA.
3. [ ] **HUMAN** — Say whether to commit on `release/v1.55.0` or a separate
   branch/PR.
   - **Why a human:** branch strategy is the maintainer's call.
   - **Done when:** the agent has an explicit commit/PR instruction.
4. [ ] **HUMAN** — Finish 1.55.0 merge / tag / GitHub Release if still open
   (see prior release handoff notes in `docs/sessions/2026-11-14-release-1-55-0.md`).
   - **Why a human:** releases are the maintainer's.
   - **Done when:** `v1.55.0` exists on the merge commit and is Latest.
5. [ ] **AGENT** — After Pages publishes, confirm
   `…/pitch-deck.html` loads _(blocked by steps 3–4)_
6. [ ] **AGENT** — Fleet bump after the tag _(blocked by step 4)_
