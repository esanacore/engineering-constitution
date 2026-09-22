# ADR-0004: A Proportionate Workflow for Trivial Changes

Status: Accepted

Date: 2026-09-16 (proposed and accepted)

## Relationships

- Extends: none
- Supersedes: none
- Related: `AI_WORKFLOW.md` ("Proportionate Workflow (Trivial Changes)"),
  `CONSTITUTION.md` ("Required Workflow"), the instruction-weight measurement
  recorded in `TODO.md` (1.46.0), `sources/summaries/articles/the-harness-is-the-thing.md`

## Promotion Criteria (met at acceptance)

Accepted by the framework maintainer (Eric) on 2026-09-16 in the session that
proposed it. The rule text lives in `AI_WORKFLOW.md`; this ADR records the
reasoning, because a conditional step in the Required Workflow is an ADR
trigger under `DOCUMENTATION.md`.

## Context

The Required Workflow has grown to thirty steps, each added for a reason and
each reasonable for a change that alters behavior. Applied to a typo fix, the
same thirty steps require a session plan, an implementation plan, an isolated
critique pass from a fresh context, a coverage evaluation, and a release
evaluation — more work than the fix, with no proportional benefit. The
measured cost of instruction weight (1.46.0) and the harness article's warning
about over-prescription both point the same way: a workflow that cannot scale
down teaches agents that it is ceremony, and ceremony gets skipped
unpredictably. The framework had no rule for this, so every agent decided for
itself, silently.

## Decision

Add a "Proportionate Workflow" section to `AI_WORKFLOW.md` that:

1. Defines **trivial** by four conjunctive tests — no behavior change; small
   enough for one screen; nothing on a sensitive list (dependencies,
   environment variables, secrets, auth, CI, instruction files, checkers,
   templates); and nobody has asked for the full workflow — with "when in
   doubt, it is not trivial" as the tie-breaker and reclassification by a
   user, reviewer, or failing check always allowed.
2. Names exactly which steps a trivial change may skip (plan, implementation
   plan, coverage, critique, traceability/OTS/env, release evaluation, memory
   proposals, plan cleanup) and which never shrink to nothing: the scoped
   reads, the secrets sweep, the pull request.
3. Requires the pull request to say the fast path was taken, so the
   classification is reviewable.

## Consequences

Positive:

- The fast path is explicit and bounded; the full workflow is the default.
- Skipping is now a reviewable claim in the pull request rather than an
  invisible judgment.

Negative / costs:

- A misclassified change can skip the critique pass. Mitigated by the
  sensitive-file list (the places where a small change does the most harm)
  and by the reviewer's power to reclassify.
- One more section to read; the reading-order measurement should be re-run
  when the document next changes materially.

## Alternatives Considered

- **Leave it to judgment.** Rejected: that is the status quo, and it produced
  silent, inconsistent skipping.
- **A size-only rule (lines changed).** Rejected: a one-line change to a CI
  workflow or an instruction file is the most dangerous kind; the sensitive
  list matters more than the line count.
- **A separate "lite" workflow document.** Rejected: two documents drift;
  a section that references the numbered steps stays in sync with them.
