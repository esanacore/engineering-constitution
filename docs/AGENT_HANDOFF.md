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

- **Accomplishments**: `v1.50.0` and `v1.51.0` tagged by SHA (`485b5df`,
  `eee5984`) and published as GitHub Releases from a local session. The
  1.51.0 fleet bump opened 18 PRs; the 8 public adopters merged. On this
  branch: 1.52.0 — "keep the demo page current" in the Required Workflow,
  every instruction file and template, Solon, and both PR templates; three
  approved `docs/MEMORY.md` entries; GAP-001 mitigated.
- **Verification Run**: `bash scripts/run_all_tests.sh` (29/29),
  `test_release_docs.sh`, `test_mcp_resources.sh`,
  `check_instruction_templates.sh --strict` with the new `demo page current`
  anchor on `.`, `templates`, and `examples/sample-project`,
  `check_next_steps.sh --strict`, `check_secrets.sh --strict`.
- **Known Blockers**: GitHub Actions does not start jobs in the 10 private
  adopters ("recent account payments have failed or your spending limit needs
  to be increased"), so their 1.51.0 bump PRs are red without running.
- **Context Hints**: the adopter list is at
  `~/.config/engineering-constitution/adopters.txt` on the maintainer's
  machine. Only SSH_DeviceManager has a `demo.html` today; adopters keep their
  own copies of instruction files, so it needs its own PR for the new rule.

#### Next Steps

**Human action required:** steps 1, 3, and 5.

1. [ ] **HUMAN** — Approve merging the 1.52.0 pull request
   - **Why a human:** merging a release is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AGENT** — Tag the merge commit `v1.52.0` by SHA and publish the GitHub Release marked Latest _(blocked by step 1)_
3. [ ] **HUMAN** — Restore GitHub Actions for private repositories
   - **Why a human:** billing and spending limits are account settings only the owner can change.
   - **You need:** the GitHub account owner's login and a working payment method.
   - **Procedure:**
     1. Open github.com → Settings → Billing and licensing (Billing & plans).
     2. Fix the failed payment, or raise the Actions spending limit above $0.
   - **Done when:** a re-run of any private adopter's check actually starts a job.
4. [ ] **AGENT** — Close the 10 open 1.51.0 bump PRs as superseded, then dry-run `bump_adopters.sh --sha <v1.52.0 merge SHA>` across all 18 adopters _(blocked by steps 2 and 3)_
5. [ ] **HUMAN** — Approve the 1.52.0 fleet bump and merging its green PRs _(blocked by step 4)_
   - **Why a human:** the bump opens a pull request in every adopter repository, some private, and merging them is the maintainer's call.
   - **You need:** the dry-run summary from step 4.
   - **Done when:** every adopter's `version-gate` check is green.
6. [ ] **AGENT** — Open a PR in SSH_DeviceManager adding the "keep the demo page current" line to its own instruction files
7. [ ] **AGENT** — Audit the fleet's `demo.html` files with `scripts/check_demo_page.sh` (read-only) and propose fixes
8. [ ] **AUTOMATED** — `tests.yml` runs on this PR; `self-governance` enforces the new instruction-file anchor.
