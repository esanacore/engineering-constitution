# AGENTS.md

This repository is Eric's Engineering Constitution Framework.

## Before Beginning Work

Read:

- `CONSTITUTION.md`
- `AI_WORKFLOW.md`
- `INTEGRATION.md` when the task touches adopter integration, bootstrap, or IDE/multi-tool setup — a reference, not session-start reading
- `TESTING.md`
- `DOCUMENTATION.md`
- `SECURITY.md`
- `OPERATIONS.md`
- `ARCHITECTURE.md`
- `RELEASES.md`
- `TODO_GUIDELINES.md`
- `README.md`
- `TODO.md` — open (`[ ]`/`[~]`) items; completed entries are history, read on demand
- `CHANGELOG.md` — the `Unreleased` section and the most recent release; older sections are history, read on demand

## Work Standards

- Keep framework documents consistent with each other.
- Update `VERSION` for released framework changes.
- Update templates when standards change.
- Update the sample project when templates or integration guidance changes.
- Validate shell scripts with `bash -n`.
- Document user-facing changes in `CHANGELOG.md`.
- Record future framework opportunities in `TODO.md`.
- When editing workflow or template files, verify that `docs/SESSION_PLAN.md` and `docs/MEMORY.md` guidance stays consistent across all agent instruction templates.

## Before Completing Work

- Review documentation impact.
- Review testing or validation impact.
- Update TODO.md.
- Update CHANGELOG.md.
- Perform a security review.
- Summarize changed files and validation.
