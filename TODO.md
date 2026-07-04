# TODO

## Features

- [x] Add retroactive version analysis mechanism.
- [x] Standardize the Eric's Engineering Constitution adoption badge across bootstrapped repositories.
- [ ] Add language-specific guidance for common stacks.
- [x] Ship a GitHub Copilot custom agent ("Solon") at `.github/agents/solon.agent.md`, install it via bootstrap, and document it in `INTEGRATION.md`. Shipped in 1.25.0 for Visual Studio 2026 (v18.4+).
- [x] Harden the release process in `RELEASES.md` with an ordered "Cutting a Release" gate (bump every version reference, tag, publish GitHub Release). Shipped in 1.24.0 after the README banner and tags lagged across 1.21.0–1.23.0.
- [x] Add GoF design-pattern guidance (the two maxims plus a curated subset of patterns) to `ARCHITECTURE.md`, building on the SOLID + Dependency Rule design principles. Shipped in 1.23.0 alongside the design principles.
- [x] Add DevOps and infrastructure standards.
- [x] Add Goose / Goosetown agent integration (`.goosehints` + MCP extension guidance).
- [x] Add automated constitution version enforcement (Dependabot auto-PRs, CI version gate, `audit_adopters.sh`).
- [x] Add a `sources/` drop-in location for book/reference sources with change detection and distilled summaries, surfaced to agents via the MCP server. Shipped in 1.28.0 as `scripts/check_source_summaries.sh` (`scan`/`record`), `KNOWLEDGE_SOURCES.md`, and dynamic `constitution://source-summary/*` resources in `mcp-server/index.js`.
- [x] Make `sources/` self-explanatory for a first-time user: a worked demo fixture (`raw/example/` + `summaries/example/`, already recorded) and tracked `README.md` pointers in `sources/` and `sources/raw/`. Also fixed `check_source_summaries.sh` treating a `raw/README.md` as a pending source.
- [x] Require agents to review non-default branches, worktrees, and open pull requests for related or conflicting in-progress work before starting, and to merge (or open a PR for) completed work before deleting its branch — never delete a branch/worktree the agent didn't create without human confirmation. Shipped in 1.26.0 in `AI_WORKFLOW.md`, prompted by an adopting repo where an agent found unmerged branches, some owned by separate automated processes, only during end-of-task cleanup.
- [x] Require agents to evaluate whether accumulated work should trigger a release, not just update `CHANGELOG.md`'s `Unreleased` section indefinitely. Shipped in 1.27.0 in `AI_WORKFLOW.md`'s Required Workflow and completion checklist, plus a `CONSTITUTION.md` Principle 10 pointer — prompted by an adopting repo that sat at `VERSION 0.1.0` with zero tags/releases across 12+ merged PRs.
- [x] Add CI enforcement so adopting repositories actually run their own automated tests and catch documentation drift, not just governance-file presence. Shipped in 1.30.0 as `scripts/run_declared_tests.sh` (runs the "Full suite" command declared in `docs/TEST_PLAN.md`) and `scripts/check_doc_freshness.sh` (blunt tripwire for source changes with no README/CHANGELOG update), each with a matching `.github/workflows/constitution-*.yml` template installed by `scripts/bootstrap.sh`. Both follow the existing warn-by-default/`--strict` rollout contract so adopting the new templates doesn't immediately break CI on repos that haven't caught up yet.

## Technical Debt

- [x] Define a repeatable release process for framework updates. Shipped in 1.24.0 as the ordered "Cutting a Release" gate in `RELEASES.md` (see the Features entry above).
- [x] Cut the first `vX.Y.Z` release tag on `main`. Stale: releases have been tagged since v1.20.0, and the `constitution-version-check` gate is actively enforcing against the latest tag.
- [x] Add a checker that catches stale adopter-facing Constitution version references after a submodule bump. Shipped in 1.26.0 as `scripts/check_version_alignment.sh` with negative-case tests.

## Refactoring

- [ ] Consider splitting project bootstrap behavior into smaller reusable scripts if it grows.

## Testing

