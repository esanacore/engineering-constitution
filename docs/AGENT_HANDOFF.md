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

### Session: 2026-10-10 (check_readme)

- **Accomplishments**: `scripts/check_readme.sh`, the README standard's
  mechanical half checked rather than reviewed: command blocks with no
  supported-platforms statement or no Windows/macOS mention (naming a
  platform as unsupported counts), `<details>` blocks missing the blank
  lines the renderer needs, nested or unclosed, with a vague summary or a
  heading inside, and a PowerShell/cmd Windows block using
  `export`/`source`. `--file`
  covers `docs/SETUP.md` and friends. `tests.yml` runs it `--strict` on
  this repository's README, `docs/SETUP.md`, `docs/TROUBLESHOOTING.md`, the
  README and SETUP templates, and the sample project; the adopter compliance
  template runs it in warn mode. Dogfooding found `docs/TROUBLESHOOTING.md`
  never mentioned macOS (fixed) and that this repository's own README
  mentions `<details>` in inline code (the checker now ignores code spans).
  The critique pass found a regex interval expression (`#{1,6}`) that older
  `mawk` builds silently never match, a Git Bash block wrongly held to
  PowerShell syntax, and multi-line / code-span summaries misread; all fixed
  with regression tests.
- **Verification Run**: `bash scripts/run_all_tests.sh --quiet` (31 suites
  green, including the new `test_check_readme.sh`), every `tests.yml`
  self-governance step locally, and an isolated critique pass on the diff.
- **Known Blockers**: v1.54.0 is tagged by nobody yet and v1.53.0 has no
  GitHub Release — both are the local session's job (see the handoff prompt
  Eric was given). No release is cut here for that reason: stacking 1.55.0 on
  an untagged 1.54.0 would leave the fleet two tags behind.
- **Context Hints**: `DOCUMENTATION.md` "README Expectations" is the rule;
  the checker's header comment lists exactly what it verifies. The fleet's
  READMEs have not been audited against the rule yet (`TODO.md` →
  Documentation); the checker makes that audit a one-liner per adopter.

#### Next Steps

**Human action required:** steps 1, 3, and 4.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs the suite and the strict self-governance job (now including the README checks) on the PR; `wiki-sync.yml` republishes the wiki on merge. Watch for a red run.
3. [ ] **HUMAN** — Run the local-session handoff for 1.54.0 (tag `v1.54.0`, publish the v1.53.0 and v1.54.0 releases, bump the fleet with the Stop hook rollout)
   - **Why a human:** remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** the `local-session-handoff-1.54.0.md` prompt from the cloud session, a local clone, `gh` signed in.
   - **Done when:** `gh release list` shows v1.54.0 as Latest and every adopter's `constitution-version.yml` is green.
4. [ ] **HUMAN** — Decide whether 1.55.0 is cut right after step 3 or waits for more `Unreleased` entries, and whether the proposed memory entry (no regex interval expressions in shipped awk: older `mawk` silently never matches them) is recorded _(blocked by step 3)_
   - **Why a human:** release cadence and `docs/MEMORY.md` entries are the maintainer's call; `RELEASES.md` says not to let `Unreleased` sit.
   - **Done when:** either a release PR is open or the decision is recorded in `TODO.md`; the memory entry is recorded or declined.
5. [ ] **AGENT** — Audit the fleet's READMEs with `check_readme.sh` (one shallow clone per adopter, warn mode) and open per-adopter PRs for the findings (`TODO.md` → Documentation) _(blocked by step 3)_.
6. [ ] **AGENT** _(suggestion)_ — Teach `measure_instruction_weight.sh` to estimate scoped reads (`TODO.md` → Features), the oldest open tooling item.
