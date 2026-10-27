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

### Session: 2026-10-26 (Demo-page conventions: Solarized code, PDF brief, page-level progressive disclosure)

- **Accomplishments**: Codified three demo-page conventions proven in adopter
  projects (chiefly `ate-harness-demo`) into the framework's standards, all as
  prose-first refinements to the demo-page standard (ADR-0002), triggering no
  new ADR (no Required File, Required Workflow step, or checker contract
  changed). `DOCUMENTATION.md` gains a new **"Code Snippets in Rendered
  Documentation"** section (Solarized Dark / Schoonover palette for code in
  rendered HTML + PDF, as a CSS-variable table, highlighted at build time;
  framed as Principle 12 applied to presentation), an **"Offline PDF Brief"**
  subsection under "Demo Page" (a PDF twin built from repo sources, code
  excerpts pulled from real files, build-time freshness guard so page and PDF
  can't drift), and a generalized **"Progressive Disclosure"** (applies to the
  demo page and any long rendered doc, not only the README). `CONSTITUTION.md`
  Principle 1's demo clause and `CODE_STYLE.md` cross-reference the new
  material. `templates/demo.html` now embodies the conventions — a
  Solarized-themed snippet, a "Why this matters" expander, house-rule comments
  — while staying one dependency-free file and keeping its placeholder marker.
  `CHANGELOG.md` `Unreleased` → Added; `TODO.md` demo-page item gained the
  shipped entry plus two follow-ups (a mechanical checker; dogfooding the
  framework's own `demo.html`).
- **Verification Run**: `scripts/check_demo_page.sh --strict` against the
  edited `templates/demo.html` staged in a temp root with a linking README —
  0 findings. Visual render of the template in a browser confirmed the
  Solarized palette (base03 background, italic comment, green keywords, blue
  calls, cyan strings, magenta number) and the working expander. The full
  suite (`run_all_tests.sh`) was **not** run this session — no shell logic
  changed, only docs, the scaffold, CHANGELOG, and TODO — so CI on the PR is
  the backstop.
- **Known Blockers**: Changes are in the working tree only — **not committed,
  not pushed** (session started on `main`; next step is a branch + PR).
  Release debt carried over from the prior handoff is still open: v1.54.0
  untagged, v1.53.0 unpublished, and `Unreleased` now holds the Dependabot
  work, the `actions/checkout` security pin, **and** this demo-page change. No
  `VERSION` bump was made here, on purpose, so `check_version_alignment.sh`
  stays green while work accumulates in `Unreleased`.
- **Context Hints**: `ate-harness-demo` is the worked reference for all three
  conventions — `demo.html` (Solarized `--code-*` vars, `details.more`) and
  `scripts/build_publish.py` (page + PDF from one source, `--check` freshness
  guard). The follow-up checker extends ADR-0002 and should follow the
  warn-by-default / `--strict` contract. The own-demo dogfooding follow-up
  (`TODO.md` → demo-page item) is what makes the framework practice what this
  change now preaches.

#### Next Steps

**Human action required:** steps 1, 4, and 5.

1. [ ] **HUMAN** — Review the working-tree changes, then branch and open a PR
   - **Why a human:** the session is on `main`; branching and the merge decision are the maintainer's.
   - **You need:** a local clone with these edits, `gh` signed in.
   - **Done when:** a PR is open with CI green.
2. [ ] **AUTOMATED** — `tests.yml` runs the full suite and the strict self-governance job (including `check_demo_page.sh` and `check_next_steps.sh`) on the PR; `wiki-sync.yml` republishes on merge. Watch for a red run.
3. [ ] **AGENT** — If CI flags anything in the edited docs/template, fix it in the PR branch.
4. [ ] **HUMAN** — Decide whether to fold this into the pending 1.55.0 release (it joins the Dependabot work and the security pin already in `Unreleased`) or ship it separately.
   - **Why a human:** release cadence is the maintainer's call.
   - **Done when:** the decision is recorded (a release PR is open, or `TODO.md` notes the hold).
5. [ ] **HUMAN** — Clear the carried-over release debt: tag `v1.54.0`, publish the v1.53.0 and v1.54.0 releases, and bump the fleet (from the prior handoff).
   - **Why a human:** remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** a local clone, `gh` signed in.
   - **Done when:** `gh release list` shows v1.54.0 as Latest and every adopter's `constitution-version.yml` is green.
6. [ ] **AGENT** _(suggestion)_ — Build the mechanical checker for the new conventions and dogfood the framework's own `demo.html` (`TODO.md` → demo-page follow-ups).
