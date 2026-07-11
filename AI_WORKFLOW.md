# AI Workflow

This document defines the required workflow for AI-assisted software development.

## Required Workflow

1. Read AGENTS.md.
2. Read constitution documents.
3. Read README.md.
4. Read TODO.md.
5. Read CHANGELOG.md.
6. Read OPERATIONS.md when the task affects infrastructure, CI/CD, deployment, or runbooks.
7. Review non-default branches, worktrees, and open pull requests for related or conflicting in-progress work.
8. Understand the task.
9. Create an implementation plan.
10. Implement changes.
11. Update tests. Add as many automated tests as the change genuinely calls for across the pyramid (unit, integration, end-to-end, regression) rather than the minimum that makes a check pass — see TESTING.md. Update `docs/TEST_PLAN.md`'s "Full suite" command if it changed, and run `bash constitution/scripts/run_declared_tests.sh .` locally before considering the work done.
12. Evaluate coverage and analyze gaps.
13. Update requirements traceability for product-facing repositories.
14. Update documentation, including README.md's current features/capabilities list — the "what can it do today?" answer is never optional just because the task wasn't explicitly about docs, and it goes stale fastest on projects that are actively growing. See CONSTITUTION.md Principle 1 and DOCUMENTATION.md's "Current Capabilities" section.
15. Update TODO.md.
16. Update CHANGELOG.md.
17. Evaluate whether this work should trigger a release (see RELEASES.md's *Semantic Versioning* and *Cutting a Release* sections). If user-facing changes have accumulated in CHANGELOG.md's `Unreleased` section, cut a release — bump `VERSION`, tag, and publish — rather than leaving it there indefinitely. If a release is not appropriate right now, state why rather than silently skipping the check.
18. Perform a security review.
19. Suggest future improvements.
20. Summarize work.
21. Before pushing, sweep for secrets that should be gitignored: run `bash constitution/scripts/check_secrets.sh .` locally (or rely on the `.pre-commit-config.yaml` pre-push hook if it's installed) — see SECURITY.md's "Secrets Sweep" section. Treat any real hit as blocking; never push past it.
22. Merge completed work (or open a pull request for it), then clean up Git state (branches, worktrees).

## Before Beginning Work

Agents must gather enough project context to make safe changes:

- Repository purpose and supported workflows
- Existing architecture and conventions
- Current roadmap and known issues
- Test strategy and available commands
- Release and changelog expectations
- Security-sensitive areas
- Non-default branches, worktrees, and open pull requests that may overlap with, duplicate, or conflict with this task

## During Work

Agents should:

- Prefer the existing project style.
- Keep changes focused on the task.
- Add or update tests for behavioral changes, across as many of unit/integration/e2e/regression as genuinely apply — CI's `constitution-tests.yml` workflow runs whatever is declared, but only what's declared.
- Update documentation as part of the implementation, including README.md's current-features list (see DOCUMENTATION.md's "README Expectations") — CI's `constitution-doc-freshness.yml` workflow is a blunt tripwire for this, not a substitute for actually doing it.
- Record discovered work in TODO.md.
- Never commit or push a real secret, credential, or credential-shaped file — sweep with `constitution/scripts/check_secrets.sh` before pushing (see SECURITY.md's "Secrets Sweep"); CI's `constitution-secrets.yml` workflow is the backstop, not the reason to skip the local sweep.
- Avoid unrelated refactors unless required for the task.
- Use the `/browse` gstack skill for all web browsing; never call `mcp__claude-in-chrome__*` tools directly.

## Before Completing Work

Agents must verify:

- The implementation addresses the request.
- Relevant tests pass or test limitations are reported. Where CI enforces this (`constitution-tests.yml`, `constitution-doc-freshness.yml`; see TESTING.md's "CI Enforcement"), treat it as the backstop, not the reason to skip verifying locally first.
- Coverage was evaluated against declared targets and any gaps were recorded.
- Requirements traceability is updated for product-facing repositories.
- Documentation impact has been evaluated, including whether README.md's current features/capabilities list still answers "what can it do today?" — not just whether the task was doc-focused.
- TODO.md reflects newly discovered or completed work.
- CHANGELOG.md includes user-facing changes when appropriate.
- Release discipline has been evaluated: either a release was cut for accumulated user-facing changes (see RELEASES.md), or there is a clear, stated reason not to. `CHANGELOG.md`'s `Unreleased` section must not be allowed to grow indefinitely without a release ever being cut.
- Security impact has been reviewed, including a secrets sweep (`constitution/scripts/check_secrets.sh`) before pushing.
- Future improvements are identified when useful.
- Completed work has been merged, or a pull request has been opened for it, before its branch is deleted.
- Git environment is clean: branches and worktrees created for this task are removed after merging (or after the agent confirms they are no longer needed); branches or worktrees the agent did not create are left alone unless a human confirms they are safe to remove, since they may belong to another in-progress session or automation; no untracked files (e.g. `node_modules`) are accidentally staged.

## Summary Expectations

Final summaries should include:

- What changed
- Tests run
- Documentation updated
- Security considerations
- Notable follow-up work