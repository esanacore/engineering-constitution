# AI Workflow

This document defines the required workflow for AI-assisted software development.

## Required Workflow

1. Read AGENTS.md.
2. Read constitution documents.
3. Read README.md.
4. Read TODO.md.
5. Read CHANGELOG.md.
6. Read OPERATIONS.md when the task affects infrastructure, CI/CD, deployment, or runbooks.
7. Understand the task.
8. Create an implementation plan.
9. Implement changes.
10. Update tests.
11. Update documentation.
12. Update TODO.md.
13. Update CHANGELOG.md.
14. Perform a security review.
15. Suggest future improvements.
16. Summarize work.
17. Clean up Git state (branches, worktrees).

## Before Beginning Work

Agents must gather enough project context to make safe changes:

- Repository purpose and supported workflows
- Existing architecture and conventions
- Current roadmap and known issues
- Test strategy and available commands
- Release and changelog expectations
- Security-sensitive areas

## During Work

Agents should:

- Prefer the existing project style.
- Keep changes focused on the task.
- Add or update tests for behavioral changes.
- Update documentation as part of the implementation.
- Record discovered work in TODO.md.
- Avoid unrelated refactors unless required for the task.

## Before Completing Work

Agents must verify:

- The implementation addresses the request.
- Relevant tests pass or test limitations are reported.
- Documentation impact has been evaluated.
- TODO.md reflects newly discovered or completed work.
- CHANGELOG.md includes user-facing changes when appropriate.
- Security impact has been reviewed.
- Future improvements are identified when useful.
- Git environment is clean (temporary branches removed, worktrees deleted, no untracked files like node_modules accidentally staged).

## Summary Expectations

Final summaries should include:

- What changed
- Tests run
- Documentation updated
- Security considerations
- Notable follow-up work
