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

### Session: 2026-10-03

- **Accomplishments**: all 18 adopters pin `constitution/` at `93510ce`
  (v1.52.0). All ten product-facing adopters carry a `demo.html` with the
  "keep the demo page current" rule in their instruction files. Four demo
  pages are published: SSH_DeviceManager, DevLaunchpad and
  istqb-quiz-simulator on GitHub Pages, and gentle-table at
  `gentletable.com/demo.html`.
- **Verification Run**: each live URL returns 200 and matches its
  repository's `demo.html` by SHA-256; CI was green on every merged PR.
- **Known Blockers**: none.
- **Context Hints**: the adopter list is at
  `~/.config/engineering-constitution/adopters.txt` on the maintainer's
  machine. `TODO.md` records which demo pages are deliberately unpublished
  and why. Open findings from the demo work, not yet filed anywhere:
  DevLaunchpad's PNG assets are corrupted (saved as text) and its README
  lists four of six custom command types; patients-served's API validation
  rule 9 conflicts with FR-004-AC-2; AI-Process-Engineer names steps
  "the application" on live captures.

#### Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs on this PR; `self-governance` includes the strict Next Steps check.
3. [ ] **AGENT** _(suggestion)_ — Fix DevLaunchpad's corrupted PNG assets and bring its README's custom-command list in line with the code.
4. [ ] **AGENT** _(suggestion)_ — Add `demo-pages.yml` to the constitution's workflow templates (`TODO.md`).
