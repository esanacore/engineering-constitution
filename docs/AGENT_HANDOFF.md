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

### Session: 2026-10-12 (on-demand qualifier)

- **Accomplishments**: `scripts/measure_instruction_weight.sh` recognizes a
  third reading-bullet qualifier. A bullet whose text starts "when the task
  ..." or "read on demand" is an on-demand row: 0 in `TOTAL (as
  instructed)`, never `HEAVY`, the whole-file figure alongside and still in
  `TOTAL (whole files)`. Checked after the open/recent qualifiers, so the
  "read on demand" tail of the TODO/CHANGELOG bullets keeps their scopes.
  `AGENTS.md`'s `INTEGRATION.md` row (and the templates' `OPERATIONS.md`
  row) now report as on demand; the `AGENTS.md` order measures ~42.2k
  estimated tokens as instructed against ~93.3k whole-file, and no row is
  `HEAVY` in either instruction file. The `INTEGRATION.md` `TODO.md` item is
  closed without touching the reading order.
- **Verification Run**: `bash scripts/run_all_tests.sh --quiet` (31 suites
  green; `test_measure_instruction_weight.sh` gained an on-demand case and a
  dogfood case), every `tests.yml` self-governance step locally, and an
  isolated critique pass on the diff, which found three things now fixed
  with a regression case: the em dash written as `\x` escape bytes, which
  the UTF-8-aware BSD awk reads as a code point (any leading punctuation is
  skipped instead); "when the task is done, update it" and "on demand we may
  add" wrongly scoped (a subject verb is required, and "on demand" must end
  the bullet); and a file listed both as required reading and as a reference
  counted as on demand (required wins).
- **Known Blockers**: v1.54.0 untagged, v1.53.0 unpublished; four
  `Unreleased` entries now wait on the local-session handoff.
- **Context Hints**: the three qualifier phrasings are exactly the ones the
  instruction files and templates ship; anything else still measures the
  whole file. The meter's header comment lists what each scope keeps.

#### Next Steps

**Human action required:** steps 1, 3, and 4.

1. [ ] **HUMAN** — Review and merge the on-demand qualifier pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs the suite and the strict self-governance job on the PR; `wiki-sync.yml` republishes the wiki on merge. Watch for a red run.
3. [ ] **HUMAN** — Run the local-session handoff for 1.54.0 (tag `v1.54.0`, publish the v1.53.0 and v1.54.0 releases, bump the fleet with the Stop hook rollout)
   - **Why a human:** remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** the `local-session-handoff-1.54.0.md` prompt from the cloud session, a local clone, `gh` signed in.
   - **Done when:** `gh release list` shows v1.54.0 as Latest and every adopter's `constitution-version.yml` is green.
4. [ ] **HUMAN** — Decide whether 1.55.0 is cut right after step 3 (four `Unreleased` entries are waiting, one of them a security pin) and whether the proposed memory entry (no regex interval expressions in shipped awk) is recorded _(blocked by step 3)_
   - **Why a human:** release cadence and `docs/MEMORY.md` entries are the maintainer's call.
   - **Done when:** either a release PR is open or the decision is recorded in `TODO.md`; the memory entry is recorded or declined.
5. [ ] **AGENT** — Audit the fleet's READMEs with `check_readme.sh` and open per-adopter PRs for the findings (`TODO.md` → Documentation) _(blocked by step 3)_.
6. [ ] **AGENT** _(suggestion)_ — Extend `templates/.github/dependabot.yml` beyond the `github-actions` ecosystem (`TODO.md` → Features), so adopters with npm, pip, or Cargo manifests get the same advisory coverage this repository's `mcp-server/` just used.
