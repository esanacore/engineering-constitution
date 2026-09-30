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

- **Accomplishments**: `v1.50.0`, `v1.51.0`, and `v1.52.0` tagged by SHA
  (`485b5df`, `eee5984`, `93510ce`) and published as GitHub Releases from a
  local session. 1.52.0 puts "keep the demo page current" into the Required
  Workflow, every instruction file and template, Solon, and both PR templates.
  1.51.0 fleet bump: 18 PRs opened; the 8 public adopters merged.
  SSH_DeviceManager (the only adopter with a `demo.html`) carries the demo
  rule in its own instruction files (PR #46) and passes `check_demo_page.sh`
  with 0 findings.
- **Verification Run**: `bash scripts/run_all_tests.sh` (29/29),
  `check_next_steps.sh --strict`, `check_secrets.sh --strict`;
  `release-tag-alignment` green on all three tags.
- **Known Blockers**: GitHub Actions does not start jobs in the 10 private
  adopters ("recent account payments have failed or your spending limit needs
  to be increased"); their 1.51.0 bump PRs are open and red without running.
- **Context Hints**: the adopter list is at
  `~/.config/engineering-constitution/adopters.txt` on the maintainer's
  machine (`docs/MEMORY.md`). Open 1.51.0 bump PRs: patients-served #59,
  Project-Greenhouse #66, AI_Workstation_Blueprints #33, GPU4HIRE_AI #30,
  MultiplatformTestApp #17, gentle-table #23, smart-teleprompter #20,
  AI-Process-Engineer #61, mfi-mpower-pro-toolkit #24, claude-drive-bridge #12.

#### Next Steps

**Human action required:** steps 1, 2, and 4.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **HUMAN** — Restore GitHub Actions for private repositories
   - **Why a human:** billing and spending limits are account settings only the owner can change.
   - **You need:** the GitHub account owner's login and a working payment method.
   - **Procedure:**
     1. Open github.com → Settings → Billing and licensing (Billing & plans).
     2. Fix the failed payment, or raise the Actions spending limit above $0.
   - **Done when:** a re-run of any private adopter's check actually starts a job.
3. [ ] **AGENT** — Close the 10 open 1.51.0 bump PRs as superseded, then dry-run `bash scripts/bump_adopters.sh --sha 93510ce07fecb5e1eb941264db22b5c69fb48431 --repos ~/.config/engineering-constitution/adopters.txt --dry-run` _(blocked by step 2)_
4. [ ] **HUMAN** — Approve the 1.52.0 fleet bump and merging its green PRs _(blocked by step 3)_
   - **Why a human:** the bump opens a pull request in every adopter repository, some private, and merging them is the maintainer's call.
   - **You need:** the dry-run summary from step 3.
   - **Procedure:**
     1. Read the dry run: skipped repos, each version-reference rewrite, any `NOTE` lines.
     2. Approve the real run, then approve merging the green PRs (gentle-table and patients-served squash; the rest merge).
   - **Done when:** every adopter's `version-gate` check is green.
5. [ ] **AUTOMATED** — `tests.yml` runs on this PR; `self-governance` includes the strict Next Steps check.
6. [ ] **AGENT** _(suggestion)_ — Give the remaining product-facing adopters a `demo.html` (`TODO.md`); each new page picks up the "keep the demo page current" rule from the templates only if its instruction files are refreshed too.
