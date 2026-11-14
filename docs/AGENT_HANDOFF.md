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

### Session: 2026-11-14 (Session summaries and a searchable session log)

Added the session log (ADR-0007): `docs/sessions/` holds one summary per
session — request, conversational context, decisions and reasoning,
discoveries, outcome, open questions — behind a newest-first index. Required
Workflow steps 9–10 consult it before planning and step 27 writes to it
before the session plan is cleared; every agent instruction file (root,
templates, sample project), Solon, and both pull request templates carry the
rule. New tooling: `scripts/check_session_summaries.sh` (format and index,
warn by default, `--strict`, `--base` tripwire), `scripts/find_sessions.sh`
(search), their suites, and a `session-summary-writer` skill. The Claude Code
`Stop` hook asks for a summary wherever `docs/sessions/` exists.
`bootstrap.sh` installs the index and template; `docs/sessions` is in the
compliance checker's recommended tier. `SECURITY.md` carries the privacy
rules.

Verified: `bash scripts/run_all_tests.sh` — 35 suites, zero failures; the
self-governance checkers pass `--strict` (secrets, instruction anchors,
skills, demo page, README, wiki links, session log, version references). An
independent review of the diff ran before the pull request; what it found is
in the session summary. No third-party dependency added. `VERSION` is
unchanged: no release was cut, because tagging and publishing are the
maintainer's and this change should be reviewed first.

Read first: `docs/sessions/2026-11-14-session-summaries.md` (the reasoning
and the open questions) and `docs/adr/0007-session-summaries.md`.

**Known blockers:** none. **Carried over:** the product-discovery pilot
(step 6) is still waiting on a participant.

## Next Steps

**Human action required:** steps 1, 3, and 6.

1. [ ] **HUMAN** — Review and merge the session-summaries pull request
   - **Why a human:** merge approval belongs to the maintainer, and three
     design choices in it are yours to confirm or overturn.
   - **You need:** the pull request, and
     `docs/sessions/2026-11-14-session-summaries.md` ("Open Questions").
   - **Procedure:**
     1. Decide whether summaries may be committed without your approval (as
        built) or should be approval-gated like `docs/MEMORY.md`.
     2. Decide whether `docs/sessions` stays in the recommended tier.
     3. Read `SECURITY.md`, "Session Summaries Are Published Artifacts", and
        say if anything else must stay out of a public log.
     4. Merge once the `Tests and Self-Governance` checks are green.
   - **Done when:** the pull request shows as merged.
2. [ ] **AGENT** — Prepare the 1.55.0 release (bump every version reference,
   date the `Unreleased` section, full suite, pull request) _(blocked by
   step 1)_
3. [ ] **HUMAN** — Tag `v1.55.0` on the release merge commit and publish the
   GitHub Release _(blocked by step 2)_
   - **Why a human:** tags and published releases are the maintainer's
     decision.
   - **Done when:** `git ls-remote --tags origin v1.55.0` shows the tag on
     the merge commit and the release is marked Latest.
4. [ ] **AGENT** — Roll the fleet: `bump_adopters.sh` to the release, plus
   `docs/sessions/README.md`, `TEMPLATE.md`, and the instruction-file line in
   each adopter _(blocked by step 3)_
5. [ ] **AUTOMATED** — `tests.yml` runs the suite and the self-governance
   job on the pull request; watch for a red run.
6. [ ] **HUMAN** — Choose an authorized pilot participant, a real bounded
   request, and a product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** the participant and owner agree on a request and the
     permitted material.
7. [ ] **AGENT** _(suggestion)_ — Generate the session-log index from the
   entries so concurrent sessions stop conflicting on its top row.
