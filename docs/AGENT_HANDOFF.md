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

### Session: 2026-11-14 (Release 1.56.0 prepared)

1.56.0 is prepared on `release/v1.56.0`: the generated session-log index
(`scripts/build_session_index.sh`, now also checked in warn mode by the
adopter compliance workflow template), the pitch deck, and the two
ADR-0007 decisions the maintainer made — `docs/sessions` stays in the
recommended tier, and summaries need no separate approval. `RELEASES.md`
now says a new recommended file must be added to strict-mode adopters on
the fleet bump. Three approved learnings are in `docs/MEMORY.md`.
Summary: `docs/sessions/2026-11-14-release-1-56-0.md`.

**Known blockers:** none for the release. The 18 open
`constitution/bump-v1.55.0` pull requests are superseded by the 1.56.0 bump;
four of them carry extra commits (session-log files on `patients-served`
and `MultiplatformTestApp`; `ubuntu-24.04` pins on `SSH_DeviceManager` and
`AI-Process-Engineer`; a JDK 17 step on `MultiplatformTestApp`) that must be
carried onto the new branches before the old ones are closed.

**Context hints:** `ubuntu-latest` is now Ubuntu 26.04 (no Python 3.8/3.9
for `actions/setup-python`, default JDK 25, `webkit2gtk-driver` renamed).
`patients-served`'s `validate-docs` is red on every constitution bump until
that repository's next archive rebuild.

## Next Steps

**Human action required:** steps 1, 4, 5, and 6.

1. [ ] **HUMAN** — Review and merge the 1.56.0 release pull request when CI
   is green.
   - **Why a human:** merging a release to `main` is the maintainer's
     decision.
   - **Done when:** the pull request is merged.
2. [ ] **AGENT** — Tag `v1.56.0` on the merge commit, publish the GitHub
   Release from the `## 1.56.0` changelog section, and confirm
   `release-tag-alignment` passes. The maintainer delegated this for 1.56.0
   _(blocked by step 1)_
3. [ ] **AGENT** — Run the 1.56.0 fleet bump; on each bump branch add the
   session-log index, template, and instruction-file line, and carry over
   the four 1.55.0 branches' extra commits; then close the 18 superseded
   1.55.0 pull requests _(blocked by step 2)_
4. [ ] **HUMAN** — Review and merge the 18 `constitution/bump-v1.56.0` pull
   requests.
   - **Why a human:** merging into each adopter's default branch is the
     maintainer's decision.
   - **Done when:** every adopter's `constitution/` gitlink is the 1.56.0
     release commit.
5. [ ] **HUMAN** — Walk the pitch deck; approve the voice or list edits, and
   give a consulting contact for the call to action if you want one.
   - **Why a human:** personal brand and public contact details are the
     author's.
   - **Done when:** the deck is approved as-is, or edits and a contact string
     are given.
6. [ ] **HUMAN** — Choose a pilot participant, a real bounded request, and a
   product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** participant and owner agree on a request and the
     permitted material.
7. [ ] **AGENT** _(suggestion)_ — Move `AI-Process-Engineer`'s e2e job to
   `webkitgtk-webdriver` and `MultiplatformTestApp` to a Gradle that runs on
   current JDKs, so the runner pins can come off.
