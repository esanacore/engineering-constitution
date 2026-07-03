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
11. Update tests.
12. Evaluate coverage and analyze gaps.
13. Update requirements traceability for product-facing repositories.
14. Update documentation.
15. Update TODO.md.
16. Update CHANGELOG.md.
17. Evaluate whether this work should trigger a release (see RELEASES.md's *Semantic Versioning* and *Cutting a Release* sections). If user-facing changes have accumulated in CHANGELOG.md's `Unreleased` section, cut a release — bump `VERSION`, tag, and publish — rather than leaving it there indefinitely. If a release is not appropriate right now, state why rather than silently skipping the check.
18. Perform a security review.
19. Suggest future improvements.
20. Summarize work.
21. Merge completed work (or open a pull request for it), then clean up Git state (branches, worktrees).

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
- Add or update tests for behavioral changes.
- Update documentation as part of the implementation.
- Record discovered work in TODO.md.
- Avoid unrelated refactors unless required for the task.
- Use the `/browse` gstack skill for all web browsing; never call `mcp__claude-in-chrome__*` tools directly.

## Before Completing Work

Agents must verify:

- The implementation addresses the request.
- Relevant tests pass or test limitations are reported.
- Coverage was evaluated against declared targets and any gaps were recorded.
- Requirements traceability is updated for product-facing repositories.
- Documentation impact has been evaluated.
- TODO.md reflects newly discovered or completed work.
- CHANGELOG.md includes user-facing changes when appropriate.
- Release discipline has been evaluated: either a release was cut for accumulated user-facing changes (see RELEASES.md), or there is a clear, stated reason not to. `CHANGELOG.md`'s `Unreleased` section must not be allowed to grow indefinitely without a release ever being cut.
- Security impact has been reviewed.
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