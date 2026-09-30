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

### Session: 2026-09-30

- **Accomplishments**: 1.50.0 merged (`scripts/check_demo_page.sh`; the
  constitution's own `demo.html` no longer loads Google Fonts). On this
  branch: the Next Steps procedure (`AI_WORKFLOW.md`, ADR-0005,
  `scripts/check_next_steps.sh`, every instruction file, handoff and PR
  templates).
- **Verification Run**: `bash scripts/run_all_tests.sh` (all suites green) and
  every self-governance checker in `--strict` mode.
- **Known Blockers**: the remote session's Git proxy refuses tag pushes, so
  `v1.50.0` is not yet tagged; the maintainer tags from a local clone.
- **Context Hints**: `docs/adr/0005-next-steps-procedure.md`; the pull request
  path of `bump_adopters.sh` is still verified only by hand (GAP-001 in
  `docs/TEST_PLAN.md`).

#### Next Steps

**Human action required:** steps 1, 2, 3, and 5.

1. [ ] **HUMAN** — Tag the 1.50.0 release commit
   - **Why a human:** this cloud session can't push tags.
   - **You need:** a local clone with push access.
   - **Procedure:**
     1. `git fetch origin`
     2. `git tag -a v1.50.0 485b5df5f01424d5769157f9d6eaddc40c86d024 -m "v1.50.0 — the demo page standard, checked"`
     3. `git show v1.50.0^{commit}:VERSION` must print `1.50.0`.
     4. `git push origin v1.50.0`
   - **Done when:** `release-tag-alignment` passes on the tag.
2. [ ] **HUMAN** — Publish the v1.50.0 GitHub Release _(blocked by step 1)_
   - **Why a human:** releases are published from the web UI.
   - **Procedure:**
     1. Open `https://github.com/esanacore/engineering-constitution/releases/new?tag=v1.50.0`.
     2. Paste the `## 1.50.0` section of `CHANGELOG.md` as the notes.
     3. Tick "Set as the latest release" and publish.
   - **Done when:** v1.50.0 shows as Latest.
3. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision, and this changes the Required Workflow (ADR-0005).
   - **Done when:** the PR is merged and CI on `main` is green.
4. [ ] **AGENT** — Cut v1.51.0 with this change _(blocked by steps 1 and 3)_
5. [ ] **HUMAN** — Bump the adopter fleet to the newest release _(blocked by step 4)_
   - **Why a human:** this session can't attach the adopter repositories, so the script runs from a local clone with `gh` signed in.
   - **Procedure:**
     1. `bash scripts/bump_adopters.sh --sha <release merge commit> --repos <list> --dry-run` and read the output.
     2. Run it again without `--dry-run`, then merge the PRs it opens. gentle-table and patients-served need squash merges.
   - **Done when:** every adopter's `version-gate` check is green.
6. [ ] **AUTOMATED** — `tests.yml` runs on this PR. Watch `self-governance`, which now includes the Next Steps check.
7. [ ] **AGENT** _(suggestion)_ — Add the Claude Code `Stop` hook from `TODO.md` so a missing procedure is caught when a session ends.
