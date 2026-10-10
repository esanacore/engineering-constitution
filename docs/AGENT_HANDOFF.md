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

### Session: 2026-10-09

- **Accomplishments**: the README standard now insists on per-platform
  instructions and progressive disclosure. `DOCUMENTATION.md` gained "Every
  Platform the Project Supports" (name the supported platforms; one install,
  run, and test block per platform — Windows, macOS, Linux at minimum — written
  for that platform's shell; verified, not guessed; the same rule for
  `docs/SETUP.md` and friends) and "Progressive Disclosure" (`<details>`
  blocks for the long parts; a stated always-visible set: title and
  description, capabilities list, hero diagram and demo link, quick start
  with its supported-platforms line, every `##` heading, version line,
  documentation pointers; the rendering mechanics). `CONSTITUTION.md`
  Principle 1 names the rule. `templates/README.md` and
  `templates/docs/SETUP.md` are the worked examples; this repository's own
  README follows it (Quick Start with Linux, macOS, and Windows Git Bash
  blocks; long sections collapsed). The `readme-capabilities-sync` skill, both
  Solon files, the demo page's Principle 1 card, and the wiki carry the rule.
  Release 1.53.0 is cut in this change (`VERSION`, every version reference,
  dated CHANGELOG section).
- **Verification Run**: `bash scripts/run_all_tests.sh --quiet` — 29 suites
  passed; every `tests.yml` self-governance step passed locally (secrets
  sweep, instruction anchors on root/templates/sample project, skills, demo
  page, Next Steps, wiki links, OTS inventory, version references). An
  isolated critique pass reviewed the final diff. No new tests: the change
  adds no checker (one is recorded in `TODO.md` → Documentation).
- **Known Blockers**: none. The macOS Quick Start block was written from
  documented behavior (macOS ships bash 3.2; the scripts use associative
  arrays and `${var,,}`, both bash 4) and has not been executed on a Mac — recorded in `TODO.md`.
- **Context Hints**: `DOCUMENTATION.md` "README Expectations" is the source
  of the rule; `templates/README.md` is the shape to copy. The adopter list
  is at `~/.config/engineering-constitution/adopters.txt` on the maintainer's
  machine. The fleet's READMEs have not been audited against the new rule
  yet (`TODO.md` → Documentation).

#### Next Steps

**Human action required:** steps 1, 3, 4, and 6.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision, and the wording of a standard every adopter inherits deserves a read.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs the full suite and the strict self-governance job on the PR; `wiki-sync.yml` republishes the wiki on merge. Watch for a red run.
3. [ ] **HUMAN** — Tag the release `v1.53.0` on the merge commit _(blocked by step 1)_
   - **Why a human:** remote sessions cannot push tags (the git proxy drops them).
   - **You need:** a local clone with push access, `gh` signed in.
   - **Procedure:**
     1. `git fetch origin main && git log -1 --format=%H origin/main` and confirm `git show <sha>:VERSION` prints `1.53.0`.
     2. `git tag -a v1.53.0 <sha> -m "v1.53.0" && git push origin v1.53.0`.
     3. `bash scripts/check_release_tag_alignment.sh .` must report `VERSION`, `HEAD`, and the tag aligned.
   - **Done when:** `release-tag-alignment.yml` is green for the tag.
4. [ ] **HUMAN** — Publish the GitHub Release for `v1.53.0` _(blocked by step 3)_
   - **Why a human:** the GitHub Release is created in the web UI; the MCP toolset has no create-release tool.
   - **You need:** the `1.53.0` section of `CHANGELOG.md` as the notes.
   - **Procedure:** open `https://github.com/esanacore/engineering-constitution/releases/new?tag=v1.53.0`, paste the CHANGELOG section, mark it the latest release, publish.
   - **Done when:** the release page shows `v1.53.0` as Latest.
5. [ ] **AGENT** — Bump the adopter fleet to the release commit with `bash scripts/bump_adopters.sh --sha <sha> --repos ~/.config/engineering-constitution/adopters.txt` _(blocked by step 3)_; adopters with a required `version-gate` check (gentle-table, patients-served) block all PRs until this lands.
6. [ ] **HUMAN** — Merge the fleet bump pull requests _(blocked by step 5)_
   - **Why a human:** merges on each adopter are the maintainer's decision.
   - **Done when:** every adopter's `constitution-version.yml` is green.
7. [ ] **AGENT** _(suggestion)_ — Audit the fleet's READMEs for Linux-only instructions and open the per-adopter PRs that add Windows and macOS blocks (`TODO.md` → Documentation).
8. [ ] **AGENT** _(suggestion)_ — Add `scripts/check_readme.sh`, the warn-by-default README tripwire recorded in `TODO.md`.
