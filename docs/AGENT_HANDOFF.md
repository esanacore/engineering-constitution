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

### Session: 2026-10-10 (scoped instruction weight)

- **Accomplishments**: `scripts/measure_instruction_weight.sh` measures
  scoped reads as instructed. A reading bullet carrying "open (`[ ]`/`[~]`)
  items" or "the `Unreleased` section and the most recent release" is
  measured as the instruction says — `TODO.md` keeps headings, open items
  and their continuation lines, nesting tracked by indent; `CHANGELOG.md`
  keeps the preamble, `## Unreleased` wherever it is, and the first other
  `## ` section, fences ignored — with the whole-file figure
  alongside, `TOTAL (as instructed)` and `TOTAL (whole files)` at the end,
  and `HEAVY` judged on the instructed figure. Unrecognized wording measures
  the whole file. The figure `TODO.md` had waited for since 1.48.0 is
  recorded there: the `CLAUDE.md` order reads at ~38.3k estimated tokens as
  instructed against ~77.3k whole-file; the critique pass's findings (loose
  qualifier matching that scoped "open items you own" to 0 bytes, `## `
  lines inside fences, Unreleased not first, a completed parent's notes
  re-opened by an open child, order-dependent dedup) are fixed with a
  regression case; neither `AI_WORKFLOW.md` nor
  `SECURITY.md` crossed `HEAVY`; `INTEGRATION.md` (~11.8k, `AGENTS.md`
  order only) is the one remaining heavy read and has its own `TODO.md`
  item now.
- **Verification Run**: `bash scripts/run_all_tests.sh --quiet` (31 suites
  green; `test_measure_instruction_weight.sh` has four new cases including a
  dogfood run), every `tests.yml` self-governance step locally, and an
  isolated critique pass on the diff.
- **Known Blockers**: this work is stacked on the branch behind PR #91
  (`check_readme.sh`), still open; it rides that PR, whose title and
  description now cover both changes. v1.54.0
  remains untagged and v1.53.0 unpublished (the local-session handoff).
- **Context Hints**: the two qualifier phrasings live in `CLAUDE.md`,
  `AGENTS.md`, and their templates; an adopter that rewords a bullet gets a
  whole-file row, never a wrong number. The meter's header comment lists
  exactly what each scope keeps.

#### Next Steps

**Human action required:** steps 1, 3, and 4.

1. [ ] **HUMAN** — Merge PR #91 (`check_readme.sh`)
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs the suite and the strict self-governance job on the PR; `wiki-sync.yml` republishes the wiki on merge. Watch for a red run.
3. [ ] **HUMAN** — Run the local-session handoff for 1.54.0 (tag `v1.54.0`, publish the v1.53.0 and v1.54.0 releases, bump the fleet with the Stop hook rollout)
   - **Why a human:** remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** the `local-session-handoff-1.54.0.md` prompt from the cloud session, a local clone, `gh` signed in.
   - **Done when:** `gh release list` shows v1.54.0 as Latest and every adopter's `constitution-version.yml` is green.
4. [ ] **HUMAN** — Decide whether 1.55.0 is cut right after step 3 (two `Unreleased` entries are waiting) and whether the proposed memory entry (no regex interval expressions in shipped awk) is recorded _(blocked by step 3)_
   - **Why a human:** release cadence and `docs/MEMORY.md` entries are the maintainer's call.
   - **Done when:** either a release PR is open or the decision is recorded in `TODO.md`; the memory entry is recorded or declined.
5. [ ] **AGENT** — Audit the fleet's READMEs with `check_readme.sh` and open per-adopter PRs for the findings (`TODO.md` → Documentation) _(blocked by step 3)_.
6. [ ] **AGENT** _(suggestion)_ — Decide and implement the `INTEGRATION.md` scoping recorded in `TODO.md`, the one remaining `HEAVY` read in the `AGENTS.md` order.