- [x] Add automated tests for `scripts/bootstrap.sh`.
- [x] Add continuous coverage evaluation and gap-analysis guidance to `TESTING.md`.
- [x] Add compliance checks that verify required files exist in integrated repositories. Implemented as `scripts/check_compliance.sh` with `scripts/test_check_compliance.sh` (required / recommended / product-facing tiers, `--strict` and `--product` modes).
- [x] Teach the compliance checker to flag uncustomized placeholder docs, so copied templates do not count as "present but unfinished" governance. Implemented in `scripts/check_compliance.sh` with `scripts/test_check_compliance_placeholders.sh`.
- [x] Add an automated check that every requirement ID has a verifying test entry in the traceability matrix. Ship it with negative-case unit tests (per the "Governance Tooling Must Be Tested" standard in `TESTING.md`), including the substring-collision case where a layered ID like `BB-FR-007` must not satisfy a check for system `FR-007`. Implemented as `scripts/check_traceability.sh` with `scripts/test_check_traceability.sh`.
- [x] Ship a CI workflow template that runs `scripts/check_traceability.sh` as a gate for product-facing repositories (alongside the existing constitution version-check workflow), so traceability is enforced and not only available on demand. Implemented as `templates/.github/workflows/constitution-compliance.yml`, which also runs `scripts/check_compliance.sh`; installed by `scripts/bootstrap.sh` and covered by `scripts/test_bootstrap.sh`.
- [x] Ship a CI workflow template that runs an adopting repository's own declared test suite, not just constitution governance checks. Implemented as `templates/.github/workflows/constitution-tests.yml` running `scripts/run_declared_tests.sh` with `scripts/test_run_declared_tests.sh` (5 cases, including that a declared failing command always fails regardless of `--strict`); installed by `scripts/bootstrap.sh` and covered by `scripts/test_bootstrap.sh`.
- [x] Ship a CI workflow template that flags pull requests changing source without touching README/CHANGELOG. Implemented as `templates/.github/workflows/constitution-doc-freshness.yml` running `scripts/check_doc_freshness.sh` with `scripts/test_check_doc_freshness.sh` (4 cases, including that the docs/lockfile ignore list actually suppresses false positives); installed by `scripts/bootstrap.sh` and covered by `scripts/test_bootstrap.sh`.

## Documentation

- [x] Add guidance for migrating existing project docs into the constitution structure.
- [x] Add language-specific override examples to `INTEGRATION.md`.
- [x] Add optional product requirements and MVP backlog templates for product-facing repositories.
- [x] Add an example of a fully populated `docs/OPERATIONS.md` for a deployed service. Added `examples/OPERATIONS.example.md` (a worked runbook for the fictional "Orders API" service), referenced from `OPERATIONS.md`, `DOCUMENTATION.md`, the blank template, and `README.md`.
- [x] Make the "what can it do today?" README expectation an explicit, named standing requirement rather than one bullet in a longer list, since it's the thing most likely to silently go stale on a fast-growing project. Shipped in 1.30.0 as `DOCUMENTATION.md`'s dedicated "Current Capabilities" section, `CONSTITUTION.md` Principle 1, and explicit call-outs in `AI_WORKFLOW.md`'s documentation step and completion checklist.

## Nice-to-Have

- [ ] Add repository health dashboards.
- [x] Add CI/CD enforcement examples.
- [ ] Add AI-generated release planning guidance.
- [ ] Consider a `--json` output mode for `scripts/check_source_summaries.sh` if another tool ever needs to consume its scan results programmatically.
- [ ] Consider curated stack-specific CI templates (Node, Python, Go, ...) layered on top of `constitution-tests.yml`'s generic declared-command runner, with real per-stack setup/dependency-install steps pre-filled instead of a comment placeholder — deferred in favor of the generic runner for the initial version.
- [ ] `check_doc_freshness.sh` is a deliberately blunt tripwire (source changed, docs didn't); consider whether real-world `--strict` usage produces enough false positives on refactor/test-only PRs to warrant a smarter allowlist (e.g. commit-message opt-out, path-based project config) before recommending `--strict` broadly.
