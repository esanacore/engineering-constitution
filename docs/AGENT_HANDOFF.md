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

### Session: 2026-11-16 (Constitution Impact Report added)

Adopters can now keep `docs/CONSTITUTION_IMPACT.md`, an evidence-based record
of what adopting the constitution changed. `scripts/build_impact_report.sh`
creates it from `templates/docs/CONSTITUTION_IMPACT.md` and rewrites only its
generated Adoption Snapshot block; the What Changed, Catches, What It Cost,
and Not Yet Adopted sections are hand-written and must cite evidence
(`DOCUMENTATION.md`, "Constitution Impact Report"). It is opt-in: no
compliance tier, no bootstrap install, no workflow step, so no adopter's CI
changes. The work is on `claude/blissful-allen-ix6z3j`, pushed, with no pull
request opened. Summary: `docs/sessions/2026-11-16-constitution-impact-report.md`.

**Known blockers:** none. `Unreleased` holds this one addition; no release
was cut (a remote session cannot tag, and a pilot may change the template).

**Context hints:** the snapshot's adoption date comes from git history, so
the first run in an adopter must be on a full clone; shallow runs keep a
date already recorded. The 1.56.0 release steps from the previous handoff
(tag, GitHub Release, fleet bump, the 18 bump pull requests) were not
checked this session and are carried below as they stood.

## Next Steps

**Human action required:** steps 1, 2, 5, 7, and 8.

1. [ ] **HUMAN** — Review the Constitution Impact Report branch and say
   whether to open a pull request.
   - **Why a human:** the name, the four rules, and the opt-in rollout were
     the agent's choices; accepting them, and merging, are the maintainer's.
   - **You need:** the branch `claude/blissful-allen-ix6z3j`.
   - **Procedure:**
     1. Read `templates/docs/CONSTITUTION_IMPACT.md` and the worked example
        in `examples/sample-project/docs/CONSTITUTION_IMPACT.md`.
     2. Read the "Constitution Impact Report" section of `DOCUMENTATION.md`.
     3. Ask an agent to open the pull request, or list the changes you want.
   - **Done when:** a pull request is open, or edits have been requested.
2. [ ] **HUMAN** — Pick one adopter to pilot the report on (a public one
   with history, such as `SSH_DeviceManager`).
   - **Why a human:** which project's record becomes public evidence is the
     owner's call.
   - **Done when:** a repository is named.
3. [ ] **AGENT** — Run `bash constitution/scripts/build_impact_report.sh .`
   on a full clone of the pilot adopter, write the hand-written sections
   from its real pull requests and CI runs, and feed what was awkward back
   into the template _(blocked by steps 1 and 2)_
4. [ ] **AGENT** — Confirm the 1.56.0 release state (tag `v1.56.0`, GitHub
   Release, `release-tag-alignment`) and finish whatever of the previous
   handoff's tagging and fleet-bump steps is still open.
5. [ ] **HUMAN** — Review and merge the 18 `constitution/bump-v1.56.0` pull
   requests once they exist.
   - **Why a human:** merging into each adopter's default branch is the
     maintainer's decision.
   - **Done when:** every adopter's `constitution/` gitlink is the 1.56.0
     release commit.
6. [ ] **AGENT** _(suggestion)_ — Add `check_impact_report.sh` so "evidence
   or nothing" is checked mechanically: non-empty Evidence cells, no
   template placeholder, both markers present (`TODO.md`).
7. [ ] **HUMAN** — Walk the pitch deck; approve the voice or list edits, and
   give a consulting contact for the call to action if you want one.
   - **Why a human:** personal brand and public contact details are the
     author's.
   - **Done when:** the deck is approved as-is, or edits and a contact string
     are given.
8. [ ] **HUMAN** — Choose a pilot participant, a real bounded request, and a
   product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** participant and owner agree on a request and the
     permitted material.
