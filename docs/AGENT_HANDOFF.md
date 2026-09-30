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

- **Accomplishments**: `v1.50.0` tagged at `485b5df` and published as a
  GitHub Release from a local session (`release-tag-alignment` green). PR #78
  (the Next Steps procedure, ADR-0005) merged at `68bd253`. On this branch:
  the 1.51.0 release — `VERSION`, every version reference, and the dated
  CHANGELOG section.
- **Verification Run**: `bash scripts/run_all_tests.sh`,
  `bash scripts/test_release_docs.sh`, `bash scripts/test_mcp_resources.sh`,
  `bash scripts/check_next_steps.sh --strict .`, and
  `bash scripts/check_secrets.sh --strict .` — all green.
- **Known Blockers**: none. The local session can push tags, publish
  releases, and reach the adopter repositories; each of those waits on the
  maintainer's go-ahead.
- **Context Hints**: `docs/adr/0005-next-steps-procedure.md`; the pull request
  path of `bump_adopters.sh` gets its first real run in the 1.51.0 fleet bump
  (GAP-001 in `docs/TEST_PLAN.md`). The adopter list lives outside this
  public repository, at `~/.config/engineering-constitution/adopters.txt`.

#### Next Steps

**Human action required:** steps 1 and 4.

1. [ ] **HUMAN** — Approve merging the 1.51.0 release pull request
   - **Why a human:** merging a release is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AGENT** — Tag the release merge commit `v1.51.0` by SHA and publish the GitHub Release marked Latest _(blocked by step 1)_
3. [ ] **AGENT** — Build `adopters.txt` from `.gitmodules` across the esanacore repositories and dry-run `scripts/bump_adopters.sh --sha <v1.51.0 merge SHA>` _(blocked by step 2)_
4. [ ] **HUMAN** — Approve the fleet bump, then approve merging the green adopter PRs _(blocked by step 3)_
   - **Why a human:** the bump opens a pull request in every adopter repository, some of them private, and merging them is the maintainer's call.
   - **You need:** the dry-run summary from step 3.
   - **Procedure:**
     1. Read the dry run: skipped repos, each version-reference rewrite, any `NOTE` lines.
     2. Approve the real run; the agent opens one PR per adopter.
     3. Approve merging the green PRs (gentle-table and patients-served squash; the rest merge).
   - **Done when:** every adopter's `version-gate` check is green.
5. [ ] **AGENT** — Audit the fleet's `demo.html` files with `scripts/check_demo_page.sh` (read-only) and propose fixes _(blocked by step 4)_
6. [ ] **AGENT** — In the next constitution PR: record the approved `docs/MEMORY.md` entries, and close or update the `bump_adopters.sh` `gh pr create` TODO item and GAP-001 _(blocked by step 4)_
7. [ ] **AUTOMATED** — `tests.yml` runs on the release PR; `self-governance` includes the strict Next Steps check.
