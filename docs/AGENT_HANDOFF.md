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

<<<<<<< HEAD
### Session: 2026-11-14 (1.56.0 released; session log rolled out to the fleet)

`v1.56.0` is tagged on merge commit `7615a92` and published as the Latest
GitHub Release; `release-tag-alignment` passed. All 18 adopters have a
`constitution/bump-v1.56.0` pull request that also adopts the session log:
`docs/sessions/README.md` and `TEMPLATE.md`, plus the session-log rule in
the instruction files. The three CI fixes from the 1.55.0 branches were
carried over, and the 18 superseded 1.55.0 pull requests are closed.
Summary: `docs/sessions/2026-11-14-release-1-56-0.md`.

**Known blockers:**

- `patients-served`'s `validate-docs` is red on its bump (archive baseline
  drift), as on every constitution bump until that repository's next archive
  rebuild.
- Six older-style adopters got the session-log rule in `AGENTS.md` and
  `CLAUDE.md` only, and no adopter's `.aider.conf.yml` or
  `.continue/config.json` was changed (see `TODO.md`).

**Context hints:** `ubuntu-latest` is now Ubuntu 26.04 (no Python 3.8/3.9
for `actions/setup-python`, default JDK 25, `webkit2gtk-driver` renamed);
three adopters are pinned around it on their bump branches.

## Next Steps

**Human action required:** steps 1, 2, 3, and 4.

1. [ ] **HUMAN** — Review and merge the 18 `constitution/bump-v1.56.0` pull
   requests.
   - **Why a human:** merging into each adopter's default branch is the
     maintainer's decision. Each pull request changes instruction files as
     well as the pin, so read one template-shaped and one older-style
     repository before merging the rest.
   - **You need:** `gh search prs "constitution: bump to v1.56.0" --owner esanacore --state open`
   - **Done when:** every adopter's `constitution/` gitlink is `7615a92`.
2. [ ] **HUMAN** — Review and merge this handoff pull request.
   - **Why a human:** merging to `main` is the maintainer's decision.
   - **Done when:** the pull request is merged.
3. [ ] **HUMAN** — Walk the pitch deck; approve the voice or list edits, and
   give a consulting contact for the call to action if you want one.
   - **Why a human:** personal brand and public contact details are the
     author's.
   - **Done when:** the deck is approved as-is, or edits and a contact string
     are given.
4. [ ] **HUMAN** — Choose a pilot participant, a real bounded request, and a
   product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** participant and owner agree on a request and the
     permitted material.
5. [ ] **AGENT** _(suggestion)_ — Hand-merge the session-log rule into
   adopters' `.aider.conf.yml` and `.continue/config.json`, and bring the six
   older-style adopters' instruction files up to the current templates.
6. [ ] **AGENT** _(suggestion)_ — Move `AI-Process-Engineer`'s e2e job to
   `webkitgtk-webdriver` and `MultiplatformTestApp` to a Gradle that runs on
   current JDKs, so the runner pins can come off.
=======
### Session: 2026-11-20 (Drawings standard, ADR-0008)

On `feat/drawings-and-plate`: every adopter is asked for a patent-style
plate in `docs/drawings/` (numbered parts, a key, a line saying it is not a
patent), and every adopter with a physical component for a dimensioned
drawing set generated from its CAD. Shipped with it: `DOCUMENTATION.md`
"Drawings", ADR-0008, `scripts/check_drawings.sh` (14 test cases), the
scaffold in `templates/docs/drawings/`, `docs/drawings` in the recommended
compliance tier, the rule in every instruction file, and the framework's own
plate in `README.md` and `demo.html`. Summary:
`docs/sessions/2026-11-20-drawings-and-the-plate.md`.

**Known blockers:** none. The 1.56.0 follow-ups from the previous handoff
(tag, fleet bump, superseded 1.55.0 pull requests, pitch deck review, pilot)
are not touched by this branch; check their state before releasing.

**Context hints:** the drawings are a documentation-workflow expectation by
the maintainer's decision: warn-only, recommended tier, no plan to make them
required. The framework ships no drawing-set generator. Adopters never
provide information back to the framework or publicly, so nothing from an
adopter belongs in this repository.

## Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Review the pull request and merge it when CI is green.
   - **Why a human:** a new standard for every adopter is the maintainer's
     to approve.
   - **Done when:** the pull request is merged, or changes are requested.
2. [ ] **AGENT** — Cut the release that carries this (the next MINOR after
   the latest tag; check the tag first) _(blocked by step 1)_
3. [ ] **AGENT** — On the fleet bump, draw a plate for each adopter and add
   the instruction-file line; hardware adopters also link their drawing set
   _(blocked by step 2)_
4. [ ] **AUTOMATED** — `tests.yml` runs the suite and the self-governance
   checks, including `check_drawings.sh --strict`, on the pull request.
>>>>>>> origin/main
