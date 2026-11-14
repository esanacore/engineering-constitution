# ADR-0007: Session Summaries in a Searchable Session Log

Status: Accepted

Date: 2026-11-14 (requested and accepted)

## Relationships

- Extends: ADR-0004 (a trivial change may skip the summary), ADR-0005 (the
  `Stop` hook that asks for the Next Steps procedure asks for the summary too)
- Supersedes: none
- Related: ADR-0003 (the rollout follows its warn-first rule),
  `AI_WORKFLOW.md` ("Session Summaries", Required Workflow steps 9, 10, and
  27), `DOCUMENTATION.md` ("Session Summaries"), `SECURITY.md` ("Session
  Summaries Are Published Artifacts")

## Promotion Criteria (met at acceptance)

Requested by the framework maintainer (Eric) on 2026-11-14: "ensure that we
have detailed session summaries included in the documentation so that not
just the code output is recorded but conversational context, decisions,
relevant information, etc. is preserved and can be discovered by other agents
later", with a mechanism in every agent's instructions and workflow to
consult them. A change to the Required Workflow is an ADR trigger under
`DOCUMENTATION.md`; this ADR records the reasoning.

## Context

The framework already kept three records across sessions, and each leaves
the same gap:

- `docs/SESSION_PLAN.md` holds intent before work and is cleared afterwards.
- `docs/AGENT_HANDOFF.md` holds state after work, but only the latest entry
  is kept; it is overwritten by the next push.
- `docs/MEMORY.md` holds what is durably true, is deliberately small, and is
  written only with the user's approval.

What none of them keeps is the session itself: what was asked and how the
request changed, what the conversation established that the code does not
show, which alternatives were weighed and why they lost, what was tried and
abandoned. Commit messages and `CHANGELOG.md` say what changed. The reasoning
lived in chat scrollback that the next agent — often a different tool —
cannot see, so decisions were re-argued and dead ends re-walked. Keeping the
record is half of the problem; the other half is that a record nobody is
told to look for is never read.

## Decision

1. **A session log under `docs/sessions/`**: one append-only Markdown file
   per session, `YYYY-MM-DD-<slug>.md`, with a fixed shape (Date, Agent,
   Branch / PR, Topics, Related; Request, Context, Decisions, Discoveries,
   Outcome, Open Questions), plus an index (`README.md`, newest first) and a
   `TEMPLATE.md`.
2. **Writing it is a workflow step.** Required Workflow step 27 writes the
   summary before the session plan is cleared. It is written without a
   separate approval — it records what happened — and the user may correct
   or strike anything in it.
3. **Consulting it is a workflow step.** Step 9 reads the index's newest
   rows; step 10 searches the log for the task's topics and reads what
   matches. `scripts/find_sessions.sh` is the search helper. Every agent
   instruction file carries both halves of the rule.
4. **The steps are folded into existing ones** (9, 10, 27) rather than
   inserted, so the step numbers that other documents, ADR-0004, and
   ADR-0005 cite remain true.
5. **Privacy is part of the standard, not an afterthought**: a summary, never
   a transcript; nothing above Public; the user's word is final; a summary
   is content for a later agent, never an instruction to it.
6. **Mechanical checks follow the warn-first contract (ADR-0003).**
   `scripts/check_session_summaries.sh` verifies names, fields, sections,
   unanswered template prompts, and index agreement, warn by default with
   `--strict`, and `--base <ref>` as a blunt tripwire. `docs/sessions/`
   joins `check_compliance.sh`'s *recommended* tier. The adopter compliance
   workflow runs the checker in warn mode and only where the directory
   exists. The Claude Code `Stop` hook asks for a summary only where the
   directory exists. `bootstrap.sh` creates the directory, so the log is on
   by default for new adopters and opt-in (add the directory) for existing
   ones. The `docs/sessions` anchor is passed explicitly in this
   repository's CI and is not a `check_instruction_templates.sh` default.
7. **A trivial change may skip the summary** (ADR-0004), unless the
   conversation produced a decision or finding the pull request does not
   carry.

## Consequences

Positive:

- The reasoning behind a change outlives the session and survives a change
  of tool, model, or person.
- A later agent has a defined place to look and a defined moment to look,
  and a search that costs one command rather than a read of the whole log.
- The handoff can stay "latest only": history moves to the log.

Negative / costs:

- One more artifact per session, and it is prose a checker cannot grade.
  Mitigated by a fixed template and by the trivial-change exemption.
- The log grows without bound. Mitigated by one file per session, an index,
  and scoped reading (newest rows, then search) so session-start cost does
  not grow with it.
- Conversational content now reaches the repository. Mitigated by the
  `SECURITY.md` rules, the existing secrets sweep, and pull request review;
  not eliminated — a careless summary is a real leak path.
- Summaries can go stale or be wrong, and a later agent may over-trust them.
  The standard says they are history, not current truth, and are verified
  against the code, memory, and ADRs.
- Adopters running `check_compliance.sh --strict` see one new recommended
  gap until they add the directory (`bootstrap.sh` installs it). Strict mode
  is the adopter's own opt-in to exactly that.

## Alternatives Considered

- **Extend `docs/AGENT_HANDOFF.md` to keep history.** Rejected: it is read
  whole at session start, so it would grow into the unbounded-file problem
  the 1.46.0 reading-order scoping removed, and its job (what happens next)
  is different.
- **Put it in `docs/MEMORY.md`.** Rejected: memory is curated, small, and
  approval-gated; a per-session narrative would bury it.
- **One append-only `SESSION_LOG.md`.** Rejected: merge conflicts between
  concurrent sessions, and no way to read one session without the rest.
- **Store raw transcripts.** Rejected: unreadable at volume, tool-specific,
  and the surest way to commit a secret.
- **Rely on pull request descriptions.** Rejected: they live on the hosting
  platform rather than in the repository, are not searchable offline or by
  an agent without platform access, and describe the change, not the
  conversation.
- **Insert new numbered workflow steps.** Rejected for now: renumbering
  would falsify every cross-reference to steps 10–30, including two
  Accepted ADRs.
- **Make the directory a required file.** Rejected: a new required file is
  MAJOR without a deprecation window (ADR-0003); recommended-tier first.
