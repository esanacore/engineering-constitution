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

### Session: 2026-10-02

- **Accomplishments**: `v1.50.0`, `v1.51.0`, and `v1.52.0` tagged and
  released; all 18 adopters pin `constitution/` at `93510ce` (v1.52.0).
  Demo pages added and merged in nine more product-facing adopters
  (DevLaunchpad, istqb-quiz-simulator, Project-Greenhouse,
  AI-Process-Engineer, smart-teleprompter, gentle-table, patients-served,
  PicklesToys, 702_with_the_view), so all ten now carry one, each with the
  "keep the demo page current" rule in its instruction files.
- **Verification Run**: every demo PR passed `check_demo_page.sh --strict`,
  `check_instruction_templates.sh --anchor "demo page current"`, and
  `check_next_steps.sh --strict` from a fresh clone; CI on each adopter's
  default branch was green after merge (smart-teleprompter's Dependency
  Audit excepted, fixed in its PR #23).
- **Known Blockers**: none. GitHub Actions runs in private adopters again
  as of 2026-10-02, after the account moved to GitHub Free.
- **Context Hints**: the adopter list is at
  `~/.config/engineering-constitution/adopters.txt` on the maintainer's
  machine. None of the demo pages is published yet (`TODO.md`).

#### Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs on this PR; `self-governance` includes the strict Next Steps check.
3. [ ] **AGENT** _(suggestion)_ — Publish the adopters' demo pages (GitHub Pages) and link the published URLs from their READMEs.
