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

### Session: 2026-11-14 (generated session-log index; fleet bump CI fixes)

`scripts/build_session_index.sh` now writes the table in
`docs/sessions/README.md` from the entries (date, title, Topics; newest
first, same day in file-name order). `--check` fails on a stale index and CI
runs it for the framework and the sample project. The documentation, the
session-log README and template, and the `session-summary-writer` skill say
to rebuild the index instead of adding a row. Full suite: 36 of 36.
A follow-up fixes three automated-review findings on that change (failed
directory listing, CRLF line endings, an overstated concurrency claim).
Summary: `docs/sessions/2026-11-14-generated-session-index.md`.

1.55.0 is tagged and released (with `v1.54.0` and the 1.53.0 and 1.54.0
Releases backfilled), and all 18 adopters have a `constitution/bump-v1.55.0`
pull request. Fixes pushed to four of those branches: the session-log index
and template on `patients-served` and `MultiplatformTestApp` (both run
`check_compliance.sh --strict`), an `ubuntu-24.04` runner pin on
`SSH_DeviceManager` and on `AI-Process-Engineer`'s e2e job, and a JDK 17
step on `MultiplatformTestApp`'s test runner.

**Known blockers:**

- `patients-served`'s `validate-docs` is red on the bump (baseline drift on
  `CLAUDE.md` and `CONSTITUTION_VERSION`). It was red on the merged 1.52.0
  bump too and clears at that repository's next archive rebuild.
- The adopter workflow template does not run `build_session_index.sh
  --check` yet: adopters get the script only with the next release.

**Context hints:** `ubuntu-latest` is now Ubuntu 26.04 (no Python 3.8/3.9
for `actions/setup-python`, default JDK 25, `webkit2gtk-driver` renamed);
expect the same class of failure in other adopters' own workflows.

## Next Steps

**Human action required:** steps 1, 2, 3, 4, and 5.

1. [ ] **HUMAN** — Review and merge this pull request (review fixes for the
   index generator) when CI is green.
   - **Why a human:** merging to `main` is the maintainer's decision.
   - **Done when:** the pull request is merged.
2. [ ] **HUMAN** — Review and merge the 18 `constitution/bump-v1.55.0` pull
   requests.
   - **Why a human:** merging into each adopter's default branch is the
     maintainer's decision; four carry extra commits to read (see above).
   - **You need:** `gh search prs "constitution: bump to v1.55.0" --owner esanacore --state open`
   - **Done when:** every adopter's `constitution/` gitlink is `111769c`.
3. [ ] **HUMAN** — Decide whether `docs/sessions` stays in the recommended
   compliance tier, and whether session summaries need approval before they
   are committed, as `docs/MEMORY.md` does.
   - **Why a human:** both set policy for every adopter; the first already
     broke two strict-mode repositories on this bump.
   - **Done when:** the decision is stated; an agent records it in ADR-0007.
4. [ ] **HUMAN** — Walk the pitch deck; approve the voice or list edits, and
   give a consulting contact for the call to action if you want one.
   - **Why a human:** personal brand and public contact details are the
     author's.
   - **Done when:** the deck is approved as-is, or edits and a contact string
     are given.
5. [ ] **HUMAN** — Choose a pilot participant, a real bounded request, and a
   product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** participant and owner agree on a request and the
     permitted material.
6. [ ] **AGENT** — Add the session-log index, template, and instruction-file
   line to the 16 adopters that do not have them yet _(blocked by step 3)_
7. [ ] **AGENT** — At the next release, add a warn-mode
   `build_session_index.sh --check` step to the adopter compliance workflow
   template _(blocked by step 1)_
8. [ ] **AGENT** _(suggestion)_ — Move `AI-Process-Engineer`'s e2e job to
   `webkitgtk-webdriver` and `MultiplatformTestApp` to a Gradle that runs on
   current JDKs, so the runner pins can come off.
