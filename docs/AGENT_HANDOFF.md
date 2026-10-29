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

### Session: 2026-10-28 (Dogfood the framework's own visuals: clean demo redesign, Solarized code, hand-built hero SVG)

- **Accomplishments**: Made the framework's own front-facing artifacts follow
  the demo-page standard it publishes. **`demo.html`** was rebuilt as a clean,
  professional, accessible dark theme — the gradient-clipped headings, neon
  glows, radial blobs, and glass blur (AI-slop tells) are gone — and now shows
  **real Solarized Dark code** using the canonical `--code-*` palette
  (`DOCUMENTATION.md` "Code Snippets in Rendered Documentation"): a
  `bootstrap.sh` run, the `check_architecture.sh` layer table with a failing
  case, and a Next Steps excerpt. Depth moved behind `<details>` "why this
  matters" expanders (page-level progressive disclosure), and the 12-principle
  grid is generated from one data object. Still one self-contained file (inline
  styles + scripts, no network). The **hero infographic** moved from an
  AI-generated raster JPG to a hand-authored, themeable
  `assets/diagrams/constitution-infographic.svg` (its own dark panel reads on
  GitHub light and dark); `README.md` and `assets/diagrams/README.md` updated,
  JPG `git rm`'d. No ADR: the demo and hero are encouraged artifacts, no
  Required File / Workflow / checker contract / compatibility policy changed.
- **Verification Run**: `scripts/check_demo_page.sh --strict .` → 0 findings;
  `scripts/check_readme.sh --strict .` → passes; all nine Solarized hexes
  present as `--code-*` vars in `demo.html`. Served the repo locally and
  verified in a browser: SVG hero renders, Solarized blocks highlight correctly
  (dim prompt/comment, blue calls, cyan paths, magenta numbers, green `[OK]`,
  red `[FAIL]`), the principle modal and triad tabs work (JS runs, no console
  errors), and the layout stacks cleanly at 390px. Fixed a teaser bug where a
  naive `split(".")` truncated Principle 3 to "TODO.". The full shell suite
  (`run_all_tests.sh`) was not run — no shell logic changed, only `demo.html`,
  an SVG, README, CHANGELOG, TODO, and handoff docs — so CI is the backstop.
- **Known Blockers**: Committed on branch `docs/demo-visual-overhaul`; a PR is
  open (see the PR for the number). No `VERSION` bump, on purpose, so
  `check_version_alignment.sh` stays green while work accumulates in
  `Unreleased` (which now also holds the Dependabot work, the
  `actions/checkout` pin, and the earlier demo-page-conventions change). The
  prior handoff's release debt (v1.54.0 untagged, v1.53.0/v1.54.0 unpublished)
  is unchanged and still a maintainer task.
- **Context Hints**: The canonical Solarized block + `details.more` pattern
  reused verbatim from `templates/demo.html`; palette table in
  `DOCUMENTATION.md:456-505`. The deferred PDF brief has a worked reference in
  `ate-harness-demo` (`scripts/build_publish.py`: page + PDF from one source,
  build-time highlight, `--check` drift guard) and pairs with the mechanical
  Solarized/PDF checker — both still open in `TODO.md` under the demo-page item.
  That generator introduces a build toolchain and likely warrants its own ADR.

#### Next Steps

**Human action required:** steps 1 and 3.

1. [ ] **HUMAN** — Review and merge the PR for `docs/demo-visual-overhaul`.
   - **Why a human:** this is a subjective visual/design change; the look and the merge decision are the maintainer's.
   - **You need:** the open PR, CI green.
   - **Done when:** the PR is merged to `main`.
2. [ ] **AUTOMATED** — `tests.yml` runs the full suite and the strict self-governance job (including `check_demo_page.sh`, `check_readme.sh`, `check_next_steps.sh`) on the PR; `wiki-sync.yml` republishes on merge. Watch for a red run.
3. [ ] **HUMAN** — Decide whether to fold this into the pending release or ship it separately, and clear the carried-over release debt (tag `v1.54.0`, publish v1.53.0/v1.54.0, bump the fleet).
   - **Why a human:** release cadence is the maintainer's call, and remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** a local clone, `gh` signed in.
   - **Done when:** the decision is recorded and `gh release list` shows the intended release as Latest.
4. [ ] **AGENT** — If CI flags anything in the edited files, fix it in the PR branch.
5. [ ] **AGENT** _(suggestion)_ — Build the deferred offline PDF brief + source-driven generator and the Solarized/PDF drift checker (`TODO.md` → demo-page follow-ups), with its own ADR for the new build toolchain.
