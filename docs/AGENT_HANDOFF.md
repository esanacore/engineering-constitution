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
   - **Why a human:** the remote session cannot push tags.
   - **You need:** a local clone with push access to `esanacore/engineering-constitution`.
   - **Procedure:**
     1. `git fetch origin`
     2. `git tag -a v1.50.0 485b5df5f01424d5769157f9d6eaddc40c86d024 -m "v1.50.0 — the demo page standard, checked"`
     3. `git show v1.50.0^{commit}:VERSION` — must print `1.50.0`.
     4. `git push origin v1.50.0`
   - **Done when:** `release-tag-alignment` passes on the tag in the Actions tab.
2. [ ] **HUMAN** — Publish the v1.50.0 GitHub Release _(blocked by step 1)_
   - **Why a human:** GitHub Releases are published from the web UI; agent sessions have no release tool.
   - **Procedure:**
     1. Open `https://github.com/esanacore/engineering-constitution/releases/new?tag=v1.50.0`.
     2. Title it `v1.50.0 — the demo page standard, checked`.
     3. Paste the `## 1.50.0` section of `CHANGELOG.md` (without its heading) as the notes.
     4. Tick "Set as the latest release" and publish.
   - **Done when:** the release page shows v1.50.0 marked Latest.
3. [ ] **HUMAN** — Bump the adopter fleet to 1.50.0 _(blocked by step 1)_
   - **Why a human:** the remote session cannot attach adopter repositories; the script runs from a local clone with `gh` authenticated.
   - **You need:** `gh auth status` green, and the list of adopter repositories.
   - **Procedure:**
     1. `bash scripts/bump_adopters.sh --sha 485b5df5f01424d5769157f9d6eaddc40c86d024 --repos <list> --dry-run` and read the planned rewrites.
     2. Re-run without `--dry-run` to open one pull request per adopter.
     3. Merge them; `gentle-table` and `patients-served` need a squash merge.
   - **Done when:** every adopter's `version-gate` check is green on its default branch.
4. [ ] **AUTOMATED** — `tests.yml` runs on this branch's pull request; watch `self-governance` for red.
5. [ ] **HUMAN** — Review and merge the Next Steps procedure pull request
   - **Why a human:** merging is the maintainer's decision, and this changes the Required Workflow (ADR-0005).
   - **Done when:** the pull request is merged and CI on `main` is green.
6. [ ] **AGENT** _(suggestion)_ — Run `check_demo_page.sh` across the adopters' existing `demo.html` files (TODO.md) before any repository flips it to `--strict`.
