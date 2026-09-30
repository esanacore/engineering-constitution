# ADR-0005: A Next Steps Procedure at the End of Every Push

Status: Accepted

Date: 2026-09-30 (requested and accepted)

## Relationships

- Extends: ADR-0004 (the Next Steps procedure is one of the steps a trivial
  change never skips)
- Supersedes: none
- Related: `AI_WORKFLOW.md` ("Next Steps Procedure", Required Workflow steps
  28 and 30), `docs/AGENT_HANDOFF.md`, `.github/pull_request_template.md`

## Promotion Criteria (met at acceptance)

Requested by the framework maintainer (Eric) on 2026-09-30. The rule text
lives in `AI_WORKFLOW.md`; this ADR records the reasoning, because a new
requirement in the Required Workflow is an ADR trigger under
`DOCUMENTATION.md`.

## Context

The Required Workflow ended with "Summarize work" and a "Notable follow-up
work" bullet. In practice that produced a paragraph of loose ideas at the end
of a session, with the steps that only a person can do — tagging a release
from a local clone, publishing it in the web UI, connecting hardware,
enabling a UI-only repository setting — mixed in with things an agent will
do next time, and described too briefly to follow cold. The 1.45.0 and
1.50.0 releases both ended with the tag step blocked on the maintainer, and
each time the instructions lived only in chat scrollback. `docs/AGENT_HANDOFF.md`
had a "Next Steps" bullet but no shape, so it was filled in inconsistently or
not at all.

## Decision

Every push ends with a **Next Steps procedure**, in the same form in three
places — the agent's summary, the pull request description, and the latest
entry of `docs/AGENT_HANDOFF.md`:

1. A "Next Steps" heading and a numbered checklist (`1. [ ]`) in the order
   the steps should happen.
2. Every step starts with who acts: **HUMAN**, **AGENT**, or **AUTOMATED**.
3. Steps only a person can do are called out first — a `**Human action
   required:** steps …` line naming every HUMAN step — and then described:
   **Why a human** and **Done when** always; **You need** and a numbered
   **Procedure** when there is more than one action.
4. Dependencies are explicit (`_(blocked by step N)_`), and the procedure is
   never empty: at least one step, marked `_(suggestion)_` when optional.

`scripts/check_next_steps.sh` verifies the format (warn by default,
`--strict` to block), runs `--strict` against this repository's handoff in
`tests.yml`, and runs in warn mode in the adopter
`constitution-compliance.yml` template. Every agent instruction file carries
the rule; `tests.yml` enforces that with an explicit
`check_instruction_templates.sh --anchor`.

## Consequences

Positive:

- A reader can see in one line what is waiting on them, and do it without
  reconstructing the session.
- Human-only work stops disappearing into chat history; the handoff file
  carries it until it is done.
- The format is mechanical enough to check, so it does not erode silently.

Negative / costs:

- One more required section per push. Mitigated by allowing a single
  suggestion when nothing else is pending.
- Existing adopter handoff files do not have the section; the compliance
  template reports that as a warning, not a failure, so no adopter turns red.
- The anchor is not added to `check_instruction_templates.sh`'s defaults:
  that would change a checker's strict behavior for adopters without a
  deprecation window (ADR-0003). Adopters inherit it through the templates;
  a later release can make it a default after a `Deprecation` notice.
