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

### Session: 2026-10-10

- **Accomplishments**: the Next Steps procedure is now enforced where it is
  skipped. `scripts/next_steps_hook.sh` is a Claude Code hook: `start`
  (`SessionStart`) records the session's starting commit; `stop` (`Stop`)
  blocks once when a session that made commits leaves `docs/AGENT_HANDOFF.md`
  stale, uncommitted, or malformed, or ends its reply without a Next Steps
  section. Registered in `templates/.claude/settings.json` and in this
  repository's own `.claude/settings.json` (now allowlisted in `.gitignore`).
  `INTEGRATION.md` documents it and the manual entries for existing
  adopters. Release 1.54.0 is cut in this change.
- **Verification Run**: `bash scripts/run_all_tests.sh --quiet` (30 suites
  green, including the new `test_next_steps_hook.sh`), every `tests.yml`
  self-governance step locally, and an isolated critique pass on the diff.
- **Known Blockers**: v1.53.0 is tagged but has no GitHub Release (latest
  published is v1.52.0); remote sessions cannot publish releases or push
  tags. Whether the fleet was bumped to 1.53.0 is not visible from here.
- **Context Hints**: the hook's input fields and exit codes follow the
  Claude Code hooks reference (`last_assistant_message`, `stop_hook_active`,
  exit 2 blocks with stderr as the reason). `bootstrap.sh` never overwrites
  an existing `.claude/settings.json`, so adopters need the two entries added
  by hand (`TODO.md`).

#### Next Steps

**Human action required:** steps 1, 3, 4, and 5.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision, and the hook changes how every Claude Code session in an adopting repository ends.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs the suite and the strict self-governance job on the PR; `wiki-sync.yml` republishes the wiki on merge. Watch for a red run.
3. [ ] **HUMAN** — Tag `v1.54.0` on the merge commit _(blocked by step 1)_
   - **Why a human:** remote sessions cannot push tags.
   - **You need:** a local clone with push access.
   - **Procedure:**
     1. `git fetch origin main` and take `sha=$(git rev-parse origin/main)`; `git show $sha:VERSION` must print `1.54.0`.
     2. `git tag -a v1.54.0 $sha -m "v1.54.0 — the Next Steps procedure, enforced at session end"` and `git push origin v1.54.0`.
   - **Done when:** `release-tag-alignment.yml` is green for the tag.
4. [ ] **HUMAN** — Publish the GitHub Releases for `v1.53.0` and `v1.54.0` _(blocked by step 3)_
   - **Why a human:** releases are published with `gh` from a local session or the web UI; remote sessions have no release tool.
   - **Procedure:**
     1. For each version, extract its section: `awk '/^## 1\.53\.0 /{f=1;next} /^## [0-9]/{f=0} f' CHANGELOG.md > notes.md` (and the same for `1\.54\.0`).
     2. `gh release create v1.53.0 --verify-tag --title "v1.53.0 — READMEs for every platform" --notes-file notes.md --latest=false`, then `v1.54.0` with `--latest`.
   - **Done when:** the releases page shows both, with `v1.54.0` as Latest.
5. [ ] **HUMAN** — Bump the adopter fleet to the 1.54.0 merge commit _(blocked by step 3)_
   - **Why a human:** it runs from a local session with `gh` signed in and the adopter list at `~/.config/engineering-constitution/adopters.txt`.
   - **Procedure:**
     1. `bash scripts/bump_adopters.sh --sha <sha> --repos ~/.config/engineering-constitution/adopters.txt --dry-run`, read the rewrites, then run without `--dry-run`.
     2. Merge the PRs; `gentle-table` and `patients-served` need squash merges.
   - **Done when:** every adopter's `constitution-version.yml` is green.
6. [ ] **AGENT** — Add the `next_steps_hook.sh` `start` and `stop` entries to each adopter's `.claude/settings.json` (merge, never overwrite) in the same fleet pass _(blocked by step 5)_; `TODO.md` → Features.
7. [ ] **AGENT** _(suggestion)_ — Add `scripts/check_readme.sh`, the warn-by-default README tripwire recorded in `TODO.md`.
