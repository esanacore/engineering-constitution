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

### Session: 2026-10-12 (Dependabot for adopters' manifests)

- **Accomplishments**: Dependabot cannot discover manifests, and the shipped
  `templates/.github/dependabot.yml` watched only the constitution submodule
  and the action pins. `scripts/bootstrap.sh` now sources
  `scripts/lib/bootstrap_dependabot.sh` and appends one `updates:` entry per
  dependency manifest at the project root (npm, pip, cargo, gomod, maven,
  gradle, swift, bundler, composer, docker; weekly, `deps` prefix,
  `dependencies` label), each marked with the manifest that produced it, and
  reports `Dependabot ecosystems added (...)`. A preserved adopter file is
  never edited: the entries go into the
  `.constitution-bootstrap/templates/` merge copy. A `pyproject.toml` counts
  only when it declares dependencies (`[project]` or `[tool.poetry]`). The
  template documents the mechanism and ends with a commented example for
  manifests below the root. This repository's own `.github/dependabot.yml`
  gained an `npm` entry for `/mcp-server`. `TODO.md` item closed; a
  follow-up for manifests below the root recorded. INTEGRATION.md,
  SECURITY.md, README.md, and the wiki's shared-libraries table updated.
- **Verification Run**: `bash scripts/test_bootstrap.sh` (new
  `test_dependabot_ecosystems`: three-manifest fixture, below-root manifest
  ignored, PyYAML parse of the generated file, preserved file untouched with
  the entries in the merge copy, tool-only `pyproject.toml` skipped,
  `build.gradle.kts`/`Dockerfile` detected, `--force` re-run without
  duplicates); `bash scripts/run_all_tests.sh --quiet` (31 suites green);
  every `tests.yml` self-governance step locally; an isolated critique pass
  on the diff, whose findings (pyproject false positive, silent YAML skip,
  template wording, wiki table, missing `build.gradle.kts` in
  INTEGRATION.md) are fixed with regression cases. Main CI on the #93 merge
  (ce64cb3) confirmed green.
- **Known Blockers**: v1.54.0 untagged, v1.53.0 unpublished; five
  `Unreleased` entries now wait on the local-session handoff. Existing
  adopters get the new entries only on their next `bootstrap.sh` run, into
  the merge copy; nothing rewrites a live adopter `dependabot.yml`.
- **Context Hints**: `bootstrap_dependabot.sh` is root-only on purpose
  (`TODO.md` → Features has the one-level-deep follow-up). The appended
  entries land after the template's commented example; that is valid YAML
  and the template comment says so.

#### Next Steps

**Human action required:** steps 1, 3, and 4.

1. [ ] **HUMAN** — Review and merge the Dependabot pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs the suite and the strict self-governance job on the PR; `wiki-sync.yml` republishes the wiki on merge; Dependabot picks up the new `/mcp-server` npm entry on its next weekly run. Watch for a red run or a burst of npm PRs.
3. [ ] **HUMAN** — Run the local-session handoff for 1.54.0 (tag `v1.54.0`, publish the v1.53.0 and v1.54.0 releases, bump the fleet with the Stop hook rollout)
   - **Why a human:** remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** the `local-session-handoff-1.54.0.md` prompt from the cloud session, a local clone, `gh` signed in.
   - **Done when:** `gh release list` shows v1.54.0 as Latest and every adopter's `constitution-version.yml` is green.
4. [ ] **HUMAN** — Decide whether 1.55.0 is cut right after step 3 (five `Unreleased` entries are waiting, one of them a security pin) and whether the proposed memory entry (no regex interval expressions in shipped awk) is recorded _(blocked by step 3)_
   - **Why a human:** release cadence and `docs/MEMORY.md` entries are the maintainer's call.
   - **Done when:** either a release PR is open or the decision is recorded in `TODO.md`; the memory entry is recorded or declined.
5. [ ] **AGENT** — During the fleet bump, re-run `bootstrap.sh` (or hand-merge the `.constitution-bootstrap/templates/.github/dependabot.yml` entries) in each adopter with a root manifest so its dependencies get version updates _(blocked by step 3)_.
6. [ ] **AGENT** — Audit the fleet's READMEs with `check_readme.sh` and open per-adopter PRs for the findings (`TODO.md` → Documentation) _(blocked by step 3)_.
7. [ ] **AGENT** _(suggestion)_ — Teach `bootstrap_dependabot.sh` about manifests one level below the root (`TODO.md` → Features).
