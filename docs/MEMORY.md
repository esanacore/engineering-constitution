# Project Memory

This file contains durable memories, codebase learnings, user preferences, and key architectural decisions. AI agents read this file at the start of each session to align with past context, and update it (at the user's discretion) at the end of a session.

> [!IMPORTANT]
> **User Discretion**: Do not add or edit entries in this file without presenting them to the user for review. The user has absolute discretion over what memories are retained.

## User Preferences & Styling Choices

- Eric works through PR-based flows on every repository, including fan-outs across the adopter fleet: one branch + one PR per repo, merged on his say-so (he frequently asks the agent to merge batches after review). Never push directly to a default branch.
- Releases are cut promptly once user-facing changes accumulate — do not let `Unreleased` sit. The full gate in `RELEASES.md` is followed every time: bump every version reference, date the CHANGELOG section, full test suite green, PR, then tag + GitHub Release after merge.
- GitHub Releases are published by Eric through the web UI (remote agent sessions have no `gh` CLI and the MCP toolset has no create-release tool). The agent's job is to extract the version's CHANGELOG section into a paste-ready notes file and hand over the pre-filled `releases/new?tag=` link.
- Eric values fleet uniformity: adopter repos should carry byte-identical copies of shared workflow files (verify with `git hash-object` blob comparison, not eyeballing).

## Codebase Learnings & Gotchas

- **Release tags must be verified by SHA, not name.** The v1.44.0 tag was initially pushed onto a year-old commit (SHA copy-paste slip). `check_release_tag_alignment.sh`'s "Latest release tag matches VERSION" line passes on the tag *name* alone — the tell was "HEAD is not tagged", and the real check is `git show <tag>^{commit}:VERSION`. When handing Eric a tag command, pin the exact merge-commit SHA in it.
- **Version references live in five places** and `test_release_docs.sh` enforces three of them: `VERSION`, `README.md` "Current version", `CONSTITUTION.md` `Version:` header, the `demo.html` badge, and `wiki/Home.md`'s current-version line (the last one is easy to forget and fails `test_release_docs.sh`).
- **Executable bits are a recurring hazard**: every directly-invoked `scripts/check_*.sh` / `test_*.sh` must be committed `100755` (tests invoke checkers directly, so a fresh clone fails with `Permission denied`); `scripts/lib/*.sh` are sourced-only and stay `100644`. Fixed once in 1.42.0; a CI guard is recorded in TODO.md but not yet built.
- **Compliance-test fixtures must track the required-file list.** When `wiki/Home.md` became required, `test_check_compliance.sh` was updated but `test_check_compliance_placeholders.sh`'s fixture builder was missed — its unguarded `$(check_compliance.sh ...)` capture then died under `set -euo pipefail` with exit 1 and zero output. Any new required file must be added to every fixture builder that constructs a "compliant" repo.
- **GitHub wiki initialization is UI-only.** `<repo>.wiki.git` does not exist until a human enables Settings → Features → Wikis and creates the first page in the UI; there is no API for it, and pushes to a nonexistent wiki repo fail. Diagnostic signature: `github.com/<repo>/wiki` redirecting to the repo homepage means the feature checkbox is off. The session git proxy does not authenticate `.wiki.git` paths, so wiki syncs must go through the Actions publish job (`actions_run_trigger` with `rerun_workflow_run` forces an immediate sync; re-running a successful run is fine).
- **Cheap fleet auditing pattern**: blobless no-checkout clones (`--depth 1 --filter=blob:none --no-checkout`), then `git ls-tree FETCH_HEAD` for gitlinks/blobs and `git show <pinned-sha>:VERSION` in the constitution checkout to map a submodule pin to a version. Fleet edits without checkouts: `git read-tree FETCH_HEAD` + `update-index --add --cacheinfo` (100644 for files, 160000 for the submodule gitlink) + `write-tree` + `commit-tree`.
- Adopter repo quirks: `gentle-table` and `patients-served` disallow merge commits (squash required) and enforce required status checks (`gentle-table`: `test-runner`; both: `version-gate`). Default branch is `master` on `macbook-home-hub`, `MultiplatformTestApp`, and `oldGTX1060_newTricks`; `main` everywhere else. `esanacore` (profile) and `CS-465` are not adopters.
- **Cutting a constitution release immediately strands the fleet one tag behind**: adopter `version-gate` checks compare the pinned submodule against the latest release tag, so repos where that gate is *required* (gentle-table, patients-served) block all PRs until the submodule is bumped — fold the bump into whatever PR is in flight, or roll a fleet-wide bump right after tagging.

## Active Project Decisions

- **Wiki subsystem is fully rolled out (ADR-0001 Accepted).** `wiki/Home.md` is a required governance file; all 17 adopters carry live, published GitHub wikis seeded with real README-derived content; `constitution-wiki.yml` runs everywhere.
- **The publish job skips gracefully when a wiki isn't enabled** (warning + exit 0; genuine clone failures still fail). First proven on AI-Process-Engineer PR #52, upstreamed verbatim into the template, shipped as v1.44.1, and rolled to the whole fleet.
- **Strict is per-repo, not the template default.** The template ships the `links` job warn-by-default (so a fresh adopter's unwritten wiki doesn't start red); each repo flips to `--strict` once its wiki is caught up. The entire current fleet runs `--strict` as of this decision; pre-verify with `check_wiki_links.sh --strict` against extracted wiki trees before enabling anywhere new.
- **Wiki page content follows the no-placeholder rule**: adopter `wiki/Home.md` files are written from each repo's own README (real capabilities, honest status), following the template's section structure — never scaffold text.
- The constitution repo maintains a single `main` branch; feature/release branches are deleted after merge (GitHub auto-deletes PR head branches).
