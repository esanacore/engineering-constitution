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
  (`485b5df`, `eee5984`, `93510ce`) and published as GitHub Releases.
  1.52.0 puts "keep the demo page current" into the Required Workflow, every
  instruction file and template, Solon, and both PR templates. All 18
  adopters now pin `constitution/` at `93510ce` (v1.52.0): the 8 public ones
  merged with green CI; the 10 private ones merged without CI, on the
  maintainer's approval, because GitHub Actions does not start jobs in
  private repositories on this account.
- **Verification Run**: `bash scripts/run_all_tests.sh` (29/29),
  `check_next_steps.sh --strict`, `check_secrets.sh --strict`;
  `release-tag-alignment` green on all three tags; every adopter's default
  branch checked to pin `93510ce`.
- **Known Blockers**: private adopters' CI does not run ("recent account
  payments have failed or your spending limit needs to be increased"),
  even on GitHub Free with no failed payment in the billing history.
- **Context Hints**: the adopter list is at
  `~/.config/engineering-constitution/adopters.txt` on the maintainer's
  machine (`docs/MEMORY.md`). To finish the bump, gentle-table's branch
  protection was set to let admins bypass, and patients-served's
  "Protect main" ruleset gained a Repository admin bypass.

#### Next Steps

**Human action required:** steps 1, 2, and 3.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **HUMAN** — Decide whether to restore the stricter protection on gentle-table and patients-served
   - **Why a human:** branch protection and rulesets are repository settings the owner controls.
   - **Procedure:**
     1. gentle-table: Settings → Branches → `main` → turn "Do not allow bypassing the above settings" back on.
     2. patients-served: Settings → Rules → Rulesets → "Protect main" → remove Repository admin from the bypass list.
   - **Done when:** both settings are back to how you want them. Leaving them relaxed means the next fleet bump can merge there while private CI is down.
3. [ ] **HUMAN** — Find out why private-repository Actions stay locked on GitHub Free
   - **Why a human:** only the account owner can see the billing state or open a GitHub Support ticket.
   - **Procedure:**
     1. Check Settings → Billing and licensing → Plans for a pending downgrade date, and Budgets for an Actions budget set to $0 with "stop usage".
     2. If nothing explains it after a day, open a GitHub Support ticket quoting the job annotation.
   - **Done when:** a re-run of any private adopter's check starts a job.
4. [ ] **AUTOMATED** — `tests.yml` runs on this PR; `self-governance` includes the strict Next Steps check.
5. [ ] **AGENT** _(suggestion)_ — Give the remaining product-facing adopters a `demo.html` (`TODO.md`), and refresh their instruction files so they carry the "keep the demo page current" rule.
